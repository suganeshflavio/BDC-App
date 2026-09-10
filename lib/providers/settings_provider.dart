import 'package:flutter/material.dart';
import '../core/services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  static const List<double> availableFontSizes = [15, 16, 18, 20, 24, 28];

  double _fontSize = 18.0;

  double get fontSize => _fontSize;

  SettingsProvider() {
    _fontSize = StorageService.getFontSize();
  }

  Future<void> setFontSize(double size) async {
    if (_fontSize != size) {
      _fontSize = size;
      notifyListeners();
      await StorageService.saveFontSize(size);
    }
  }
}
