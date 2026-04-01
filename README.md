# ApiBill Tracker - Flutter SDK

Lightweight bandwidth tracking SDK for [ApiBill](https://github.com/Nextive-Solution/apibill). Tracks all HTTP traffic from your Flutter app and reports to the ApiBill API for usage-based billing.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  apibill_tracker:
    git:
      url: https://github.com/Nextive-Solution/apibill-flutter-sdk.git
```

Then run:

```bash
flutter pub get
```

## Setup

### 1. Initialize the tracker

In your `main.dart`:

```dart
import 'package:apibill_tracker/apibill_tracker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  ApiBillTracker.init(
    siteId: 'YOUR_SITE_ID',                 // Get this from ApiBill admin panel
    apiUrl: 'https://your-api.com/api',      // Your ApiBill API URL
  );

  runApp(MyApp());
}
```

### 2. Add the interceptor to Dio

```dart
import 'package:dio/dio.dart';
import 'package:apibill_tracker/apibill_tracker.dart';

final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
dio.interceptors.add(ApiBillInterceptor());
```

That's it. All HTTP responses through this Dio instance are now tracked automatically.

## How it works

- The `ApiBillInterceptor` captures the byte size of every HTTP response (API calls, image downloads, file downloads - from any domain)
- Bytes accumulate in memory and are sent to the ApiBill API in batches every 2 minutes
- When the app goes to background or is closed, pending bytes are flushed immediately
- Failed reports are retried on the next flush cycle
- The tracker sends data to `POST /api/tracker/bandwidth` with `{ siteId, bytes }`

## Configuration

```dart
ApiBillTracker.init(
  siteId: 'YOUR_SITE_ID',
  apiUrl: 'https://your-api.com/api',
  flushInterval: Duration(minutes: 5),  // Default: 2 minutes
);
```

## Multiple Dio instances

If your app uses multiple Dio instances (e.g., one for API, one for file downloads), add the interceptor to each:

```dart
final apiClient = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
apiClient.interceptors.add(ApiBillInterceptor());

final cdnClient = Dio();
cdnClient.interceptors.add(ApiBillInterceptor());
```

## Manual tracking

If you use the `http` package or other HTTP clients instead of Dio, you can track bytes manually:

```dart
import 'package:http/http.dart' as http;
import 'package:apibill_tracker/apibill_tracker.dart';

final response = await http.get(Uri.parse('https://example.com/image.jpg'));
ApiBillTracker.instance.trackBytes(response.bodyBytes.length);
```

## Getting your Site ID

1. Log in to the ApiBill admin panel
2. Go to **Sites** and click on your site
3. Copy the Site ID from the **Flutter SDK** section

## Requirements

- Flutter >= 3.10.0
- Dart >= 3.0.0
- [dio](https://pub.dev/packages/dio) >= 5.0.0
