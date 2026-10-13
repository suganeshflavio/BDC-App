import 'dart:convert';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const ApiException(
    this.message, {
    this.statusCode,
    this.details,
  });

  @override
  String toString() => message;

  /// Parses error responses from the backend API:
  /// Handles { "error": "..." }, { "errors": [...] }, { "message": "..." },
  /// and standard HTTP status code fallbacks.
  factory ApiException.fromResponse(int statusCode, String responseBody) {
    String? parsedMessage;

    if (responseBody.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(responseBody);
        if (decoded is Map<String, dynamic>) {
          if (decoded['error'] is String && decoded['error'].toString().trim().isNotEmpty) {
            parsedMessage = decoded['error'].toString().trim();
          } else if (decoded['message'] is String && decoded['message'].toString().trim().isNotEmpty) {
            parsedMessage = decoded['message'].toString().trim();
          } else if (decoded['errors'] is List && (decoded['errors'] as List).isNotEmpty) {
            parsedMessage = (decoded['errors'] as List).map((e) => e.toString()).join('; ');
          } else if (decoded['errors'] is Map) {
            final errMap = decoded['errors'] as Map<String, dynamic>;
            parsedMessage = errMap.entries.map((e) => '${e.key}: ${e.value}').join('; ');
          }
        } else if (decoded is String && decoded.trim().isNotEmpty) {
          parsedMessage = decoded.trim();
        }
      } catch (_) {
        // If response is HTML or plain text error
        final cleanText = responseBody.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        if (cleanText.isNotEmpty && cleanText.length < 200) {
          parsedMessage = cleanText;
        }
      }
    }

    parsedMessage ??= _statusFallback(statusCode);

    return ApiException(
      parsedMessage,
      statusCode: statusCode,
    );
  }

  static String _statusFallback(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check the submitted information.';
      case 401:
        return 'Unauthorized. Authentication token is missing or expired.';
      case 403:
        return 'This account has been disabled.';
      case 404:
        return 'Requested item or resource was not found.';
      case 422:
        return 'Validation failed. Please verify all required fields.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
      case 503:
        return 'Service temporarily unavailable. Please try again in a moment.';
      default:
        return 'Request failed with status code $statusCode.';
    }
  }
}
