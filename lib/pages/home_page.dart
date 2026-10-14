import 'package:flutter/material.dart';
import 'package:aurora/models/server.dart';
import 'package:aurora/pages/server_edit_page.dart';
import 'package:aurora/pages/settings_page.dart';
import 'package:aurora/pages/terminal_page.dart';
import 'package:aurora/services/server_store.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _store = ServerStore.instance;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openTerminal(Server server) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TerminalPage(server: server),
      ),
    );
  }

  Future<void> _addServer() async {
    final result = await Navigator.of(context).push<Server>(
      MaterialPageRoute(builder: (_) => const ServerEditPage()),
    );
    if (result != null && mounted) {
      // already saved in edit page
    }
  }

  Future<void> _editServer(Server server) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServerEditPage(server: server),
      ),
    );
  }

  Future<void> _deleteServer(Server server) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除服务器'),
        content: Text('确定删除「${server.name}」？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _store.remove(server.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final servers = _store.servers;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('服务器'),
        actions: [
          IconButton(
            tooltip: '设置',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addServer,
        icon: const Icon(Icons.add),
        label: const Text('添加'),
      ),
      body: servers.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.dns_outlined,
                      size: 72, color: scheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    '还没有服务器',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击右下角添加一台',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.outline,
                        ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
              itemCount: servers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final s = servers[index];
                return _ServerTile(
                  server: s,
                  onTap: () => _openTerminal(s),
                  onEdit: () => _editServer(s),
                  onDelete: () => _deleteServer(s),
                );
              },
            ),
    );
  }
}

class _ServerTile extends StatelessWidget {
  const _ServerTile({
    required this.server,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Server server;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.terminal, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      server.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${server.username}@${server.displayAddr}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('编辑')),
                  PopupMenuItem(value: 'delete', child: Text('删除')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
