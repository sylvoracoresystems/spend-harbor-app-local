import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/root_page_scaffold.dart';
import '../../../theme/app_spacing.dart';
import 'widgets/stats_distribution_card.dart';
import 'widgets/stats_filter_bar.dart';
import 'widgets/stats_top_card.dart';
import 'widgets/stats_trend_card.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  final _tagDistKey = GlobalKey();

  Future<void> _jumpToTagDist() async {
    final ctx = _tagDistKey.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      alignment: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    // 宽屏（iPad / 横屏大屏）下，category 与 tag 两张分布卡并排展示。
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    final distributions = isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: CategoryDistributionCard()),
              const SizedBox(width: AppSpacing.x3),
              Expanded(child: TagDistributionCard(cardKey: _tagDistKey)),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CategoryDistributionCard(),
              const SizedBox(height: AppSpacing.x3),
              TagDistributionCard(cardKey: _tagDistKey),
            ],
          );
    return RootPageScaffold(
      title: l.tabStats,
      pageHeader: const StatsFilterBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x3,
          AppSpacing.x3,
          AppSpacing.x3,
          AppSpacing.x3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StatsTrendCard(),
            const SizedBox(height: AppSpacing.x3),
            distributions,
            const SizedBox(height: AppSpacing.x3),
            StatsTopCard(onJumpToTagDist: _jumpToTagDist),
          ],
        ),
      ),
    );
  }
}
