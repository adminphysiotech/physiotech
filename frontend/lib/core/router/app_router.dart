import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/views/sign_in_page.dart';
import '../../features/auth/presentation/views/sign_up_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class SignInRoute {
  static const String path = '/signin';
  static const String name = 'signin';
}

class SignUpRoute {
  static const String path = '/signup';
  static const String name = 'signup';
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: SignInRoute.path,
    routes: [
      GoRoute(
        path: SignInRoute.path,
        name: SignInRoute.name,
        builder: (context, _) => const SignInPage(),
      ),
      GoRoute(
        path: SignUpRoute.path,
        name: SignUpRoute.name,
        builder: (context, _) => const SignUpPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
