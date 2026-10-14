import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../core/services/api_exception.dart';
import '../models/prayer_request.dart';

class PrayerRequestProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<PrayerRequest> _requests = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;

  PrayerRequestProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  List<PrayerRequest> get requests => _requests;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalCount => _totalCount;

  Future<void> loadPrayerRequests({int page = 1, bool refresh = false}) async {
    if (refresh) {
      page = 1;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiService.fetchPrayerRequests(page: page);
      if (page == 1) {
        _requests = res.requests;
      } else {
        _requests.addAll(res.requests);
      }
      _currentPage = res.currentPage;
      _totalPages = res.totalPages;
      _totalCount = res.totalCount;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      debugPrint('PrayerRequestProvider.loadPrayerRequests API error: ${e.message}');
    } catch (e) {
      _errorMessage = 'Could not load prayer requests. Please try again.';
      debugPrint('PrayerRequestProvider.loadPrayerRequests error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPrayerRequest({
    required String name,
    required String mobile,
    required String description,
    required String location,
    String? voiceNoteUrl,
  }) async {
    final trimmedLoc = location.trim();
    if (trimmedLoc.isEmpty) {
      _errorMessage = 'Please enter your location';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _apiService.createPrayerRequest(
        name: name,
        mobile: mobile,
        description: description,
        location: trimmedLoc,
        voiceNoteUrl: voiceNoteUrl,
      );

      if (created != null) {
        _requests.insert(0, created);
        _totalCount++;
        _isSubmitting = false;
        notifyListeners();
        print('>>> [PrayerRequestProvider]: Successfully submitted prayer request #${created.id}');
        return true;
      } else {
        _errorMessage = 'Failed to submit prayer request. Please check details.';
        print('>>> [PrayerRequestProvider]: createPrayerRequest returned null');
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      print('>>> [PrayerRequestProvider API Error]: ${e.message} (status: ${e.statusCode})');
      debugPrint('PrayerRequestProvider.createPrayerRequest API error: ${e.message}');
    } catch (e) {
      _errorMessage = 'Error submitting request. Please try again.';
      print('>>> [PrayerRequestProvider Unexpected Error]: $e');
      debugPrint('PrayerRequestProvider.createPrayerRequest error: $e');
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> deletePrayerRequest(int id) async {
    _errorMessage = null;
    try {
      final success = await _apiService.deletePrayerRequest(id);
      if (success) {
        _requests.removeWhere((item) => item.id == id);
        if (_totalCount > 0) _totalCount--;
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      debugPrint('PrayerRequestProvider.deletePrayerRequest API error: ${e.message}');
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete prayer request. Please try again.';
      debugPrint('PrayerRequestProvider.deletePrayerRequest error: $e');
      notifyListeners();
    }
    return false;
  }
}
