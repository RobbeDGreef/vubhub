import 'package:flutter/material.dart';

import 'const.dart';

final Color AlmostWhite = Color.fromRGBO(235, 238, 239, 1.0);
final Color AlmostDark = Color.fromRGBO(50, 50, 50, 1.0);
final Color NearDark = Color.fromRGBO(40, 40, 40, 1.0);

ThemeData buildTheme(bool light) {
  return ThemeData(
    primaryColor: VubOrange,
    accentColor: light ? VubBlue : VubOrange,
    unselectedWidgetColor: light ? VubBlue : VubOrange,
    toggleableActiveColor: light ? VubBlue : VubOrange,
    colorScheme: light ? ColorScheme.light() : ColorScheme.dark(),
    scaffoldBackgroundColor: light ? AlmostWhite : AlmostDark,
    cardColor: light ? null : NearDark,
  );
}
