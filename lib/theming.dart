import 'package:flutter/material.dart';

import 'const.dart';

final Color AlmostWhite = Color.fromRGBO(235, 238, 239, 1.0);
final Color AlmostDark = Color.fromRGBO(72, 74, 82, 1.0);

ThemeData buildTheme(bool light) {
  return ThemeData(
    primaryColor: VubOrange,
    accentColor: light ? VubBlue : VubOrange,
    unselectedWidgetColor: light ? VubBlue : VubOrange,
    toggleableActiveColor: light ? VubBlue : VubOrange,
    colorScheme: light ? ColorScheme.light() : ColorScheme.dark(),
    scaffoldBackgroundColor: light ? AlmostWhite : AlmostDark,
  );
}
