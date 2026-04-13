import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/pending_notification_navigation.dart';
import 'root_navigator_key.dart';

import '../../features/alfabetizacion/screens/alfabetizacion_home_screen.dart';
import '../../features/alfabetizacion/screens/alfabetizacion_leccion_screen.dart';
import '../../features/alfabetizacion/screens/alfabetizacion_lecciones_list_screen.dart';
import '../../features/alfabetizacion/screens/alfabetizacion_niveles_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/comercializacion/screens/beneficios_screen.dart';
import '../../features/comercializacion/screens/comercializacion_entry_screen.dart';
import '../../features/comercializacion/screens/indicadores_economicos_screen.dart';
import '../../features/comercializacion/screens/comercializacion_mis_productos_screen.dart';
import '../../features/comercializacion/screens/ayuda_chat_screen.dart';
import '../../features/comercializacion/screens/red_comunitaria_screen.dart';
import '../../features/comercializacion/screens/comercializacion_ordenes_screen.dart';
import '../../features/comercializacion/screens/comercializacion_productos_screen.dart';
import '../../features/comercializacion/models/producto.dart';
import '../../features/comercializacion/screens/orden_detalle_screen.dart';
import '../../features/comercializacion/screens/producto_detalle_screen.dart';
import '../../features/comercializacion/screens/producto_form_screen.dart';
import '../../features/comercializacion/screens/tienda_campesino_screen.dart';
import '../../features/comercializacion/navigation/producto_detalle_extra.dart';
import '../../features/comercializacion/navigation/tienda_campesino_extra.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/location/location_gate_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/splash/splash_screen.dart';

/// Singleton de navegación; se usa como `refreshListenable` del router.
final _nav = PendingNotificationNavigation.instance;

/// Rutas abiertas desde FCM: no deben pasar por el chequeo de ubicación.
bool _isPushNotificationDeepLink(String path) {
  final p = path.toLowerCase();
  return p.startsWith('/comercializacion/orden/') ||
      p.startsWith('/comercializacion/ayuda-chat/');
}

GoRouter? _appRouterRef;

GoRouter get appRouter {
  final r = _appRouterRef;
  if (r == null) {
    throw StateError(
      'Sembrapp: llama initAppRouter() desde main() antes de runApp().',
    );
  }
  return r;
}

