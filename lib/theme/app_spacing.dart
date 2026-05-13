import 'package:flutter/widgets.dart';

class AppSpacing {
  AppSpacing._();

  static const double x1 = 4.0;
  static const double x2 = 8.0;
  static const double x3 = 12.0;
  static const double x4 = 16.0;
  static const double x5 = 20.0;
  static const double x6 = 24.0;
  static const double x8 = 32.0;
  static const double x10 = 40.0;
  static const double x12 = 48.0;
  static const double x16 = 64.0;
  static const double x24 = 96.0;

  static const EdgeInsets listItem =
      EdgeInsets.symmetric(horizontal: x4, vertical: x3);
  static const EdgeInsets card = EdgeInsets.all(x4);
  static const EdgeInsets cardLarge = EdgeInsets.all(x6);
  static const EdgeInsets dialog = EdgeInsets.all(x6);
  static const EdgeInsets input =
      EdgeInsets.symmetric(horizontal: x3, vertical: x2 + 2);
  static const EdgeInsets button =
      EdgeInsets.symmetric(horizontal: x4, vertical: x2 + 2);
  static const EdgeInsets buttonCompact =
      EdgeInsets.symmetric(horizontal: x3, vertical: 6);
}
