import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/services/supabase_client.dart';
import '../../../chat/presentation/pages/chat_screen.dart';
import '../../../../config/theme.dart';
import '../../../../shared/utils/validators.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // --- Estado ---
  bool isLogin = true;
  bool busy = false;
  String? error;

  // --- Visibilidad de contraseñas ---
  bool _obscure1 = true;
  bool _obscure2 = true;

  // --- Formularios y controladores ---
  final _loginKey = GlobalKey<FormState>();
  final _registerKey = GlobalKey<FormState>();

  final emailCtrl = TextEditingController();
  final passCtrl  = TextEditingController();

  // Solo registro:
  final nameCtrl  = TextEditingController();
  final pass2Ctrl = TextEditingController();

  // --- Helpers ---
  void _toggleMode() {
    // Limpia formularios y campos al alternar entre login/registro
    _loginKey.currentState?.reset();
    _registerKey.currentState?.reset();
    emailCtrl.clear();
    passCtrl.clear();
    nameCtrl.clear();
    pass2Ctrl.clear();
    setState(() {
      error = null;
      isLogin = !isLogin;
      _obscure1 = true;
      _obscure2 = true;
    });
  }

  // --- Validadores con mensajes en español (usa utils/validators.dart) ---
  String? _validateEmail(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'El correo es obligatorio.';
    if (!Validators.isValidEmail(s)) return 'Ingresa un correo válido (ej.: usuario@dominio.com).';
    return null;
  }

  String? _validatePassword(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'La contraseña es obligatoria.';
    if (!Validators.isStrongPassword(s)) {
      return 'Contraseña insegura. Debe cumplir:\n'
             '• Mínimo 8 caracteres\n'
             '• Al menos 1 mayúscula y 1 minúscula\n'
             '• Al menos 1 número\n'
             '• Al menos 1 símbolo';
    }
    return null;
  }

  String? _validateName(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Tu nombre es obligatorio.';
    if (s.length < 2) return 'Ingresa un nombre válido.';
    return null;
  }

  String? _validateConfirm(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Confirma tu contraseña.';
    if (s != passCtrl.text.trim()) return 'Las contraseñas no coinciden.';
    return null;
  }

  // --- Acciones Supabase ---
  Future<void> _submitLogin() async {
    final ok = _loginKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() { busy = true; error = null; });
    try {
      await Supa.client.auth.signInWithPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );
    } on AuthException catch (e) {
      setState(() { error = e.message; });
    } finally {
      if (mounted) setState(() { busy = false; });
    }
  }

  Future<void> _submitRegister() async {
    final ok = _registerKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() { busy = true; error = null; });
    try {
      await Supa.client.auth.signUp(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
        data: {
          'full_name': nameCtrl.text.trim(),
        },
      );
    } on AuthException catch (e) {
      setState(() { error = e.message; });
    } finally {
      if (mounted) setState(() { busy = false; });
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    nameCtrl.dispose();
    pass2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supa.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supa.client.auth.currentSession;
        if (session != null) return const ChatScreen();

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text('TesiXpress'),
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            actions: [
              TextButton(
                onPressed: busy ? null : _toggleMode,
                child: Text(
                  isLogin ? '' : '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF0C0F14), Color(0xFF141925)],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.beige, AppColors.white],
                    ),
            ),
            alignment: Alignment.center,
            child: LayoutBuilder(
              builder: (_, c) {
                final maxW = c.maxWidth < 520 ? c.maxWidth - 24 : 480.0;
                return ConstrainedBox(
                  constraints: BoxConstraints.tightFor(width: maxW),
                  child: _GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Avatar/logo con halo
                          Container(
                            height: 64, width: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: isDark ? const Color(0x1AFFFFFF) : AppColors.white,
                              border: Border.all(color: isDark ? AppColors.outline : AppColors.outlineDark),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 24,
                                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.12),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.lock_outline, size: 30),
                          ),
                          const SizedBox(height: 14),

                          // Título animado (Login / Registro)
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (w, a) => FadeTransition(opacity: a, child: w),
                            child: Text(
                              isLogin ? 'Iniciar sesión' : 'Crear cuenta',
                              key: ValueKey(isLogin),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // --- AQUÍ LA TRANSICIÓN MARCADA ENTRE FORMULARIOS ---
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 420),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, anim) {
                              final begin = isLogin ? const Offset(0.10, 0) : const Offset(-0.10, 0);
                              final slide = Tween<Offset>(begin: begin, end: Offset.zero).animate(anim);
                              return FadeTransition(
                                opacity: anim,
                                child: SlideTransition(position: slide, child: child),
                              );
                            },
                            child: isLogin
                                ? _LoginForm(
                                    key: const ValueKey('login-form'),
                                    formKey: _loginKey,
                                    emailCtrl: emailCtrl,
                                    passCtrl: passCtrl,
                                    obscure: _obscure1,
                                    onToggleObscure: () => setState(() => _obscure1 = !_obscure1),
                                    onSubmit: _submitLogin,
                                    validateEmail: _validateEmail,
                                    validatePassword: _validatePassword,
                                  )
                                : _RegisterForm(
                                    key: const ValueKey('register-form'),
                                    formKey: _registerKey,
                                    nameCtrl: nameCtrl,
                                    emailCtrl: emailCtrl,
                                    passCtrl: passCtrl,
                                    pass2Ctrl: pass2Ctrl,
                                    obscure1: _obscure1,
                                    obscure2: _obscure2,
                                    onToggleObscure1: () => setState(() => _obscure1 = !_obscure1),
                                    onToggleObscure2: () => setState(() => _obscure2 = !_obscure2),
                                    onSubmit: _submitRegister,
                                    validateName: _validateName,
                                    validateEmail: _validateEmail,
                                    validatePassword: _validatePassword,
                                    validateConfirm: _validateConfirm,
                                  ),
                          ),

                          const SizedBox(height: 10),

                          if (error != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.redAccent : Colors.red).withOpacity(0.09),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.withOpacity(0.35)),
                              ),
                              child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Botón principal
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: busy
                                  ? null
                                  : (isLogin ? _submitLogin : _submitRegister),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                backgroundColor: isDark ? const Color(0x1AFFFFFF) : Colors.black,
                                foregroundColor: Colors.white,
                              ).merge(
                                ButtonStyle(
                                  shadowColor: WidgetStatePropertyAll(
                                    (isDark ? Colors.white : Colors.black).withOpacity(0.20),
                                  ),
                                ),
                              ),
                              child: Text(busy ? 'Procesando…' : (isLogin ? 'Entrar' : 'Registrarme')),
                            ),
                          ),

                          // Toggle login/registro (también limpia al cambiar)
                          TextButton(
                            onPressed: busy ? null : _toggleMode,
                            child: Text(
                              isLogin
                                  ? '¿No tienes cuenta? Regístrate'
                                  : '¿Ya tienes cuenta? Inicia sesión',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// ---------- Tarjeta con efecto "glass" + contorno coherente al tema ----------
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0x14000000) : const Color(0xDFFFFFFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? AppColors.outline : AppColors.outlineDark),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ================== Widgets de formularios ==================

class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  final String? Function(String?) validateEmail;
  final String? Function(String?) validatePassword;

  const _LoginForm({
    super.key,
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.validateEmail,
    required this.validatePassword,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: Column(
        children: [
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'usuario@dominio.com',
              prefixIcon: Icon(Icons.alternate_email),
            ),
            validator: validateEmail,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: passCtrl,
            obscureText: obscure,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                tooltip: obscure ? 'Mostrar' : 'Ocultar',
                onPressed: onToggleObscure,
                icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
              ),
            ),
            validator: validatePassword,
            onFieldSubmitted: (_) => onSubmit(),
          ),
        ],
      ),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final TextEditingController pass2Ctrl;

  final bool obscure1;
  final bool obscure2;
  final VoidCallback onToggleObscure1;
  final VoidCallback onToggleObscure2;
  final VoidCallback onSubmit;

  final String? Function(String?) validateName;
  final String? Function(String?) validateEmail;
  final String? Function(String?) validatePassword;
  final String? Function(String?) validateConfirm;

  const _RegisterForm({
    super.key,
    required this.formKey,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.pass2Ctrl,
    required this.obscure1,
    required this.obscure2,
    required this.onToggleObscure1,
    required this.onToggleObscure2,
    required this.onSubmit,
    required this.validateName,
    required this.validateEmail,
    required this.validatePassword,
    required this.validateConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: Column(
        children: [
          TextFormField(
            controller: nameCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: validateName,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'usuario@dominio.com',
              prefixIcon: Icon(Icons.alternate_email),
            ),
            validator: validateEmail,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: passCtrl,
            obscureText: obscure1,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              helperText: 'Debe cumplir los requisitos de seguridad.',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: obscure1 ? 'Mostrar' : 'Ocultar',
                onPressed: onToggleObscure1,
                icon: Icon(obscure1 ? Icons.visibility : Icons.visibility_off),
              ),
            ),
            validator: validatePassword,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: pass2Ctrl,
            obscureText: obscure2,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Confirmar contraseña',
              prefixIcon: const Icon(Icons.lock_person_outlined),
              suffixIcon: IconButton(
                tooltip: obscure2 ? 'Mostrar' : 'Ocultar',
                onPressed: onToggleObscure2,
                icon: Icon(obscure2 ? Icons.visibility : Icons.visibility_off),
              ),
            ),
            validator: validateConfirm,
            onFieldSubmitted: (_) => onSubmit(),
          ),
        ],
      ),
    );
  }
}
