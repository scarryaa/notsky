import 'package:flutter/material.dart';

class BottomNavVisibilityController extends ChangeNotifier {
  bool _isVisible = true;

  bool get isVisible => _isVisible;

  void hide() {
    _isVisible = false;
    notifyListeners();
  }

  void show() {
    _isVisible = true;
    notifyListeners();
  }
}
