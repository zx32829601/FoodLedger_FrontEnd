import 'package:flutter/widgets.dart';

/// FoodLedger 元件使用的圓角尺寸。
abstract final class AppRadius {
  static const small = 8.0;
  static const medium = 14.0;
  static const large = 22.0;

  static const smallBorderRadius = BorderRadius.all(Radius.circular(small));
  static const mediumBorderRadius = BorderRadius.all(Radius.circular(medium));
}
