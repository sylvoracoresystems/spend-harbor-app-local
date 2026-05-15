import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(l.tabStats),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.x3),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.x3),
              child: StatsFilterBar(),
            ),
            const SizedBox(height: AppSpacing.x3),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.x3),
              child: StatsTrendCard(),
            ),
            const SizedBox(height: AppSpacing.x3),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.x3),
              child: CategoryDistributionCard(),
            ),
            const SizedBox(height: AppSpacing.x3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
              child: TagDistributionCard(cardKey: _tagDistKey),
            ),
            const SizedBox(height: AppSpacing.x3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
              child: StatsTopCard(onJumpToTagDist: _jumpToTagDist),
            ),
          ],
        ),
      ),
    );
  }
}
