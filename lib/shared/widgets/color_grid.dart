import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
  final ctrl = TextEditingController(text: initial.replaceFirst('#', ''));
  String? preview = _safeHex(ctrl.text);

  return showDialog<String>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          title: Text(l.colorCustomTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: preview == null
                          ? c.borderSoft
                          : _hexToColor(preview!),
                      shape: BoxShape.circle,
                      border: Border.all(color: c.border),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      maxLength: 6,
                      autofocus: true,
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
                        setState(() => preview = _safeHex(v));
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(l.txCancel),
            ),
            FilledButton(
              onPressed: preview == null
                  ? null
                  : () => Navigator.of(ctx).pop('#${preview!}'),
              child: Text(l.txSave),
            ),
          ],
        );
      });
    },
  );
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
