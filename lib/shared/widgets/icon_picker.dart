import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../icons/icon_registry.dart';

/// kIconRegistry 的网格选择器。选中项以 [color] 高亮，其余为静默灰底。
///
/// 替代 category_edit / source_edit 内联的 _IconPicker。
class IconPicker extends StatelessWidget {
  const IconPicker({
    super.key,
    required this.value,
    required this.color,
    required this.onPicked,
  });

  final String value;
  final Color color;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final entries = kIconRegistry.entries.toList();
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.brXl,
        border: Border.all(color: c.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.x2),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 48,
          mainAxisSpacing: AppSpacing.x2,
          crossAxisSpacing: AppSpacing.x2,
          childAspectRatio: 1,
        ),
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final entry = entries[i];
          final selected = value == entry.key;
          return GestureDetector(
            onTap: () => onPicked(entry.key),
            child: Container(
              decoration: BoxDecoration(
                color: selected ? color : c.surfacePress,
                borderRadius: AppRadius.brFull,
                border: Border.all(color: selected ? color : c.border),
              ),
              child: Icon(
                entry.value,
                size: 18,
                color: selected ? Colors.white : c.textMuted,
              ),
            ),
          );
        },
      ),
    );
  }
}
