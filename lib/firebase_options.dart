import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Dummy Firebase config for Emulator-only setup
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "demo-key",
    appId: "1:1234567890:web:demo",
    messagingSenderId: "demo-sender",
    projectId: "demo-meeting",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "demo-key",
    appId: "1:1234567890:android:demo",
    messagingSenderId: "demo-sender",
    projectId: "demo-meeting",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "demo-key",
    appId: "1:1234567890:ios:demo",
    messagingSenderId: "demo-sender",
    projectId: "demo-meeting",
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: "demo-key",
    appId: "1:1234567890:macos:demo",
    messagingSenderId: "demo-sender",
    projectId: "demo-meeting",
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: "demo-key",
    appId: "1:1234567890:windows:demo",
    messagingSenderId: "demo-sender",
    projectId: "demo-meeting",
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: "demo-key",
    appId: "1:1234567890:linux:demo",
    messagingSenderId: "demo-sender",
    projectId: "demo-meeting",
  );
}
