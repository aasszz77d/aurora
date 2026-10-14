import 'package:flutter/material.dart';
import 'package:aurora/models/virt_key_def.dart';
import 'package:aurora/services/settings_store.dart';
import 'package:xterm/xterm.dart';

/// 底部虚拟按键条：布局由 [SettingsStore] 驱动。
class VirtKeysBar extends StatefulWidget {
  const VirtKeysBar({
    super.key,
    required this.onInput,
    required this.onKey,
  });

  final void Function(String data) onInput;
  final void Function(TerminalKey key) onKey;

  @override
  State<VirtKeysBar> createState() => _VirtKeysBarState();
}

class _VirtKeysBarState extends State<VirtKeysBar> {
  final _settings = SettingsStore.instance;
  bool _ctrl = false;
  bool _alt = false;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettings);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettings);
    super.dispose();
  }

  void _onSettings() {
    if (mounted) setState(() {});
  }

  void _tapDef(VirtKeyDef def) {
    switch (def.kind) {
      case VirtKeyKind.modifier:
        if (def.id == 'ctrl') {
          setState(() => _ctrl = !_ctrl);
        } else if (def.id == 'alt') {
          setState(() => _alt = !_alt);
        }
        return;
      case VirtKeyKind.terminalKey:
        if (def.terminalKey != null) {
          widget.onKey(def.terminalKey!);
        }
      case VirtKeyKind.char:
        final ch = def.char ?? '';
        if (_ctrl && ch.isNotEmpty) {
          final code = ch.toUpperCase().codeUnitAt(0);
          if (code >= 65 && code <= 90) {
            widget.onInput(String.fromCharCode(code - 64));
          } else {
            widget.onInput(ch);
          }
        } else if (_alt && ch.isNotEmpty) {
          widget.onInput('\x1b$ch');
        } else {
          widget.onInput(ch);
        }
      case VirtKeyKind.control:
        if (def.controlCode != null) {
          widget.onInput(String.fromCharCode(def.controlCode!));
        }
    }
    if (_ctrl) setState(() => _ctrl = false);
    if (_alt) setState(() => _alt = false);
  }

  bool _isActive(VirtKeyDef def) {
    if (def.id == 'ctrl') return _ctrl;
    if (def.id == 'alt') return _alt;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = scheme.surfaceContainerHighest;
    final keys = _settings.enabledVirtKeys;
    final perRow = _settings.virtKeysPerRow;

    if (keys.isEmpty) {
      return const SizedBox.shrink();
    }

    final rows = <List<VirtKeyDef>>[];
    for (var i = 0; i < keys.length; i += perRow) {
      rows.add(
        keys.sublist(i, i + perRow > keys.length ? keys.length : i + perRow),
      );
    }

    Widget keyBtn(VirtKeyDef def) {
      final active = _isActive(def);
      final isEnter = def.id == 'enter';
      return Expanded(
        flex: isEnter ? 14 : 10,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Material(
            color: active ? scheme.primary : bg,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => _tapDef(def),
              child: SizedBox(
                height: 36,
                child: Center(
                  child: Text(
                    def.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: active ? scheme.onPrimary : scheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      elevation: 4,
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final row in rows)
                Row(
                  children: [
                    for (final k in row) keyBtn(k),
                    // 不足一行时补空位，避免键被拉得过宽
                    for (var i = row.length; i < perRow; i++)
                      const Expanded(flex: 10, child: SizedBox()),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
