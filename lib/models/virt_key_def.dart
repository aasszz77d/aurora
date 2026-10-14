import 'package:xterm/xterm.dart';

enum VirtKeyKind {
  /// 可切换的修饰键（Ctrl / Alt）
  modifier,
  /// 发送 TerminalKey
  terminalKey,
  /// 发送原始字符
  char,
  /// 发送控制字符（如 Ctrl+C）
  control,
}

/// 一枚可配置的虚拟按键。
class VirtKeyDef {
  const VirtKeyDef({
    required this.id,
    required this.label,
    required this.kind,
    this.terminalKey,
    this.char,
    this.controlCode,
  });

  final String id;
  final String label;
  final VirtKeyKind kind;
  final TerminalKey? terminalKey;
  final String? char;
  final int? controlCode;

  static const catalog = <VirtKeyDef>[
    VirtKeyDef(id: 'ctrl', label: 'Ctrl', kind: VirtKeyKind.modifier),
    VirtKeyDef(id: 'alt', label: 'Alt', kind: VirtKeyKind.modifier),
    VirtKeyDef(
      id: 'esc',
      label: 'Esc',
      kind: VirtKeyKind.terminalKey,
      terminalKey: TerminalKey.escape,
    ),
    VirtKeyDef(
      id: 'tab',
      label: 'Tab',
      kind: VirtKeyKind.terminalKey,
      terminalKey: TerminalKey.tab,
    ),
    VirtKeyDef(id: 'dash', label: '—', kind: VirtKeyKind.char, char: '-'),
    VirtKeyDef(id: 'slash', label: '/', kind: VirtKeyKind.char, char: '/'),
    VirtKeyDef(id: 'pipe', label: '|', kind: VirtKeyKind.char, char: '|'),
    VirtKeyDef(
      id: 'up',
      label: '↑',
      kind: VirtKeyKind.terminalKey,
      terminalKey: TerminalKey.arrowUp,
    ),
    VirtKeyDef(
      id: 'down',
      label: '↓',
      kind: VirtKeyKind.terminalKey,
      terminalKey: TerminalKey.arrowDown,
    ),
    VirtKeyDef(
      id: 'left',
      label: '←',
      kind: VirtKeyKind.terminalKey,
      terminalKey: TerminalKey.arrowLeft,
    ),
    VirtKeyDef(
      id: 'right',
      label: '→',
      kind: VirtKeyKind.terminalKey,
      terminalKey: TerminalKey.arrowRight,
    ),
    VirtKeyDef(
      id: 'home',
      label: 'Home',
      kind: VirtKeyKind.terminalKey,
      terminalKey: TerminalKey.home,
    ),
    VirtKeyDef(
      id: 'end',
      label: 'End',
      kind: VirtKeyKind.terminalKey,
      terminalKey: TerminalKey.end,
    ),
    VirtKeyDef(
      id: 'pgup',
      label: 'PgUp',
      kind: VirtKeyKind.terminalKey,
      terminalKey: TerminalKey.pageUp,
    ),
    VirtKeyDef(
      id: 'pgdn',
      label: 'PgDn',
      kind: VirtKeyKind.terminalKey,
      terminalKey: TerminalKey.pageDown,
    ),
    VirtKeyDef(
      id: 'backspace',
      label: '⌫',
      kind: VirtKeyKind.terminalKey,
      terminalKey: TerminalKey.backspace,
    ),
    VirtKeyDef(
      id: 'delete',
      label: 'Del',
      kind: VirtKeyKind.terminalKey,
      terminalKey: TerminalKey.delete,
    ),
    VirtKeyDef(id: 'c_c', label: 'C-c', kind: VirtKeyKind.control, controlCode: 3),
    VirtKeyDef(id: 'c_d', label: 'C-d', kind: VirtKeyKind.control, controlCode: 4),
    VirtKeyDef(id: 'c_z', label: 'C-z', kind: VirtKeyKind.control, controlCode: 26),
    VirtKeyDef(id: 'c_l', label: 'C-l', kind: VirtKeyKind.control, controlCode: 12),
    VirtKeyDef(id: 'c_a', label: 'C-a', kind: VirtKeyKind.control, controlCode: 1),
    VirtKeyDef(id: 'c_e', label: 'C-e', kind: VirtKeyKind.control, controlCode: 5),
    VirtKeyDef(id: 'c_r', label: 'C-r', kind: VirtKeyKind.control, controlCode: 18),
    VirtKeyDef(id: 'c_w', label: 'C-w', kind: VirtKeyKind.control, controlCode: 23),
    VirtKeyDef(id: 'c_u', label: 'C-u', kind: VirtKeyKind.control, controlCode: 21),
    VirtKeyDef(id: 'c_k', label: 'C-k', kind: VirtKeyKind.control, controlCode: 11),
    VirtKeyDef(
      id: 'enter',
      label: 'Enter',
      kind: VirtKeyKind.terminalKey,
      terminalKey: TerminalKey.enter,
    ),
    VirtKeyDef(id: 'tilde', label: '~', kind: VirtKeyKind.char, char: '~'),
    VirtKeyDef(id: 'dollar', label: '\$', kind: VirtKeyKind.char, char: '\$'),
    VirtKeyDef(id: 'star', label: '*', kind: VirtKeyKind.char, char: '*'),
    VirtKeyDef(id: 'amp', label: '&', kind: VirtKeyKind.char, char: '&'),
    VirtKeyDef(id: 'semi', label: ';', kind: VirtKeyKind.char, char: ';'),
    VirtKeyDef(id: 'gt', label: '>', kind: VirtKeyKind.char, char: '>'),
    VirtKeyDef(id: 'lt', label: '<', kind: VirtKeyKind.char, char: '<'),
  ];

  static VirtKeyDef? byId(String id) {
    for (final k in catalog) {
      if (k.id == id) return k;
    }
    return null;
  }

  /// 默认布局（与原先三行一致）。
  static const defaultIds = <String>[
    'ctrl',
    'alt',
    'esc',
    'tab',
    'dash',
    'slash',
    'pipe',
    'up',
    'down',
    'left',
    'right',
    'home',
    'end',
    'backspace',
    'c_c',
    'c_d',
    'c_z',
    'c_l',
    'c_a',
    'c_e',
    'enter',
  ];

  /// 精简布局。
  static const compactIds = <String>[
    'ctrl',
    'esc',
    'tab',
    'up',
    'down',
    'left',
    'right',
    'c_c',
    'c_d',
    'c_z',
    'enter',
  ];
}
