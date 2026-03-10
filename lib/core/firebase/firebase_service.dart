import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../constants/env_config.dart';
import '../constants/firebase_web_options_fallback.dart';

/// Firebase Service - Centralized Firebase initialization and access
class FirebaseService {
  FirebaseService._();
  
  static FirebaseApp? _app;
  static FirebaseAuth? _auth;
  static FirebaseFirestore? _firestore;
  static FirebaseStorage? _storage;
  static FirebaseMessaging? _messaging;
  static FirebaseAnalytics? _analytics;
  static FirebaseApp? _adminApp;
  static FirebaseAuth? _adminAuth;

  /// Initialize Firebase
  static Future<void> initialize() async {
    if (kIsWeb) {
      // Use .env if loaded (local), otherwise fallback so production deploy works
      final options = EnvConfig.firebaseWebOptions ?? FirebaseWebOptionsFallback.options;
      _app = await Firebase.initializeApp(options: options);
    } else {
      _app = await Firebase.initializeApp();
    }
    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
    _storage = FirebaseStorage.instance;
    _messaging = FirebaseMessaging.instance;
    _analytics = FirebaseAnalytics.instance;
  }

  /// Get Firebase Auth instance
  static FirebaseAuth get auth {
    if (_auth == null) {
      throw Exception('Firebase not initialized. Call FirebaseService.initialize() first.');
    }
    return _auth!;
  }

  /// Get a secondary Firebase Auth instance for admin-only operations
  /// (e.g. creating rider accounts) without affecting the current session.
  static Future<FirebaseAuth> get adminAuth async {
    // Ensure main app is initialized
    if (_app == null) {
      await initialize();
    }

    // On web, multiple auth instances are not needed/supported the same way,
    // so we just reuse the primary auth instance.
    if (kIsWeb) {
      return auth;
    }

    if (_adminAuth != null) {
      return _adminAuth!;
    }

    // Initialize a named secondary app sharing the same options
    _adminApp ??= await Firebase.initializeApp(
      name: 'admin_app',
      options: _app!.options,
    );

    _adminAuth = FirebaseAuth.instanceFor(app: _adminApp!);
    return _adminAuth!;
  }

  /// Get Firestore instance
  static FirebaseFirestore get firestore {
    if (_firestore == null) {
      throw Exception('Firebase not initialized. Call FirebaseService.initialize() first.');
    }
    return _firestore!;
  }

  /// Get Firebase Storage instance
  static FirebaseStorage get storage {
    if (_storage == null) {
      throw Exception('Firebase not initialized. Call FirebaseService.initialize() first.');
    }
    return _storage!;
  }

  /// Get Firebase Messaging instance
  static FirebaseMessaging get messaging {
    if (_messaging == null) {
      throw Exception('Firebase not initialized. Call FirebaseService.initialize() first.');
    }
    return _messaging!;
  }

  /// Get Firebase Analytics instance
  static FirebaseAnalytics get analytics {
    if (_analytics == null) {
      throw Exception('Firebase not initialized. Call FirebaseService.initialize() first.');
    }
    return _analytics!;
  }

  /// Get current user
  static User? get currentUser => _auth?.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;
}
