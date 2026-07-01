const int minAge = 18;
const int maxAge = 120;
const int minPasswordLength = 8;

final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) {
    return 'Introduce tu email.';
  }
  if (!_emailRegex.hasMatch(email)) {
    return 'Introduce un email válido.';
  }
  return null;
}

String? validatePassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) {
    return 'Introduce una contraseña.';
  }
  if (password.length < minPasswordLength) {
    return 'La contraseña debe tener al menos $minPasswordLength caracteres.';
  }
  return null;
}

String? validateAge(String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) {
    return 'Introduce tu edad.';
  }
  final age = int.tryParse(raw);
  if (age == null) {
    return 'Introduce una edad válida.';
  }
  if (age < minAge) {
    return 'Debes ser mayor de edad (18 años) para registrarte.';
  }
  if (age > maxAge) {
    return 'Introduce una edad válida.';
  }
  return null;
}
