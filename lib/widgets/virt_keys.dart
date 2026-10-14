import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

/// 底部虚拟按键条（参考 ServerBox 思路，精简实现）。
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
  bool _ctrl = false;
  bool _alt = false;

  void _tapChar(String ch) {
    if (_ctrl) {
      final code = ch.toUpperCase().codeUnitAt(0);
      if (code >= 65 && code <= 90) {
        widget.onInput(String.fromCharCode(code - 64));
      } else {
        widget.onInput(ch);
      }
      setState(() => _ctrl = false);
    } else if (_alt) {
      widget.onInput('\x1b$ch');
      setState(() => _alt = false);
    } else {
      widget.onInput(ch);
    }
  }

  void _tapKey(TerminalKey key) {
    widget.onKey(key);
    if (_ctrl) setState(() => _ctrl = false);
    if (_alt) setState(() => _alt = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = scheme.surfaceContainerHighest;

    Widget keyBtn({
      required String label,
      VoidCallback? onTap,
      bool active = false,
      double flex = 1,
    }) {
      return Expanded(
        flex: (flex * 10).round(),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Material(
            color: active ? scheme.primary : bg,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: onTap,
              child: SizedBox(
                height: 36,
                child: Center(
                  child: Text(
                    label,
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
              Row(
                children: [
                  keyBtn(
                    label: 'Ctrl',
                    active: _ctrl,
                    onTap: () => setState(() => _ctrl = !_ctrl),
                  ),
                  keyBtn(
                    label: 'Alt',
                    active: _alt,
                    onTap: () => setState(() => _alt = !_alt),
                  ),
                  keyBtn(label: 'Esc', onTap: () => _tapKey(TerminalKey.escape)),
                  keyBtn(label: 'Tab', onTap: () => _tapKey(TerminalKey.tab)),
                  keyBtn(label: '—', onTap: () => _tapChar('-')),
                  keyBtn(label: '/', onTap: () => _tapChar('/')),
                  keyBtn(label: '|', onTap: () => _tapChar('|')),
                ],
              ),
              Row(
                children: [
                  keyBtn(label: '↑', onTap: () => _tapKey(TerminalKey.arrowUp)),
                  keyBtn(label: '↓', onTap: () => _tapKey(TerminalKey.arrowDown)),
                  keyBtn(label: '←', onTap: () => _tapKey(TerminalKey.arrowLeft)),
                  keyBtn(label: '→', onTap: () => _tapKey(TerminalKey.arrowRight)),
                  keyBtn(label: 'Home', onTap: () => _tapKey(TerminalKey.home)),
                  keyBtn(label: 'End', onTap: () => _tapKey(TerminalKey.end)),
                  keyBtn(label: '⌫', onTap: () => _tapKey(TerminalKey.backspace)),
                ],
              ),
              Row(
                children: [
                  keyBtn(label: 'C-c', onTap: () {
                    widget.onInput(String.fromCharCode(3));
                  }),
                  keyBtn(label: 'C-d', onTap: () {
                    widget.onInput(String.fromCharCode(4));
                  }),
                  keyBtn(label: 'C-z', onTap: () {
                    widget.onInput(String.fromCharCode(26));
                  }),
                  keyBtn(label: 'C-l', onTap: () {
                    widget.onInput(String.fromCharCode(12));
                  }),
                  keyBtn(label: 'C-a', onTap: () {
                    widget.onInput(String.fromCharCode(1));
                  }),
                  keyBtn(label: 'C-e', onTap: () {
                    widget.onInput(String.fromCharCode(5));
                  }),
                  keyBtn(
                    label: 'Enter',
                    flex: 1.4,
                    onTap: () => _tapKey(TerminalKey.enter),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
