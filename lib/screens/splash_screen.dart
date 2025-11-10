import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class SplashScreen extends StatefulWidget {
  final Widget next;
  final int totalSeconds;

  const SplashScreen({super.key, required this.next, this.totalSeconds = 8});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _orbitCtrl;
  late Animation<double> _fade;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOutCubic);

    _orbitCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4200))..repeat();

    _timer = Timer(Duration(seconds: widget.totalSeconds), _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    _fadeCtrl.reverse().whenComplete(() {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => widget.next,
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeCtrl.dispose();
    _orbitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradiente minimalista beige->negro
      body: InkWell(
        onTap: _goNext,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.beige, AppColors.black],
            ),
          ),
          child: Center(
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // LOGO ORBITAL
                  SizedBox(
                    height: 140,
                    width: 140,
                    child: AnimatedBuilder(
                      animation: _orbitCtrl,
                      builder: (_, __) {
                        final t = _orbitCtrl.value * 2 * math.pi;
                        final r = 46.0;
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0x1AFFFFFF),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: AppColors.outline),
                              ),
                              child: const Icon(Icons.school, size: 64, color: AppColors.white),
                            ),
                            // Partículas orbitando (3 puntitos luminosos)
                            for (int i = 0; i < 3; i++)
                              Positioned(
                                left: 70 + r * math.cos(t + (i * 2 * math.pi / 3)) - 6,
                                top: 70 + r * math.sin(t + (i * 2 * math.pi / 3)) - 6,
                                child: Container(
                                  height: 12,
                                  width: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(blurRadius: 20, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Bienvenido a TesiXpress',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Evaluación estricta de tu tesis con IA',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 16),
                  Opacity(
                    opacity: 0.9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0x1AFFFFFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: const Text('Toca para continuar', style: TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
