import 'dart:async';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

class ApiBillTracker {
  static ApiBillTracker? _instance;

  final String siteId;
  final String apiUrl;
  final Duration flushInterval;

  int _pendingBytes = 0;
  String _currentPath = '/';
  Timer? _timer;
  late final Dio _dio;

  ApiBillTracker._({
    required this.siteId,
    required this.apiUrl,
    this.flushInterval = const Duration(minutes: 2),
  }) {
    _dio = Dio(BaseOptions(
      baseUrl: apiUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));
  }

  /// Initialize the tracker. Call once at app startup.
  ///
  /// ```dart
  /// void main() {
  ///   ApiBillTracker.init(
  ///     siteId: 'YOUR_SITE_ID',
  ///     apiUrl: 'https://your-api.com/api',
  ///   );
  ///   runApp(MyApp());
  /// }
  /// ```
  static ApiBillTracker init({
    required String siteId,
    required String apiUrl,
    Duration flushInterval = const Duration(minutes: 2),
  }) {
    _instance ??= ApiBillTracker._(
      siteId: siteId,
      apiUrl: apiUrl.endsWith('/') ? apiUrl.substring(0, apiUrl.length - 1) : apiUrl,
      flushInterval: flushInterval,
    );
    _instance!._startTimer();
    _instance!._observeAppLifecycle();
    return _instance!;
  }

  /// Get the singleton instance. Must call [init] first.
  static ApiBillTracker get instance {
    assert(_instance != null, 'Call ApiBillTracker.init() first');
    return _instance!;
  }

  /// Set the current route/path and track a page view.
  /// Call this on every route change.
  void trackPageView(String path) {
    _currentPath = path;
    _sendBeacon(0);
  }

  /// Record bytes from a network response.
  void trackBytes(int bytes) {
    if (bytes > 0) {
      _pendingBytes += bytes;
    }
  }

  /// Flush pending bytes to the API.
  Future<void> flush() async {
    if (_pendingBytes <= 0) return;

    final bytes = _pendingBytes;
    _pendingBytes = 0;

    try {
      await _sendBeacon(bytes);
    } catch (_) {
      _pendingBytes += bytes;
    }
  }

  Future<void> _sendBeacon(int bytes) async {
    final screenWidth = PlatformDispatcher.instance.views.first.physicalSize.width /
        PlatformDispatcher.instance.views.first.devicePixelRatio;

    await _dio.post(
      '/tracker/bandwidth',
      data: {
        'siteId': siteId,
        'bytes': bytes,
        'url': _currentPath,
        'referrer': '',
        'screenWidth': screenWidth.round(),
      },
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(flushInterval, (_) => flush());
  }

  void _observeAppLifecycle() {
    WidgetsBinding.instance.addObserver(_LifecycleObserver(this));
  }

  /// Stop the tracker and flush remaining bytes.
  Future<void> dispose() async {
    _timer?.cancel();
    await flush();
    _instance = null;
  }
}

class _LifecycleObserver extends WidgetsBindingObserver {
  final ApiBillTracker _tracker;

  _LifecycleObserver(this._tracker);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _tracker.flush();
    }
  }
}
