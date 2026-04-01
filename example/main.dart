import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:apibill_tracker/apibill_tracker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize the tracker
  ApiBillTracker.init(
    siteId: 'YOUR_SITE_ID',
    apiUrl: 'https://your-api.com/api',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. Add the interceptor to your Dio instance
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.interceptors.add(ApiBillInterceptor());

    // Now all HTTP calls through this Dio instance are tracked automatically
    // Including image downloads, API calls, file downloads, etc.

    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              // This request's bandwidth will be tracked automatically
              await dio.get('/products');

              // Image download — also tracked
              await dio.get(
                'https://bebrainer-app.sgp1.digitaloceanspaces.com/courses/image.jpg',
                options: Options(responseType: ResponseType.bytes),
              );
            },
            child: const Text('Make API Call'),
          ),
        ),
      ),
    );
  }
}
