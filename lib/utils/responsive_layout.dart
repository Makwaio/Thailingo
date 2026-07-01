import 'package:flutter/material.dart';

class ResponsiveLayout {
  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  static bool isPortrait(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.portrait;

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static EdgeInsets pagePadding(BuildContext context) {
    if (isLandscape(context)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 8);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }

  static double titleSize(BuildContext context) =>
      isLandscape(context) ? 20 : 24;

  static double bodySize(BuildContext context) =>
      isLandscape(context) ? 14 : 16;

  static double octagonSize(BuildContext context) =>
      isLandscape(context) ? 60 : 75;
}
