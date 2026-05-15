import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/enums/transaction_type.dart';
import '../../features/budgets/presentation/budget_edit_page.dart';
import '../../features/budgets/presentation/budgets_page.dart';
import '../../features/categories/presentation/categories_page.dart';
import '../../features/categories/presentation/category_edit_page.dart';
import '../../features/data_io/presentation/export_page.dart';
import '../../features/data_io/presentation/backup_page.dart';
import '../../features/data_io/presentation/import_page.dart';
import '../../features/dashboard/application/dashboard_filter_provider.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import '../../features/settings/presentation/about_page.dart';
import '../../features/settings/presentation/appearance_page.dart';
import '../../features/settings/presentation/currency_page.dart';
import '../../features/settings/presentation/language_page.dart';
import '../../features/settings/presentation/legal_page.dart';
import '../../features/settings/presentation/profile_page.dart';
import '../../features/settings/presentation/security_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/sources/presentation/source_edit_page.dart';
import '../../features/sources/presentation/sources_page.dart';
import '../../features/stats/presentation/stats_page.dart';
import '../../features/tags/presentation/tag_edit_page.dart';
import '../../features/tags/presentation/tags_page.dart';
import '../../features/transactions/presentation/recycle_bin_page.dart';
import '../../features/transactions/presentation/transaction_edit_page.dart';
import '../../features/transactions/application/transactions_list_controller.dart';
import '../../features/transactions/presentation/transactions_page.dart';
import '../../l10n/generated/app_localizations.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/placeholder_page.dart';
import 'app_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// Settings 子路由配置：路径 + 标题构造器（用 ARB 解析）。
typedef _SettingsRoute = ({String path, String Function(AppL10n) title});

const _settingsRoutes = <_SettingsRoute>[
  // profile / appearance / language 已实现，从占位列表中移除
  // categories 已实现，从占位列表中移除
  // tags 已实现，从占位列表中移除
  // sources 已实现，从占位列表中移除
  // budgets 已实现，从占位列表中移除
  // export 已实现，从占位列表中移除
  // import 已实现，从占位列表中移除
  // backup 已实现，从占位列表中移除
  // currency 已实现
  // language 已实现
  // appearance 已实现
  // security 已实现
  // about / legal 已实现
];

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    refreshListenable: _OnboardingListenable(ref),
    redirect: (context, state) {
      final done = ref.read(onboardingControllerProvider);
      final atOnboarding = state.matchedLocation == '/onboarding';
      if (!done && !atOnboarding) return '/onboarding';
      if (done && atOnboarding) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/transactions/new',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const TransactionEditPage(),
      ),
      GoRoute(
        path: '/transactions/recycle-bin',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const RecycleBinPage(),
      ),
      GoRoute(
        path: '/settings/categories',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const CategoriesPage(),
        routes: [
          GoRoute(
            path: 'new',
            parentNavigatorKey: _rootKey,
            builder: (_, state) => CategoryEditPage(
              initialType: state.extra is TransactionType
                  ? state.extra as TransactionType
                  : null,
            ),
          ),
          GoRoute(
            path: ':id/edit',
            parentNavigatorKey: _rootKey,
            builder: (_, state) => CategoryEditPage(
              id: state.pathParameters['id'],
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/settings/tags',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const TagsPage(),
        routes: [
          GoRoute(
            path: 'new',
            parentNavigatorKey: _rootKey,
            builder: (_, __) => const TagEditPage(),
          ),
          GoRoute(
            path: ':id/edit',
            parentNavigatorKey: _rootKey,
            builder: (_, state) =>
                TagEditPage(id: state.pathParameters['id']),
          ),
        ],
      ),
      GoRoute(
        path: '/settings/sources',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const SourcesPage(),
        routes: [
          GoRoute(
            path: 'new',
            parentNavigatorKey: _rootKey,
            builder: (_, __) => const SourceEditPage(),
          ),
          GoRoute(
            path: ':id/edit',
            parentNavigatorKey: _rootKey,
            builder: (_, state) =>
                SourceEditPage(id: state.pathParameters['id']),
          ),
        ],
      ),
      GoRoute(
        path: '/settings/export',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const ExportPage(),
      ),
      GoRoute(
        path: '/settings/import',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const ImportPage(),
      ),
      GoRoute(
        path: '/settings/backup',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const BackupPage(),
      ),
      GoRoute(
        path: '/settings/profile',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const ProfilePage(),
      ),
      GoRoute(
        path: '/settings/appearance',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const AppearancePage(),
      ),
      GoRoute(
        path: '/settings/language',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const LanguagePage(),
      ),
      GoRoute(
        path: '/settings/currency',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const CurrencyPage(),
      ),
      GoRoute(
        path: '/settings/security',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const SecurityPage(),
      ),
      GoRoute(
        path: '/settings/about',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const AboutPage(),
      ),
      GoRoute(
        path: '/settings/legal',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const LegalPage(),
      ),
      GoRoute(
        path: '/settings/budgets',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const BudgetsPage(),
        routes: [
          GoRoute(
            path: 'new',
            parentNavigatorKey: _rootKey,
            builder: (_, __) => const BudgetEditPage(),
          ),
          GoRoute(
            path: ':id/edit',
            parentNavigatorKey: _rootKey,
            builder: (_, state) =>
                BudgetEditPage(id: state.pathParameters['id']),
          ),
        ],
      ),
      GoRoute(
        path: '/transactions/:id/edit',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            TransactionEditPage(id: state.pathParameters['id']),
      ),
      for (final r in _settingsRoutes)
        GoRoute(
          path: r.path,
          parentNavigatorKey: _rootKey,
          builder: (context, _) =>
              PlaceholderPage(title: r.title(AppL10n.of(context))),
        ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (_, __) => const DashboardPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/stats', builder: (_, __) => const StatsPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/transactions',
              builder: (_, state) =>
                  _TransactionsRouteEntry(state.uri.queryParameters),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (_, __) => const SettingsPage(),
            ),
          ]),
        ],
      ),
    ],
  );
});

