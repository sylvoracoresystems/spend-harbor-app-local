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
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/sources/presentation/source_edit_page.dart';
import '../../features/sources/presentation/sources_page.dart';
import '../../features/stats/presentation/stats_page.dart';
import '../../features/tags/presentation/tag_edit_page.dart';
import '../../features/tags/presentation/tags_page.dart';
import '../../features/transactions/presentation/recycle_bin_page.dart';
import '../../features/transactions/presentation/transaction_edit_page.dart';
import '../../features/transactions/presentation/transactions_page.dart';
import '../../l10n/generated/app_localizations.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/placeholder_page.dart';
import 'app_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// Settings 子路由配置：路径 + 标题构造器（用 ARB 解析）。
typedef _SettingsRoute = ({String path, String Function(AppL10n) title});

const _settingsRoutes = <_SettingsRoute>[
  (path: '/settings/profile', title: _profile),
  // categories 已实现，从占位列表中移除
  // tags 已实现，从占位列表中移除
  // sources 已实现，从占位列表中移除
  // budgets 已实现，从占位列表中移除
  // export 已实现，从占位列表中移除
  // import 已实现，从占位列表中移除
  // backup 已实现，从占位列表中移除
  (path: '/settings/currency', title: _currency),
  (path: '/settings/language', title: _language),
  (path: '/settings/appearance', title: _appearance),
  (path: '/settings/security', title: _security),
  (path: '/settings/about', title: _about),
  (path: '/settings/legal', title: _legal),
];

String _profile(AppL10n l) => l.settingsProfile;
String _currency(AppL10n l) => l.settingsCurrency;
String _language(AppL10n l) => l.settingsLanguage;
String _appearance(AppL10n l) => l.settingsAppearance;
String _security(AppL10n l) => l.settingsSecurity;
String _about(AppL10n l) => l.settingsAbout;
String _legal(AppL10n l) => l.settingsLegal;

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
              builder: (_, __) => const TransactionsPage(),
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
