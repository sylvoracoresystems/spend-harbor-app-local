import 'package:flutter/material.dart';

import '../../../../theme/app_typography.dart';

class TagPill extends StatelessWidget {
  const TagPill({
    super.key,
    required this.label,
    required this.color,
    this.compact = false,
    this.italic = false,
  });

  final String label;
  final Color color;
  final bool compact;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: (compact ? AppTypography.xs : AppTypography.sm).copyWith(
          color: Colors.white,
          fontWeight: AppTypography.weightSemibold,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
  }
}
