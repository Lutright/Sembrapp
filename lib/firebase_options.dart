// Opciones de Firebase para FCM.
// Los defaultValue de Android coinciden con android/app/google-services.json para que
// `flutter build apk` registre push sin --dart-define. En CI puedes sobrescribir con dart-define.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// `true` si hay valores mínimos para la plataforma actual (vía dart-define).
bool get firebaseOptionsConfigured {
  if (kIsWeb) return false;
  final o = _forPlatform();
  if (o.projectId.isEmpty || o.apiKey.isEmpty || o.appId.isEmpty) {
    return false;
  }
  if (o.messagingSenderId.isEmpty) return false;
  if (defaultTargetPlatform == TargetPlatform.iOS &&
      (o.iosBundleId == null || o.iosBundleId!.isEmpty)) {
    return false;
  }
  return true;
}

FirebaseOptions firebaseOptionsForPlatform() => _forPlatform();

FirebaseOptions _forPlatform() {
  if (kIsWeb) {
    return web;
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return android;
    case TargetPlatform.iOS:
      return ios;
    default:
      return android;
  }
}

const FirebaseOptions android = FirebaseOptions(
  apiKey: String.fromEnvironment(
    'SEMBRAPP_FIREBASE_ANDROID_API_KEY',
    defaultValue: 'AIzaSyCmSun-L2zJcSGw6v8RMHv3KZPjUnnxCDc',
  ),
  appId: String.fromEnvironment(
    'SEMBRAPP_FIREBASE_ANDROID_APP_ID',
    defaultValue: '1:517275193091:android:2e672cf9a9186ef19ee336',
  ),
  messagingSenderId: String.fromEnvironment(
    'SEMBRAPP_FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '517275193091',
  ),
  projectId: String.fromEnvironment(
    'SEMBRAPP_FIREBASE_PROJECT_ID',
    defaultValue: 'sembrapp-1abd4',
  ),
  storageBucket: String.fromEnvironment(
    'SEMBRAPP_FIREBASE_STORAGE_BUCKET',
    defaultValue: 'sembrapp-1abd4.firebasestorage.app',
  ),
);

const FirebaseOptions ios = FirebaseOptions(
  apiKey: String.fromEnvironment(
    'SEMBRAPP_FIREBASE_IOS_API_KEY',
    defaultValue: '',
  ),
  appId: String.fromEnvironment(
    'SEMBRAPP_FIREBASE_IOS_APP_ID',
    defaultValue: '',
  ),
  messagingSenderId: String.fromEnvironment(
    'SEMBRAPP_FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '',
  ),
  projectId: String.fromEnvironment(
    'SEMBRAPP_FIREBASE_PROJECT_ID',
    defaultValue: '',
  ),
  storageBucket: String.fromEnvironment(
    'SEMBRAPP_FIREBASE_STORAGE_BUCKET',
    defaultValue: '',
  ),
  iosBundleId: String.fromEnvironment(
    'SEMBRAPP_IOS_BUNDLE_ID',
    defaultValue: '',
  ),
);

/// Web no usa FCM en este flujo (misma app puede ampliarse con VAPID después).
const FirebaseOptions web = FirebaseOptions(
  apiKey: '',
  appId: '',
  messagingSenderId: '',
  projectId: '',
);
