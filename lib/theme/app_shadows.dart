import 'package:flutter/widgets.dart';

class AppShadows {
  AppShadows._();

  static const BoxShadow sm = BoxShadow(
    offset: Offset(0, 1),
    blurRadius: 2,
    color: Color(0x0A000000),
  );

  static const BoxShadow md = BoxShadow(
    offset: Offset(0, 2),
    blurRadius: 6,
    color: Color(0x0F000000),
  );

  static const BoxShadow lg = BoxShadow(
    offset: Offset(0, 8),
    blurRadius: 16,
    color: Color(0x1A000000),
  );

  static const List<BoxShadow> card = [sm];
  static const List<BoxShadow> popover = [md];
  static const List<BoxShadow> modal = [lg];
}
