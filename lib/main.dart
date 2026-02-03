import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:food_flow_app/routes/route_constants.dart';
import 'package:food_flow_app/routes/route_generator.dart';
import 'package:food_flow_app/core/constants/env_config.dart';
import 'package:food_flow_app/core/constants/secure_config.dart';
import 'package:food_flow_app/core/services/database_service.dart';
import 'package:food_flow_app/core/services/repository_factory.dart';
import 'package:food_flow_app/core/services/push_notification_service.dart';
import 'package:food_flow_app/core/providers/theme_provider.dart';
import 'package:food_flow_app/core/widgets/keyboard_dismisser.dart';
import 'package:food_flow_app/core/di/dependency_injection.dart';
import 'package:food_flow_app/styles/styles.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await PushNotificationService.backgroundMessageHandler(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.initialize();
  await SecureConfig.initialize();
  
  // Initialize database
  final database = await DatabaseService.database;
  RepositoryFactory.initialize(database);
  
  // Initialize Dependency Injection (includes Firebase)
  await DependencyInjection.instance.initialize();
  
  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
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
            title: 'Food Flow App',
            debugShowCheckedModeBanner: false,
            theme: Styles.lightTheme,
            darkTheme: Styles.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: Routes.initial,
            onGenerateRoute: RouteGenerator.generateRoute,
            builder: (context, child) {
              return KeyboardDismisser(
                child: child ?? const SizedBox(),
              );
            },
          );
        },
      ),
    );
  }
}
