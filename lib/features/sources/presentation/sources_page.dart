import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../data/seed/default_name_resolver.dart';
import '../../../domain/value_objects/currency.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/icons/icon_registry.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class SourcesPage extends ConsumerWidget {
  const SourcesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final async = ref.watch(allSourcesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsSources)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) {
          if (rows.isEmpty) {
            return Center(
              child: Text(
                l.srcEmpty,
                style: AppTypography.sm.copyWith(color: c.textMuted),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.x2),
            itemCount: rows.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: c.border, indent: AppSpacing.x4),
            itemBuilder: (context, i) => _SourceRow(src: rows[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/settings/sources/new'),
        icon: const Icon(LucideIcons.plus),
        label: Text(l.srcAdd),
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.src});
  final Source src;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final label =
        resolveDefaultName(AppL10n.of(context), src.nameKey) ?? src.name;
    final color = _hexToColor(src.color);
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: AppRadius.brFull,
        ),
        child: Icon(iconFor(src.icon), color: color, size: 18),
      ),
      title: Text(
        label,
        style: AppTypography.sm.copyWith(
          color: c.actionInk,
          fontWeight: AppTypography.weightSemibold,
        ),
      ),
      subtitle: Text(
        '${src.currency} · ${Currency.byCode(src.currency).symbol}',
        style: AppTypography.xs.copyWith(color: c.textMuted),
      ),
      trailing: Icon(LucideIcons.chevronRight, size: 18, color: c.textMuted),
      onTap: () => context.push('/settings/sources/${src.id}/edit'),
    );
  }
}

Color _hexToColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('ff$cleaned', radix: 16));
}
