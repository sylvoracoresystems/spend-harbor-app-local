import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_typography.dart';
import '../icons/icon_registry.dart';

/// 10 列调色板网格。可视高度约 2.5 行；末尾有一个自定义颜色 + 按钮。
class ColorGrid extends StatelessWidget {
  const ColorGrid({super.key, required this.value, required this.onPicked});

  final String value;
  final ValueChanged<String> onPicked;

  static const _cols = 10;
  static const _spacing = 6.0;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final items = [...kPaletteHex, _customSlot];
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _cols,
        mainAxisSpacing: _spacing,
        crossAxisSpacing: _spacing,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final hex = items[i];
        if (hex == _customSlot) {
          return _CustomTile(
            borderColor: c.border,
            iconColor: c.textMuted,
            onTap: () async {
              final picked = await _showHexDialog(context, value);
              if (picked != null) onPicked(picked);
            },
          );
        }
        final selected = hex.toLowerCase() == value.toLowerCase();
        return GestureDetector(
          onTap: () => onPicked(hex),
          child: Container(
            decoration: BoxDecoration(
              color: _hexToColor(hex),
              shape: BoxShape.circle,
              border: Border.all(
                width: selected ? 3 : 1,
                color: selected ? c.actionInk : c.border,
              ),
            ),
          ),
        );
      },
    );
  }

  static const _customSlot = '__custom__';
}

class _CustomTile extends StatelessWidget {
  const _CustomTile({
    required this.borderColor,
    required this.iconColor,
    required this.onTap,
  });
  final Color borderColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(width: 1, color: borderColor),
        ),
        child: Icon(LucideIcons.plus, size: 16, color: iconColor),
      ),
    );
  }
}

Future<String?> _showHexDialog(BuildContext context, String initial) async {
  final l = AppL10n.of(context);
  final c = context.appColors;
  final initialHex = _safeHex(initial) ?? 'ff5a5f';
  final ctrl = TextEditingController(text: initialHex);
  String preview = initialHex;

  // 12 色相 × 7 亮度 的 HSL 面板
  const hues = 12;
  const lights = 7;
  final swatches = <String>[
    for (int l = 0; l < lights; l++)
      for (int h = 0; h < hues; h++)
        _hslHex(
          (h * 360 / hues),
          0.78,
          0.18 + (l * (0.82 - 0.18) / (lights - 1)),
        ),
  ];
  // 第一行用中性灰阶覆盖，方便选黑/白/灰
  for (int h = 0; h < hues; h++) {
    final v = (h / (hues - 1));
    swatches[h] = _hslHex(0, 0, v);
  }

  return showDialog<String>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          title: Text(l.colorCustomTitle),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: hues,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: swatches.length,
                  itemBuilder: (_, i) {
                    final hex = swatches[i];
                    final selected =
                        hex.toLowerCase() == preview.toLowerCase();
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          preview = hex;
                          ctrl.text = hex;
                          ctrl.selection = TextSelection.fromPosition(
                            TextPosition(offset: ctrl.text.length),
                          );
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _hexToColor(hex),
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: selected ? 2.5 : 0.5,
                            color: selected ? c.actionInk : c.border,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _hexToColor(preview),
                        shape: BoxShape.circle,
                        border: Border.all(color: c.border),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        maxLength: 6,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9a-fA-F]')),
                        ],
                        decoration: InputDecoration(
                          prefixText: '#',
                          hintText: 'RRGGBB',
                          counterText: '',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.brLg,
                          ),
                        ),
                        style: AppTypography.sm,
                        onChanged: (v) {
                          final s = _safeHex(v);
                          if (s != null) setState(() => preview = s);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(l.txCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop('#$preview'),
              child: Text(l.txSave),
            ),
          ],
        );
      });
    },
  );
}

/// HSL → 6 位 hex（无 #，小写）。h ∈ [0,360), s,l ∈ [0,1]。
String _hslHex(double h, double s, double l) {
  final color = HSLColor.fromAHSL(1, h % 360, s.clamp(0, 1), l.clamp(0, 1))
      .toColor();
  return (color.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0');
}

/// 校验并规范化（小写无 #）；非法返回 null。
String? _safeHex(String input) {
  final v = input.replaceFirst('#', '').toLowerCase();
  if (v.length != 6) return null;
  if (!RegExp(r'^[0-9a-f]{6}$').hasMatch(v)) return null;
  return v;
}

Color _hexToColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('ff$cleaned', radix: 16));
}
