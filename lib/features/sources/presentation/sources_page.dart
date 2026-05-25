import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../data/seed/default_name_resolver.dart';
import '../../../domain/value_objects/currency.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/icons/icon_registry.dart';
import '../../../shared/utils/hex_color.dart';
import '../../../shared/widgets/root_page_scaffold.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

/// 来源管理页（设置入口）：列出全部来源并支持新建/进入编辑。
class SourcesPage extends ConsumerWidget {
  const SourcesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final async = ref.watch(allSourcesProvider);

    return SubPageScaffold(
      title: l.settingsSources,
      actions: [
        IconButton(
          tooltip: l.srcAdd,
          icon: const Icon(LucideIcons.plus),
          onPressed: () => context.push('/settings/sources/new'),
        ),
      ],
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
    );
  }
}

/// 单条来源行：图标 + 名称 + 货币，点击进入编辑。
class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.src});
  final Source src;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final label =
        resolveDefaultName(AppL10n.of(context), src.nameKey) ?? src.name;
    final color = HexColor.fromHex(src.color);
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
