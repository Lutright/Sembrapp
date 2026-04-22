import 'package:flutter/material.dart';

/// Clave raíz compartida por [GoRouter] y la navegación desde push (sin importar `app_router`).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