/// Construye el [GoRouter] una sola vez. [initialLocation] `'/'`. Deep link en frío: stash +
/// [ScheduleColdStartDeepLink] hace [go] al detalle (evita assert match.dart).
void initAppRouter({required String initialLocation}) {
  if (_appRouterRef != null) return;
  _appRouterRef = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    // Android puede reportar otra ruta inicial al abrir desde notificación; forzar `/`.
    overridePlatformDefaultLocation: true,
    // refreshListenable: splash y ubicación notifican aquí para re-evaluar redirect.
    refreshListenable: _nav,
    // ── redirect 100 % SÍNCRONO: evita la carrera async que dispara el assert ──
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final loc = state.matchedLocation;
      final isSplash = loc == '/';
      final isAuthRoute =
          loc == '/login' || loc == '/register' || loc == '/forgot-password';
      final isLocationRoute = loc == '/location';

      // ── 1. Splash: mantener hasta que la animación termine ──
      if (isSplash && !_nav.splashDone) return null;

      // Los pushes en caliente usan [PushNavigator.openFromPushData] (push), no redirect.

      // ── 2. Splash terminó: respaldo si la URL sigue en `/` (p. ej. deep link manual).
      // Salida normal: [SplashScreen] hace go; deep link en frío: [ScheduleColdStartDeepLink].
      if (isSplash && _nav.splashDone) {
        if (session == null) return '/login';
        final role = session.user.userMetadata?['role'] as String?;
        return role == 'comprador' ? '/comercializacion' : '/home';
      }

      // ── 3. Sesión y ubicación ──
      if (session == null && !isAuthRoute && !isSplash) return '/login';

      // Chequeo de ubicación (síncrono gracias al cache en splashDone / LocationService).
      if (session != null &&
          !isAuthRoute &&
          !isSplash &&
          !isLocationRoute &&
          !_isPushNotificationDeepLink(loc)) {
        // Usar el valor cacheado que el SplashScreen calculó en _redirect().
        final locReady = _nav.locationReady;
        if (locReady == false) return '/location';
      }

      final role = session?.user.userMetadata?['role'] as String?;
      // Comprador no ve Home: va directo al marketplace
      if (session != null && loc == '/home' && role == 'comprador') {
        return '/comercializacion';
      }
      // Alfabetización solo para campesinos
      if (session != null &&
          loc.startsWith('/alfabetizacion') &&
          role == 'comprador') {
        return '/comercializacion';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/location',
        builder: (_, __) => const LocationGateScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/alfabetizacion',
        builder: (_, __) => const AlfabetizacionHomeScreen(),
      ),
      GoRoute(
        path: '/alfabetizacion/lectura',
        builder: (_, __) =>
            const AlfabetizacionNivelesScreen(modulo: 'lectura'),
      ),
      GoRoute(
        path: '/alfabetizacion/escritura',
        builder: (_, __) =>
            const AlfabetizacionNivelesScreen(modulo: 'escritura'),
      ),
      GoRoute(
        path: '/alfabetizacion/lectura/nivel/:nivel',
        builder: (_, state) {
          final n = int.tryParse(state.pathParameters['nivel'] ?? '1') ?? 1;
          return AlfabetizacionLeccionesListScreen(modulo: 'lectura', nivel: n);
        },
      ),
      GoRoute(
        path: '/alfabetizacion/escritura/nivel/:nivel',
        builder: (_, state) {
          final n = int.tryParse(state.pathParameters['nivel'] ?? '1') ?? 1;
          return AlfabetizacionLeccionesListScreen(
              modulo: 'escritura', nivel: n);
        },
      ),
      GoRoute(
        path: '/alfabetizacion/leccion/:id',
        builder: (_, state) {
          final id = state.pathParameters['id'] ?? '';
          return AlfabetizacionLeccionScreen(leccionId: id);
        },
      ),
      // Rutas planas con path absoluto; `/comercializacion/ordenes` antes que `.../orden/:id`.
      GoRoute(
        path: '/comercializacion/ordenes',
        builder: (_, __) => const ComercializacionOrdenesScreen(),
      ),
      GoRoute(
        path: '/comercializacion/orden/:id',
        caseSensitive: false,
        builder: (_, state) {
          final id = state.pathParameters['id'] ?? '';
          return OrdenDetalleScreen(ordenId: id);
        },
      ),
      GoRoute(
        path: '/comercializacion/ayuda-chat/:solicitudId',
        caseSensitive: false,
        builder: (_, state) {
          final id = state.pathParameters['solicitudId'] ?? '';
          return AyudaChatScreen(solicitudId: id);
        },
      ),
      GoRoute(
        path: '/comercializacion/red-comunitaria',
        builder: (_, __) => const RedComunitariaScreen(),
      ),
      GoRoute(
        path: '/comercializacion/beneficios',
        builder: (_, __) => const BeneficiosScreen(),
      ),
      GoRoute(
        path: '/comercializacion/indicadores',
        builder: (_, __) => const IndicadoresEconomicosScreen(),
      ),
      GoRoute(
        path: '/comercializacion/productos',
        builder: (_, __) => const ComercializacionProductosScreen(),
      ),
      GoRoute(
        path: '/comercializacion/mis-productos',
        builder: (_, __) => const ComercializacionMisProductosScreen(),
      ),
      GoRoute(
        path: '/comercializacion/producto/nuevo',
        builder: (_, __) => const ProductoFormScreen(),
      ),
      GoRoute(
        path: '/comercializacion/producto/editar/:id',
        builder: (_, state) {
          final p = state.extra;
          return ProductoFormScreen(
            producto: p is Producto ? p : null,
          );
        },
      ),
      GoRoute(
        path: '/comercializacion/tienda/:campesinoId',
        builder: (_, state) {
          final id = state.pathParameters['campesinoId'] ?? '';
          final extra = state.extra;
          String? nombre;
          Producto? productoIni;
          var cantIni = 1.0;
          var destacado = false;
          if (extra is TiendaCampesinoExtra) {
            nombre = extra.nombreTienda;
            productoIni = extra.productoInicial;
            cantIni = extra.cantidadInicial;
            destacado = extra.isDestacado;
          } else if (extra is String) {
            nombre = extra;
          }
          return TiendaCampesinoScreen(
            campesinoId: id,
            nombreTienda: nombre,
            productoInicial: productoIni,
            cantidadInicial: cantIni,
            isDestacado: destacado,
          );
        },
      ),
      GoRoute(
        path: '/comercializacion/producto/:id',
        builder: (_, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra;
          if (extra is ProductoDetalleExtra) {
            return ProductoDetalleScreen(
              producto: extra.producto,
              productoId: id,
              onAgregarAlPedido: extra.onAgregarAlPedido,
            );
          }
          return ProductoDetalleScreen(
            producto: extra is Producto ? extra : null,
            productoId: id,
          );
        },
      ),
      GoRoute(
        path: '/comercializacion',
        builder: (_, __) => const ComercializacionEntryScreen(),
      ),
      // `/` al final: el matcher prueba rutas en orden; el splash no debe sombrear rutas largas.
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashScreen(),
      ),
    ],
  );
}
