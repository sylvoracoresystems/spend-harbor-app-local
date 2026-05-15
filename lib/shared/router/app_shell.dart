import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../features/transactions/application/transactions_list_controller.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Transactions tab 在底栏中的索引。离开此 tab 时清空 transactionsFilter
/// （Stats 跳过来带的 category/tag/dateRange 等临时筛选不应跨 tab 保留）。
const int _kTransactionsTabIndex = 2;

/// 平板/桌面切换断点（PRODUCT_SPEC §3.4 md:）。
const double kTabletBreakpoint = 768;

/// 主框架：StatefulShellRoute 的容器。
/// 宽度 < 768 用底部 NavigationBar；≥ 768 切换为顶部 NavigationRail。
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final destinations = <_NavDestination>[
      _NavDestination(Symbols.home, l.tabDashboard),
      _NavDestination(Symbols.bar_chart, l.tabStats),
      _NavDestination(Symbols.receipt_long, l.tabTransactions),
      _NavDestination(Symbols.settings, l.tabSettings),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= kTabletBreakpoint;
        return isTablet
            ? _TabletShell(
                shell: navigationShell,
                destinations: destinations,
                fabLabel: l.fabAddTransaction,
              )
            : _MobileShell(
                shell: navigationShell,
                destinations: destinations,
                fabLabel: l.fabAddTransaction,
              );
      },
    );
  }
}

class _MobileShell extends ConsumerWidget {
  const _MobileShell({
    required this.shell,
    required this.destinations,
    required this.fabLabel,
  });

  final StatefulNavigationShell shell;
  final List<_NavDestination> destinations;
  final String fabLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final showFab = shell.currentIndex != 3; // 设置页不显示
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        indicatorColor: Colors.transparent,
        overlayColor: WidgetStatePropertyAll(c.action.withValues(alpha: 0.08)),
        onDestinationSelected: (i) {
          HapticFeedback.selectionClick();
          if (i != _kTransactionsTabIndex) {
            ref.read(transactionsFilterProvider.notifier).state = null;
          }
          shell.goBranch(i, initialLocation: i == shell.currentIndex);
        },
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon,
                  weight: 300, fill: 0, color: c.textMuted),
              selectedIcon: Icon(d.icon,
                  weight: 300, fill: 1, color: c.action),
              label: d.label,
            ),
        ],
      ),
      floatingActionButton: showFab
          ? FloatingActionButton(
              tooltip: fabLabel,
              backgroundColor: c.action,
              foregroundColor: Colors.white,
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push('/transactions/new');
              },
              child: const Icon(LucideIcons.plus),
            )
          : null,
    );
  }
}

class _TabletShell extends ConsumerWidget {
  const _TabletShell({
    required this.shell,
    required this.destinations,
    required this.fabLabel,
  });

  final StatefulNavigationShell shell;
  final List<_NavDestination> destinations;
  final String fabLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: (i) {
              if (i != _kTransactionsTabIndex) {
                ref.read(transactionsFilterProvider.notifier).state = null;
              }
              shell.goBranch(i, initialLocation: i == shell.currentIndex);
            },
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.x4),
              child: FloatingActionButton(
                tooltip: fabLabel,
                backgroundColor: c.action,
                foregroundColor: Colors.white,
                elevation: 0,
                onPressed: () {
                HapticFeedback.lightImpact();
                context.push('/transactions/new');
              },
                child: const Icon(LucideIcons.plus),
              ),
            ),
            useIndicator: false,
            selectedIconTheme: IconThemeData(color: c.action),
            unselectedIconTheme: IconThemeData(color: c.textMuted),
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon, weight: 300, fill: 0),
                  selectedIcon: Icon(d.icon, weight: 300, fill: 1),
                  label: Text(d.label),
                ),
            ],
          ),
          VerticalDivider(width: 1, color: c.border),
          Expanded(child: shell),
        ],
      ),
    );
  }
}

class _NavDestination {
  const _NavDestination(this.icon, this.label);
  final IconData icon;
  final String label;
}
