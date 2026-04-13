import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../router/root_navigator_key.dart';

/// Navegación desde FCM / notificación local: parseo estable y apertura con [GoRouter.push]
/// (mantiene la pila → el botón atrás funciona). No usar el `redirect` del router para esto.
abstract final class PushNavigator {
  /// Normaliza barras y **minúsculas en el path**.
  ///
  /// go_router genera RegExp case-insensitive para matchear, pero en v14 el assert
  /// `uri.path.startsWith(newMatchedLocation)` es case-sensitive: si FCM/Android
  /// envían `/Comercializacion/orden/...` y el patrón es `/comercializacion/...`,
  /// el match parcial pasa y luego falla match.dart:235. Los UUID en hex son
  /// equivalentes en minúsculas.
  static String canonicalPath(String location) {
    var s = location.trim();
    if (s.isEmpty) return '/';
    while (s.contains('//')) {
      s = s.replaceAll('//', '/');
    }
    if (s.length > 1 && s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    if (!s.startsWith('/')) {
      s = '/$s';
    }
    return s.toLowerCase();
  }

  static String? _cleanId(dynamic raw) {
    if (raw == null) return null;
    var s = raw.toString().trim();
    if (s.length >= 2 && s.startsWith('"') && s.endsWith('"')) {
      s = s.substring(1, s.length - 1).trim();
    }
    return s.isEmpty ? null : s;
  }

  /// Construye la ruta destino desde el mapa `data` de FCM o del JSON de la notificación local.
  static String? pathFromPushData(Map<String, dynamic> data) {
    final rawRoute = data['route']?.toString();
    final route = rawRoute?.trim().toLowerCase();
    if (route == 'orden_detail') {
      final id = _cleanId(
        data['orden_id'] ?? data['ordenId'],
      );
      if (id != null) {
        return canonicalPath('/comercializacion/orden/$id');
      }
    }
    if (route == 'ayuda_chat') {
      final sid = _cleanId(
        data['solicitud_id'] ?? data['solicitudId'],
      );
      if (sid != null) {
        return canonicalPath('/comercializacion/ayuda-chat/$sid');
      }
    }
    if (route == 'red_comunitaria') {
      return canonicalPath('/comercializacion/red-comunitaria');
    }
    return null;
  }

  /// App en primer plano o en memoria: abre la pantalla encima de la actual ([push]).
  static void openFromPushData(Map<String, dynamic> data) {
    final path = pathFromPushData(data);
    if (path == null) return;

    var frames = 0;
    void schedule() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = rootNavigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          GoRouter.of(ctx).push(path);
          return;
        }
        frames++;
        if (frames < 45) {
          schedule();
        }
      });
    }

    schedule();
  }
}
