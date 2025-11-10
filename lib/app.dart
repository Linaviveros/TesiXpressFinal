// lib/app.dart
import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'routing/app_router.dart';

class TesiXpressApp extends StatelessWidget {
  const TesiXpressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TesiXpress',

      // ⬇️ Temas congruentes con login/chat/splash
      theme: buildLightTheme(),     // beige + alto contraste
      darkTheme: buildDarkTheme(),  // oscuro futurista
      themeMode: ThemeMode.system,  // usa el tema del sistema (cámbialo a .light o .dark si quieres forzar)

      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.initialRoute,
    );
  }
}
