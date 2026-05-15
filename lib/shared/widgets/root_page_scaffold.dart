import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// 四个根 tab 页（Dashboard / Stats / Transactions / Settings）共用的外壳。
///
/// 统一以下视觉规则，避免各页面零散重写：
/// - Scaffold + AppBar 使用 theme 默认背景（`bgMint`），elevation = 0。
/// - 标题居中、走 `AppTypography.lg + semibold`。
/// - body 顶部可选 [pageHeader] 槽位（filter bar / period segmented 等二级头）。
/// - body 自带底部 SafeArea，避免被 NavigationBar 遮住。
///
/// Transactions 的「选中模式 AppBar」走 [customAppBar] 直接覆盖。
class RootPageScaffold extends StatelessWidget {
  const RootPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.pageHeader,
    this.customAppBar,
  });

  /// 标题文案。当传 [customAppBar] 时被忽略。
  final String title;

  /// AppBar 右侧 actions。当传 [customAppBar] 时被忽略。
  final List<Widget>? actions;

  /// 完全自定义 AppBar；优先级高于 [title] / [actions]。
  final PreferredSizeWidget? customAppBar;

  /// 顶部二级头（DashboardFilterBar / StatsFilterBar 等）。无内边距，由组件自控。
  final Widget? pageHeader;

  /// 主体内容。底部自动包 SafeArea。
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar ?? _defaultAppBar(context),
      body: SafeArea(
        top: false,
        child: pageHeader == null
            ? body
            : Column(
                children: [
                  pageHeader!,
                  Expanded(child: body),
                ],
              ),
      ),
    );
  }

  PreferredSizeWidget _defaultAppBar(BuildContext context) {
    final c = context.appColors;
    return AppBar(
      title: Text(title),
      centerTitle: true,
      titleTextStyle: AppTypography.lg.copyWith(
        color: c.actionInk,
        fontWeight: AppTypography.weightSemibold,
      ),
      actions: actions,
    );
  }
}

/// 根 tab 页空态：居中文案，颜色和字号与四个页面对齐。
class RootPageEmpty extends StatelessWidget {
  const RootPageEmpty({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTypography.sm.copyWith(color: c.textMuted),
        ),
      ),
    );
  }
}

/// Settings 系子页面（profile / categories / tags / budgets / sources /
/// data_io / language / currency / appearance / security / about / legal
/// 以及它们的 edit/new 页）共用的外壳。与根 tab 形成层级对比：
///
/// - Scaffold + AppBar 背景统一为 `c.surface`（白），不再用 `bgMint`。
/// - AppBar 默认带返回按钮（系统自动），`centerTitle` 走 theme 默认（false）。
/// - 标题字号同 root tab：`AppTypography.lg + semibold`。
class SubPageScaffold extends StatelessWidget {
  const SubPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.leading,
    this.bottom,
    this.floatingActionButton,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        backgroundColor: c.surface,
        leading: leading,
        title: Text(title),
        titleTextStyle: AppTypography.lg.copyWith(
          color: c.actionInk,
          fontWeight: AppTypography.weightSemibold,
        ),
        actions: actions,
        bottom: bottom,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