/// /transactions 路由入口：从 URL query 参数解析筛选条件并写入 provider。
///
/// 采用 post-frame 回调来避免在 build 阶段直接修改 provider 状态。
/// 关键顺序：先设置 month，再设置 filter。
/// 原因：_monthChangeListenerProvider 在 currentMonthProvider 变化时同步触发，
/// 会将 filter 清空（date-range 模式除外）。此时 filter 还未写入（仍为 null），
/// 监听器的清空操作是 no-op；随后再写入 filter，不会被覆盖。
class _TransactionsRouteEntry extends ConsumerStatefulWidget {
  const _TransactionsRouteEntry(this.qp);
  final Map<String, String> qp;

  @override
  ConsumerState<_TransactionsRouteEntry> createState() =>
      _TransactionsRouteEntryState();
}

class _TransactionsRouteEntryState
    extends ConsumerState<_TransactionsRouteEntry> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _apply();
    });
  }

  @override
  void didUpdateWidget(covariant _TransactionsRouteEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    // StatefulShellRoute.indexedStack 保留分支 State，跨次跳转到 /transactions
    // 不会重跑 initState；这里在 query 参数变化时重新应用。
    if (!_mapEquals(oldWidget.qp, widget.qp)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _apply();
      });
    }
  }

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (a[k] != b[k]) return false;
    }
    return true;
  }

  void _apply() {
    final qp = widget.qp;
    // 1. 先设置月份（监听器此时看到的 filter 仍为 null，清空是 no-op）。
    final m = qp['month'];
    if (m != null && RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(m)) {
      ref.read(currentMonthProvider.notifier).set(YearMonth.parse(m));
    }

    // 2. currency / source 写入 dashboardFilter（顶部过滤栏可见状态）。
    // 缺省参数视为「清空」，避免上次跳转残留导致与本次 Stats 选择不一致。
    final dash = ref.read(dashboardFilterProvider.notifier);
    dash.setCurrency(qp['currency']);
    dash.setSource(qp['source']);

    // 3. 构造 filter（category / tag / day / dateRange 等临时筛选）。
    final filter = TransactionsFilter(
      dayIso: qp['day'],
      dateStartIso: qp['dateStart'],
      dateEndIso: qp['dateEnd'],
      categoryId: qp['category'],
      tagId: qp['tag'],
      untagged: qp['untagged'] == '1',
    );

    // 4. 若 filter 携带 dateRange 但没有 month 参数，将月份锚定到区间起点。
    if (m == null && filter.hasDateRange) {
      final dt = DateTime.tryParse(filter.dateStartIso!);
      // date-range 模式下监听器不会清空 filter，直接设置月份即可。
      if (dt != null) {
        ref
            .read(currentMonthProvider.notifier)
            .set(YearMonth(dt.year, dt.month));
      }
    }

    // 5. 最后写入 filter（在月份已确定之后，避免被监听器覆盖）。
    ref.read(transactionsFilterProvider.notifier).state =
        filter.isEmpty ? null : filter;
  }

  @override
  Widget build(BuildContext context) => const TransactionsPage();
}

/// 把 Riverpod 的 onboarding 状态桥接到 go_router 的 refreshListenable。
class _OnboardingListenable extends ChangeNotifier {
  _OnboardingListenable(this._ref) {
    _sub = _ref.listen<bool>(
      onboardingControllerProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;
  late final ProviderSubscription<bool> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
