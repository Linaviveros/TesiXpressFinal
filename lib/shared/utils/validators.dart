class Validators {
  /// Email RFC5322 simplificado y robusto
  static final RegExp _emailRe = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@"
    r"[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?"
    r"(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
  );

  /// Fuerte: mínimo 8, al menos 1 mayúscula, 1 minúscula, 1 dígito y 1 símbolo.
  static final RegExp _passwordRe =
      RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[^\w\s]).{8,}$');

  static bool isValidEmail(String s) => _emailRe.hasMatch(s.trim());

  static bool isStrongPassword(String s) => _passwordRe.hasMatch(s.trim());
}
