import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/placeholder_page.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderPage(
      title: AppL10n.of(context).tabStats,
      showAppBar: false,
    );
  }
}
