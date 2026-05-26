import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/root_navigator_key.dart';
import '../services/pending_notification_navigation.dart';

/// Cuando la base es `/home` o `/comercializacion`, hace [GoRouter.go] al deep link en frío
/// tras un par de frames (evita solaparse con el parseo del [Router]).
class ScheduleColdStartDeepLink extends StatefulWidget {
  const ScheduleColdStartDeepLink({super.key, required this.child});

  final Widget child;

  @override
  State<ScheduleColdStartDeepLink> createState() =>
      _ScheduleColdStartDeepLinkState();
}

class _ScheduleColdStartDeepLinkState extends State<ScheduleColdStartDeepLink> {
  @override
  void initState() {
    super.initState();
    if (PendingNotificationNavigation.instance.peekPendingDeepLink == null) {
      return;
    }
    // Dos frames: el primero deja terminar go/redirect tras splash o `/location`;
    // el segundo evita solapar el parseo async del Router con `push` (assert match.dart).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = rootNavigatorKey.currentContext;
        if (ctx == null || !ctx.mounted) return;
        final router = GoRouter.of(ctx);
        PendingNotificationNavigation.instance.tryConsumeAndPushColdStart(router);
      });
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
