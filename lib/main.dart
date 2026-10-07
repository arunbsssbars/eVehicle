import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/storage/local_database.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch uncaught Flutter framework errors (prevents silent blank pages on web)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      // ignore: avoid_print
      print('[FlutterError] ${details.exceptionAsString()}\n${details.stack}');
    }
  };

  // Catch async/zone errors on web
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[PlatformError] $error\n$stack');
    }
    return true; // handled
  };

  try {
    await LocalDatabase.instance.init();
  } catch (e, stack) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[DB Init Error] $e\n$stack');
    }
  }

  runApp(
    const ProviderScope(
      child: EVehicleLogBookApp(),
    ),
  );
}
