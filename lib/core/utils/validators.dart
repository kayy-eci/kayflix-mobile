class Validators {
  Validators._();

  static final RegExp _emailPattern =
      RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email wajib diisi';
    if (!_emailPattern.hasMatch(text)) return 'Format email tidak valid';
    if (text.length > 50) return 'Email maksimal 50 karakter';
    return null;
  }

  static String? username(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Username wajib diisi';
    if (text.length < 6) return 'Username minimal 6 karakter';
    if (text.length > 50) return 'Username maksimal 50 karakter';
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Password wajib diisi';
    if (text.length < 6) return 'Password minimal 6 karakter';
    if (text.length > 100) return 'Password maksimal 100 karakter';
    return null;
  }

  static String? required(String? value, {String label = 'Field'}) {
    if ((value ?? '').trim().isEmpty) return '$label wajib diisi';
    return null;
  }
}
