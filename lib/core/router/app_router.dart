import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
import '../../features/comercializacion/screens/comercializacion_home_screen.dart';
import '../../features/comercializacion/screens/comercializacion_mis_productos_screen.dart';
import '../../features/comercializacion/screens/red_comunitaria_screen.dart';
import '../../features/comercializacion/screens/comercializacion_ordenes_screen.dart';
import '../../features/comercializacion/screens/comercializacion_productos_screen.dart';
import '../../features/comercializacion/models/producto.dart';
import '../../features/comercializacion/screens/orden_detalle_screen.dart';
import '../../features/comercializacion/screens/producto_detalle_screen.dart';
import '../../features/comercializacion/screens/producto_form_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/splash/splash_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isAuthRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register' ||
        state.matchedLocation == '/forgot-password' ||
        state.matchedLocation == '/';

    if (session == null && !isAuthRoute) return '/login';
    final role = session?.user.userMetadata?['role'] as String?;
    if (session != null && isAuthRoute && state.matchedLocation == '/') {
      return role == 'comprador' ? '/comercializacion' : '/home';
    }
    // Comprador no ve Home: va directo al marketplace
    if (session != null && state.matchedLocation == '/home' && role == 'comprador') {
      return '/comercializacion';
    }
    // Alfabetización solo para campesinos
    if (session != null &&
        state.matchedLocation.startsWith('/alfabetizacion') &&
        role == 'comprador') {
      return '/comercializacion';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const SplashScreen(),
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
      builder: (_, __) => const AlfabetizacionNivelesScreen(modulo: 'lectura'),
    ),
    GoRoute(
      path: '/alfabetizacion/escritura',
      builder: (_, __) => const AlfabetizacionNivelesScreen(modulo: 'escritura'),
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
        return AlfabetizacionLeccionesListScreen(modulo: 'escritura', nivel: n);
      },
    ),
    GoRoute(
      path: '/alfabetizacion/leccion/:id',
      builder: (_, state) {
        final id = state.pathParameters['id'] ?? '';
        return AlfabetizacionLeccionScreen(leccionId: id);
      },
    ),
    GoRoute(
      path: '/comercializacion',
      builder: (_, __) => const ComercializacionEntryScreen(),
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
      path: '/comercializacion/ordenes',
      builder: (_, __) => const ComercializacionOrdenesScreen(),
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
      path: '/comercializacion/producto/:id',
      builder: (_, state) {
        final id = state.pathParameters['id'] ?? '';
        final extra = state.extra;
        return ProductoDetalleScreen(
          producto: extra is Producto ? extra : null,
          productoId: id,
        );
      },
    ),
    GoRoute(
      path: '/comercializacion/orden/:id',
      builder: (_, state) {
        final id = state.pathParameters['id'] ?? '';
        return OrdenDetalleScreen(ordenId: id);
      },
    ),
  ],
);
