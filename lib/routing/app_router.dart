import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../features/auth/presentation/pages/auth_gate.dart';

class AppRouter {
  static const initialRoute = '/splash';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/splash':
        return _fade(const SplashScreen(next: AuthGate()));
      case '/auth':
        return _fade(const AuthGate());
      default:
        return _fade(const AuthGate());
    }
  }

  static PageRouteBuilder _fade(Widget page) => PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      );
}
