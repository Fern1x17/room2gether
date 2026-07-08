import 'package:roomie/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

User fakeUser({String id = 'user-1', String email = 'test@example.com'}) {
  return User(
    id: id,
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    email: email,
    createdAt: DateTime.now().toIso8601String(),
  );
}

Session fakeSession({User? user}) {
  return Session(
    accessToken: 'fake-access-token',
    tokenType: 'bearer',
    user: user ?? fakeUser(),
  );
}

/// Repositorio falso para tests, sin tocar Supabase real.
///
/// Por defecto simula un registro/login exitoso con sesión activa. Pásale
/// [signUpError]/[signInError] para simular un fallo, o
/// [signUpWithoutSession] para simular el caso de confirmación de email
/// pendiente (signUp sin sesión).
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.signUpError,
    this.signInError,
    this.signOutError,
    this.signUpWithoutSession = false,
  });

  final Object? signUpError;
  final Object? signInError;
  final Object? signOutError;
  final bool signUpWithoutSession;
  bool signedOut = false;

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required DateTime birthdate,
  }) async {
    if (signUpError != null) throw signUpError!;
    if (signUpWithoutSession) {
      return AuthResponse(user: fakeUser(email: email));
    }
    return AuthResponse(
      session: fakeSession(user: fakeUser(email: email)),
    );
  }

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    if (signInError != null) throw signInError!;
    return AuthResponse(
      session: fakeSession(user: fakeUser(email: email)),
    );
  }

  @override
  Future<void> signOut() async {
    if (signOutError != null) throw signOutError!;
    signedOut = true;
  }
}
