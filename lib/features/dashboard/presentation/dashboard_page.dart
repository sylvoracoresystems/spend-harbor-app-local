import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../data/seed/default_name_resolver.dart';
import '../../../domain/enums/budget_period.dart';
import '../../../domain/enums/budget_scope.dart';
import '../../../domain/value_objects/currency.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/root_page_scaffold.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../data_io/presentation/backup_reminder_banner.dart';
import '../../transactions/presentation/transaction_list_row.dart';
import '../application/budget_progress_provider.dart';
import '../application/dashboard_summary_controller.dart';
import 'dashboard_filter_bar.dart';

part 'dashboard_page/metrics.dart';
part 'dashboard_page/recent.dart';
part 'dashboard_page/budgets.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final recentAsync = ref.watch(recentTransactionsProvider);

    return RootPageScaffold(
      title: l.tabDashboard,
      pageHeader: const DashboardFilterBar(),
      body: metricsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (metrics) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.x4),
            children: [
              const BackupReminderBanner(),
              _MetricsGrid(metrics: metrics),
              if (metrics.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.x6),
                  child: RootPageEmpty(text: l.dashEmpty),
                ),
              const SizedBox(height: AppSpacing.x6),
              const _BudgetsSection(),
              _RecentSection(asyncRows: recentAsync),
            ],
          );
        },
      ),
    );
  }
}
