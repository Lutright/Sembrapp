import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'push_navigator.dart';

/// Estado para splash, ubicación y **solo** el deep link de arranque en frío (stash).
/// Tras el splash, [SplashScreen] hace `go` a la base; el redirect ajusta login/ubicación.
/// [tryConsumeAndPushColdStart] hace [GoRouter.go] al deep link en frío (evita assert match.dart).
///
/// [ChangeNotifier] en `refreshListenable` del [GoRouter] (reservado; splash ya no notifica aquí).
/// Las notificaciones con la app en memoria usan [PushNavigator].
final class PendingNotificationNavigation extends ChangeNotifier {
  PendingNotificationNavigation._();
  static final PendingNotificationNavigation instance =
      PendingNotificationNavigation._();

  String? _coldStartPath;
  bool _coldStartPushHandled = false;

  /// Indica que el splash completó su animación y el redirect puede redirigir.
  bool splashDone = false;

  /// Marca el splash como completado **sin** [notifyListeners].
  ///
  /// La salida del splash es un [GoRouter.go] explícito desde [SplashScreen]; disparar
  /// [refreshListenable] aquí hacía que el [Router] re-parseara `RouteInformation` en
  /// paralelo con esa navegación y acababa en el assert `match.dart:235`.
  void markSplashDone() {
    if (splashDone) return;
    splashDone = true;
  }

  /// Indica si la ubicación ya fue verificada para la sesión actual.
  bool? _locationReady;
  bool? get locationReady => _locationReady;
  set locationReady(bool? v) {
    _locationReady = v;
  }

  /// Llamar desde [LocationGateScreen] cuando el usuario ya concedió ubicación y hay
  /// posición; si no, el redirect sigue viendo `locationReady == false` y devuelve a `/location`.
  ///
  /// No llama a [notifyListeners]: [refreshListenable] haría que el [Router] vuelva a
  /// parsear [RouteInformationProvider.value] en paralelo con el `context.go` que sigue
  /// en pantalla, y el `push` del arranque en frío puede coincidir con ese parseo → assert
  /// `match.dart` (`uri.path.startsWith(newMatchedLocation)`). El `go` ya dispara redirect.
  void markLocationGranted() {
    if (_locationReady == true) return;
    _locationReady = true;
  }

  /// Arranque en frío: guarda ruta destino (después de [PushNotificationService.initialize]).
  void stashFromNotificationData(Map<String, dynamic> data) {
    final path = PushNavigator.pathFromPushData(data);
    if (path != null) {
      _coldStartPath = path;
    }
  }

  String? get peekPendingDeepLink =>
      _coldStartPath == null ? null : PushNavigator.canonicalPath(_coldStartPath!);

  String? consumePendingDeepLink() {
    final link = _coldStartPath;
    _coldStartPath = null;
    return link == null ? null : PushNavigator.canonicalPath(link);
  }

  /// Si hay stash y la ubicación actual es la base post-splash, hace [GoRouter.go] una vez.
  ///
  /// [GoRouter.push] sobre la base + `refreshListenable` provocaba asserts en `match.dart`
  /// en arranque en frío (re-parse vs pila imperativa).
  void tryConsumeAndPushColdStart(GoRouter router) {
    if (_coldStartPushHandled) return;
    if (peekPendingDeepLink == null) return;
    if (_locationReady == false) return;
    final loc = router.state.matchedLocation;
    if (loc != '/home' && loc != '/comercializacion') return;
    final path = consumePendingDeepLink();
    if (path == null) return;
    _coldStartPushHandled = true;
    router.go(path);
  }

  void clear() {
    _coldStartPath = null;
    splashDone = false;
    _locationReady = null;
    _coldStartPushHandled = false;
  }

  /// Tap en notificación con la app en memoria: [GoRouter.push] (no redirect).
  void requestNavigationFromNotificationData(Map<String, dynamic> data) {
    PushNavigator.openFromPushData(data);
  }
}
