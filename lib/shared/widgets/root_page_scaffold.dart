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
