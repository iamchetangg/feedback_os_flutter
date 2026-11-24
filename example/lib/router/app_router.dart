import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../main.dart';
import 'route_names.dart';

/// Root navigator key, shared with FeedbackOS so the in-app notification
/// banner can be shown and can open threads.
final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: RouteNames.home,
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);
