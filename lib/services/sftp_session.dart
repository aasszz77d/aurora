import 'dart:async';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:aurora/models/server.dart';

enum SftpState {
  idle,
  connecting,
  ready,
  failed,
  closed,
}

/// 独立的 SFTP 会话（不占用终端 shell）。
class SftpSession {
  SftpSession({required this.server});

  final Server server;

  SSHClient? _client;
  SftpClient? _sftp;

  SftpState state = SftpState.idle;
  String? errorMessage;
  String currentPath = '/';

  final ValueNotifier<SftpState> stateNotifier = ValueNotifier(SftpState.idle);
  final ValueNotifier<List<SftpName>> entries = ValueNotifier(const []);
  final ValueNotifier<bool> loading = ValueNotifier(false);

  void _setState(SftpState s) {
    state = s;
    stateNotifier.value = s;
  }

  Future<void> connect({String? initialPath}) async {
    if (state == SftpState.connecting || state == SftpState.ready) return;

    _setState(SftpState.connecting);
    errorMessage = null;
    loading.value = true;

    try {
      final socket = await SSHSocket.connect(
        server.host,
        server.port,
        timeout: const Duration(seconds: 15),
      );

      List<SSHKeyPair> identities = const [];
      if (server.privateKey != null && server.privateKey!.trim().isNotEmpty) {
        identities = SSHKeyPair.fromPem(
          server.privateKey!,
          server.passphrase,
        );
      }

      _client = SSHClient(
        socket,
        username: server.username,
        onPasswordRequest: (server.password != null &&
                server.password!.isNotEmpty)
            ? () => server.password!
            : null,
        identities: identities,
      );

      await _client!.authenticated;
      _sftp = await _client!.sftp();

      // 尽量落到用户家目录
      String path = initialPath ?? '/';
      if (initialPath == null) {
        try {
          final home = await _sftp!.absolute('.');
          if (home.isNotEmpty) path = home;
        } catch (_) {}
      }

      _setState(SftpState.ready);
      await list(path);
    } catch (e, st) {
      debugPrint('SFTP connect failed: $e\n$st');
      errorMessage = e.toString();
      _setState(SftpState.failed);
      await close();
    } finally {
      loading.value = false;
    }
  }

  Future<void> list(String path) async {
    final sftp = _sftp;
    if (sftp == null) return;

    loading.value = true;
    try {
      final normalized = _normalize(path);
      final names = await sftp.listdir(normalized);
      final items = names.where((e) => e.filename != '.').toList();

      // 目录在前，再按名称
      items.sort((a, b) {
        final ad = a.attr.isDirectory;
        final bd = b.attr.isDirectory;
        if (ad != bd) return ad ? -1 : 1;
        return a.filename.toLowerCase().compareTo(b.filename.toLowerCase());
      });

      currentPath = normalized;
      entries.value = items;
    } catch (e, st) {
      debugPrint('SFTP list failed: $e\n$st');
      errorMessage = e.toString();
      rethrow;
    } finally {
      loading.value = false;
    }
  }

  Future<void> refresh() => list(currentPath);

  Future<void> cd(String name) async {
    if (name == '..') {
      await list(_parent(currentPath));
      return;
    }
    final next = currentPath == '/'
        ? '/$name'
        : '$currentPath/$name';
    await list(next);
  }

  Future<void> mkdir(String name) async {
    final sftp = _sftp;
    if (sftp == null) return;
    final path = currentPath == '/' ? '/$name' : '$currentPath/$name';
    await sftp.mkdir(path);
    await refresh();
  }

  Future<void> remove(SftpName entry) async {
    final sftp = _sftp;
    if (sftp == null) return;
    final path = currentPath == '/'
        ? '/${entry.filename}'
        : '$currentPath/${entry.filename}';
    if (entry.attr.isDirectory) {
      await sftp.rmdir(path);
    } else {
      await sftp.remove(path);
    }
    await refresh();
  }

  Future<void> rename(String fromName, String toName) async {
    final sftp = _sftp;
    if (sftp == null) return;
    final from = currentPath == '/' ? '/$fromName' : '$currentPath/$fromName';
    final to = currentPath == '/' ? '/$toName' : '$currentPath/$toName';
    await sftp.rename(from, to);
    await refresh();
  }

  /// 读取整个文件到内存（适合小文件下载）。
  Future<Uint8List> readFile(String name) async {
    final sftp = _sftp;
    if (sftp == null) throw StateError('SFTP not connected');
    final path = currentPath == '/' ? '/$name' : '$currentPath/$name';
    final file = await sftp.open(path);
    try {
      final stat = await file.stat();
      final size = stat.size ?? 0;
      if (size <= 0) {
        final builder = BytesBuilder(copy: false);
        while (true) {
          final chunk = await file.readBytes();
          if (chunk.isEmpty) break;
          builder.add(chunk);
        }
        return builder.takeBytes();
      }
      return await file.readBytes(length: size);
    } finally {
      await file.close();
    }
  }

  Future<void> writeFile(String name, Uint8List data) async {
    final sftp = _sftp;
    if (sftp == null) throw StateError('SFTP not connected');
    final path = currentPath == '/' ? '/$name' : '$currentPath/$name';
    final file = await sftp.open(
      path,
      mode: SftpFileOpenMode.create |
          SftpFileOpenMode.write |
          SftpFileOpenMode.truncate,
    );
    try {
      await file.writeBytes(data);
    } finally {
      await file.close();
    }
    await refresh();
  }

  Future<void> close() async {
    try {
      _sftp?.close();
    } catch (_) {}
    _sftp = null;
    try {
      _client?.close();
    } catch (_) {}
    _client = null;
    if (state != SftpState.failed) {
      _setState(SftpState.closed);
    }
  }

  void dispose() {
    close();
    stateNotifier.dispose();
    entries.dispose();
    loading.dispose();
  }

  static String _normalize(String path) {
    if (path.isEmpty) return '/';
    var p = path.replaceAll(RegExp(r'/+'), '/');
    if (p.length > 1 && p.endsWith('/')) {
      p = p.substring(0, p.length - 1);
    }
    if (!p.startsWith('/')) p = '/$p';
    return p.isEmpty ? '/' : p;
  }

  static String _parent(String path) {
    if (path == '/' || path.isEmpty) return '/';
    final i = path.lastIndexOf('/');
    if (i <= 0) return '/';
    return path.substring(0, i);
  }
}
