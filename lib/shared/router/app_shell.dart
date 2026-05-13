import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

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
      _NavDestination(LucideIcons.layoutDashboard, l.tabDashboard),
      _NavDestination(LucideIcons.pieChart, l.tabStats),
      _NavDestination(LucideIcons.listOrdered, l.tabTransactions),
      _NavDestination(LucideIcons.settings, l.tabSettings),
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

class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.shell,
    required this.destinations,
    required this.fabLabel,
  });

  final StatefulNavigationShell shell;
  final List<_NavDestination> destinations;
  final String fabLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final showFab = shell.currentIndex != 3; // 设置页不显示
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) {
          HapticFeedback.selectionClick();
          shell.goBranch(i, initialLocation: i == shell.currentIndex);
        },
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
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

class _TabletShell extends StatelessWidget {
  const _TabletShell({
    required this.shell,
    required this.destinations,
    required this.fabLabel,
  });

  final StatefulNavigationShell shell;
  final List<_NavDestination> destinations;
  final String fabLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: (i) => shell.goBranch(
              i,
              initialLocation: i == shell.currentIndex,
            ),
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
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
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
