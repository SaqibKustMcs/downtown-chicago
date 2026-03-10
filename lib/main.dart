import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/routes/route_generator.dart';
import 'package:downtown/core/constants/env_config.dart';
import 'package:downtown/core/constants/secure_config.dart';
import 'package:downtown/core/services/push_notification_service.dart';
import 'package:downtown/core/providers/theme_provider.dart';
import 'package:downtown/core/widgets/keyboard_dismisser.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/styles/styles.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await PushNotificationService.backgroundMessageHandler(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runZonedGuarded(
    () async {
      try {
        await EnvConfig.initialize();
        await SecureConfig.initialize();

        // Initialize Dependency Injection (includes Firebase)
        await DependencyInjection.instance.initialize();

        // Register background message handler
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

        runApp(const MyApp());
      } catch (e, stack) {
        debugPrint('App init error: $e');
        debugPrint(stack.toString());
        runApp(ErrorApp(error: e, stack: stack));
      }
    },
    (error, stack) {
      debugPrint('Zone error: $error');
      debugPrint(stack.toString());
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

/// Fallback app shown when initialization fails (e.g. on deployed web).
///
/// Displays the error and optional stack trace instead of a white screen.
class ErrorApp extends StatelessWidget {
  /// The error that occurred during init.
  final Object error;

  /// Optional stack trace for the error.
  final StackTrace? stack;

  /// Creates an [ErrorApp] with the given [error] and optional [stack].
  const ErrorApp({super.key, required this.error, this.stack});

  static String _errorMessage(Object error) {
    final s = error.toString();
    if (s.startsWith('Instance of')) {
      return '$s (${error.runtimeType})';
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(_errorMessage(error), style: const TextStyle(fontSize: 14)),
                if (stack != null) ...[
                  const SizedBox(height: 16),
                  const Text('Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text('$stack', style: const TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MyAppState extends State<MyApp> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Downtown Chicago ',
            debugShowCheckedModeBanner: false,
            theme: Styles.lightTheme,
            darkTheme: Styles.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: Routes.initial,
            onGenerateRoute: RouteGenerator.generateRoute,
            builder: (context, child) {
              return KeyboardDismisser(child: child ?? const SizedBox());
            },
          );
        },
      ),
    );
  }
}
