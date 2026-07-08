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

/// Edad en años cumplidos a fecha de [reference], teniendo en cuenta si el
/// cumpleaños de este año ya ha pasado.
int ageInYears(DateTime birthdate, DateTime reference) {
  var age = reference.year - birthdate.year;
  final hasHadBirthdayThisYear =
      reference.month > birthdate.month ||
      (reference.month == birthdate.month && reference.day >= birthdate.day);
  if (!hasHadBirthdayThisYear) {
    age--;
  }
  return age;
}

/// [now] solo se usa en tests para fijar la fecha de referencia.
String? validateBirthdate(DateTime? value, {DateTime? now}) {
  if (value == null) {
    return 'Introduce tu fecha de nacimiento.';
  }
  final age = ageInYears(value, now ?? DateTime.now());
  if (age < minAge) {
    return 'Debes ser mayor de edad (18 años) para registrarte.';
  }
  if (age > maxAge) {
    return 'Introduce una fecha de nacimiento válida.';
  }
  return null;
}
