import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../models/song.dart';

class SongProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Song> _songs = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _errorMessage;

  SongProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  List<Song> get songs => _songs;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;

  Future<void> loadSongs({String? query}) async {
    _isLoading = true;
    _searchQuery = query ?? '';
    _errorMessage = null;
    notifyListeners();

    try {
      _songs = await _apiService.fetchSongs(query: query);
    } catch (e) {
      _errorMessage = 'Failed to load songs: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Song?> getSongDetail(int id) async {
    try {
      return await _apiService.fetchSongDetail(id);
    } catch (e) {
      debugPrint('Error getting song detail: $e');
      return null;
    }
  }

  Future<void> toggleFavorite(Song song) async {
    final nextState = !song.isFavorite;
    song.isFavorite = nextState;
    notifyListeners();

    await _apiService.toggleFavorite(song.id, nextState);
  }

  void updateFavoriteStatus(int songId, bool isFav) {
    final idx = _songs.indexWhere((s) => s.id == songId);
    if (idx != -1) {
      _songs[idx].isFavorite = isFav;
      notifyListeners();
    }
  }
}
