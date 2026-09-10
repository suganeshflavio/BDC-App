import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../models/song.dart';

class FavoriteProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Song> _favorites = [];
  bool _isLoading = false;

  FavoriteProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  List<Song> get favorites => _favorites;
  bool get isLoading => _isLoading;

  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      _favorites = await _apiService.fetchFavorites();
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeFavorite(Song song) async {
    _favorites.removeWhere((s) => s.id == song.id);
    notifyListeners();

    await _apiService.toggleFavorite(song.id, false);
  }

  Future<void> toggleFavorite(Song song) async {
    final exists = _favorites.any((s) => s.id == song.id);
    if (exists) {
      await removeFavorite(song);
    } else {
      song.isFavorite = true;
      _favorites.insert(0, song);
      notifyListeners();
      await _apiService.toggleFavorite(song.id, true);
    }
  }
}
