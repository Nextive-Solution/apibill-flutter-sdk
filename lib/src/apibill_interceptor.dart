import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'apibill_tracker.dart';

/// Dio interceptor that automatically tracks bandwidth for all HTTP responses.
///
/// Add this to your Dio instance:
/// ```dart
/// final dio = Dio();
/// dio.interceptors.add(ApiBillInterceptor());
/// ```
class ApiBillInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    int bytes = 0;

    // Try content-length header first
    final contentLength = response.headers.value('content-length');
    if (contentLength != null) {
      bytes = int.tryParse(contentLength) ?? 0;
    }

    // Fallback: measure response data size
    if (bytes <= 0 && response.data != null) {
      final data = response.data;
      if (data is String) {
        bytes = data.length;
      } else if (data is List<int>) {
        bytes = data.length;
      } else if (data is Uint8List) {
        bytes = data.length;
      } else if (data is Map || data is List) {
        // JSON response — estimate from string representation
        bytes = data.toString().length;
      }
    }

    if (bytes > 0) {
      ApiBillTracker.instance.trackBytes(bytes);
    }

    handler.next(response);
  }
}
