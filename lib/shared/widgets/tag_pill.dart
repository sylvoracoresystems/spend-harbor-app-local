import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';
import '../../theme/app_typography.dart';

/// 共享标签胶囊：用于 Dashboard / Transactions 列表行、Stats tag distribution。
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
        borderRadius: AppRadius.brFull,
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
