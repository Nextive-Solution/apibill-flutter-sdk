import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'apibill_tracker.dart';

/// Dio interceptor that tracks bandwidth for external/CDN responses only.
///
/// Skips requests to your API domain (Nginx already logs those).
/// Only tracks bandwidth from external sources like DO Spaces, CDNs, etc.
///
/// ```dart
/// // For your API client — skips tracking (Nginx handles it)
/// final apiDio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
/// apiDio.interceptors.add(ApiBillInterceptor());
///
/// // For CDN/external requests — tracks bandwidth
/// final cdnDio = Dio();
/// cdnDio.interceptors.add(ApiBillInterceptor());
/// ```
class ApiBillInterceptor extends Interceptor {
  /// Hosts to exclude from tracking (e.g., your API domain).
  /// These are already measured by Nginx logs.
  /// Automatically includes the host from [ApiBillTracker.apiUrl].
  final Set<String> _excludedHosts;

  /// Create an interceptor that skips the API host automatically.
  /// Pass additional [excludeHosts] if needed.
  ApiBillInterceptor({List<String> excludeHosts = const []})
      : _excludedHosts = {
          ...excludeHosts.map((h) => h.toLowerCase()),
        };

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final requestUrl = response.requestOptions.uri;
    final host = requestUrl.host.toLowerCase();

    // Build excluded hosts lazily (includes API host)
    final apiHost = _getApiHost();
    if (apiHost != null && host == apiHost) {
      handler.next(response);
      return;
    }

    if (_excludedHosts.contains(host)) {
      handler.next(response);
      return;
    }

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
        bytes = data.toString().length;
      }
    }

    if (bytes > 0) {
      ApiBillTracker.instance.trackBytes(bytes);
    }

    handler.next(response);
  }

  String? _getApiHost() {
    try {
      return Uri.parse(ApiBillTracker.instance.apiUrl).host.toLowerCase();
    } catch (_) {
      return null;
    }
  }
}
