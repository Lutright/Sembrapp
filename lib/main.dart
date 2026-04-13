import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/router/app_router.dart';
import 'core/services/push_notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  if (!kIsWeb && firebaseOptionsConfigured) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await Firebase.initializeApp(options: firebaseOptionsForPlatform());
    // Incluye getInitialMessage() + stash en [PendingNotificationNavigation]
    // antes de runApp (equivalente a capturar el mensaje en main()).
    await PushNotificationService.instance.initialize();
  }

  // Siempre `/` (override platform): splash hace go a la base; [ScheduleColdStartDeepLink] go al detalle.
  initAppRouter(initialLocation: '/');
  runApp(const SembrappApp());
}
