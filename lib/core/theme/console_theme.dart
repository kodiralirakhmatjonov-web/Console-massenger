import 'package:flutter/cupertino.dart';

abstract final class ConsoleColors {
  static const background = Color(0xFF020403);
  static const panel = Color(0xFF080B09);
  static const panelRaised = Color(0xFF0D110E);
  static const border = Color(0xFF1C251E);
  static const accent = Color(0xFF7CFF8D);
  static const accentMuted = Color(0xFF2D6E38);
  static const text = Color(0xFFF3F5F3);
  static const secondary = Color(0xFF8D968F);
  static const tertiary = Color(0xFF566059);
  static const danger = Color(0xFFFF605C);
  static const warning = Color(0xFFFFD55A);
}

abstract final class ConsoleTheme {
  static CupertinoThemeData get data => const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: ConsoleColors.accent,
        scaffoldBackgroundColor: ConsoleColors.background,
        barBackgroundColor: ConsoleColors.background,
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(
            color: ConsoleColors.text,
            fontFamily: 'Courier',
            fontSize: 15,
          ),
          navTitleTextStyle: TextStyle(
            color: ConsoleColors.text,
            fontFamily: 'Courier',
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      );
}
