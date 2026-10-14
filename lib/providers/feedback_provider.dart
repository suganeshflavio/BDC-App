import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../core/services/api_exception.dart';
import '../core/services/storage_service.dart';
import '../models/feedback_question.dart';

class FeedbackProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<FeedbackQuestion> _questions = [];
  final Map<int, String> _answers = {};
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _submitSuccess = false;

  FeedbackProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  List<FeedbackQuestion> get questions => _questions;
  Map<int, String> get answers => _answers;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get submitSuccess => _submitSuccess;

  void setAnswer(int questionId, String text) {
    _answers[questionId] = text;
    notifyListeners();
  }

  Future<void> loadQuestions({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    _submitSuccess = false;
    notifyListeners();

    try {
      _questions = await _apiService.fetchFeedbackQuestions();
      // Populate pre-existing answers
      for (final q in _questions) {
        if (q.answerText != null && q.answerText!.trim().isNotEmpty) {
          _answers[q.id] = q.answerText!;
        }
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      debugPrint('FeedbackProvider.loadQuestions API error: ${e.message}');
    } catch (e) {
      _errorMessage = 'Could not load feedback questions. Please try again.';
      debugPrint('FeedbackProvider.loadQuestions error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitFeedback({required String name}) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _errorMessage = 'தயவுசெய்து உங்கள் பெயரை உள்ளிடவும் (Please enter your name before submitting feedback)';
      notifyListeners();
      return false;
    }

    final payload = <Map<String, dynamic>>[];
    for (final entry in _answers.entries) {
      final text = entry.value.trim();
      if (text.isNotEmpty) {
        payload.add({
          'question_id': entry.key,
          'answer_text': text,
        });
      }
    }

    if (payload.isEmpty) {
      _errorMessage = 'தயவுசெய்து ஏதேனும் ஒரு கேள்விக்கு பதிலளிக்கவும் (Please provide an answer before submitting).';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _apiService.submitFeedbackAnswers(payload, name: trimmedName);
      if (success) {
        await StorageService.saveUserName(trimmedName);
        _submitSuccess = true;
        _isSubmitting = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to submit feedback. Please check details.';
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      debugPrint('FeedbackProvider.submitFeedback API error: ${e.message}');
    } catch (e) {
      _errorMessage = 'An error occurred while submitting feedback. Please try again.';
      debugPrint('FeedbackProvider.submitFeedback error: $e');
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }

    return false;
  }
}
