// Copyright Terry Hancock 2023

import 'package:flutter/material.dart';

class TextStyleHandler with ChangeNotifier {
  static final TextStyleHandler _instance = TextStyleHandler._constructor();
  String font = '';
  double fontSize = 22;

  // String get font => _font;
  // double get fontSize => _fontSize;

  factory TextStyleHandler() {
    return _instance;
  }
  TextStyleHandler._constructor();

  void increaseFontSize() {
    fontSize++;
    notifyListeners();
  }

  void decreaseFontSize() {
    fontSize--;
    notifyListeners();
  }

  void changeFont(String newFont) {
    font = newFont;
    notifyListeners();
  }
}
