import 'package:flutter/material.dart';

class LanguageController {
  static Locale current = const Locale('en');

  static void switchLanguage(String langCode) {
    current = Locale(langCode);
  }
}
