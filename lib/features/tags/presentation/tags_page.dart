import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../data/seed/default_name_resolver.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class TagsPage extends ConsumerWidget {
  const TagsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final async = ref.watch(allTagsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTags)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) {
          if (rows.isEmpty) {
            return Center(
              child: Text(
                l.tagEmpty,
                style: AppTypography.sm.copyWith(color: c.textMuted),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.x2),
            itemCount: rows.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: c.border, indent: AppSpacing.x4),
            itemBuilder: (context, i) => _TagRow(tag: rows[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/settings/tags/new'),
        icon: const Icon(LucideIcons.plus),
        label: Text(l.tagAdd),
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({required this.tag});
  final Tag tag;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final label =
        resolveDefaultName(AppL10n.of(context), tag.nameKey) ?? tag.name;
    final color = _hexToColor(tag.color);
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: AppRadius.brFull,
        ),
        child: Icon(LucideIcons.hash, color: color, size: 18),
      ),
      title: Text(
        label,
        style: AppTypography.sm.copyWith(
          color: c.actionInk,
          fontWeight: AppTypography.weightSemibold,
        ),
      ),
      trailing: Icon(LucideIcons.chevronRight, size: 18, color: c.textMuted),
      onTap: () => context.push('/settings/tags/${tag.id}/edit'),
    );
  }
}

Color _hexToColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('ff$cleaned', radix: 16));
}
