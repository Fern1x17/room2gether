import 'package:room2gether/features/auth/data/auth_repository.dart';
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
///
/// Para el polling de auto-login (CU-01): [signInUnconfirmedTimes] hace que las
/// primeras N llamadas a [signIn] lancen `email_not_confirmed` y la siguiente
/// ya devuelva sesión, simulando que el usuario confirma el email a mitad del
/// polling. Para el callback PKCE: [exchangeError] fuerza un fallo del canje, e
/// [initialSession] fija la sesión previa que devuelve [currentSession].
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.signUpError,
    this.signInError,
    this.signOutError,
    this.signUpWithoutSession = false,
    this.signInUnconfirmedTimes = 0,
    this.resendError,
    this.exchangeError,
    this.verifyError,
    Session? initialSession,
  }) : _currentSession = initialSession;

  final Object? signUpError;
  final Object? signInError;
  final Object? signOutError;
  final bool signUpWithoutSession;

  /// Número de llamadas iniciales a [signIn] que fallan con `email_not_confirmed`
  /// antes de empezar a devolver sesión.
  final int signInUnconfirmedTimes;
  final Object? resendError;
  final Object? exchangeError;
  final Object? verifyError;

  Session? _currentSession;

  /// Nombre con el que se llamó a [signUp], para comprobar que el formulario
  /// lo envía a los metadatos del registro.
  String? lastDisplayName;

  bool signedOut = false;
  int signInCallCount = 0;
  int resendCallCount = 0;
  int exchangeCallCount = 0;
  int verifyCallCount = 0;

  /// Último `token_hash` y `type` recibidos en [verifyEmailToken].
  String? lastTokenHash;
  String? lastTokenType;

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
    required DateTime birthdate,
  }) async {
    lastDisplayName = displayName;
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
    signInCallCount++;
    if (signInError != null) throw signInError!;
    if (signInCallCount <= signInUnconfirmedTimes) {
      throw const AuthException(
        'Email not confirmed',
        code: 'email_not_confirmed',
      );
    }
    final session = fakeSession(user: fakeUser(email: email));
    _currentSession = session;
    return AuthResponse(session: session);
  }

  @override
  Future<void> signOut() async {
    if (signOutError != null) throw signOutError!;
    signedOut = true;
    _currentSession = null;
  }

  @override
  Future<void> resendSignupConfirmation({required String email}) async {
    resendCallCount++;
    if (resendError != null) throw resendError!;
  }

  @override
  Future<Session> exchangeCode(String code) async {
    exchangeCallCount++;
    if (exchangeError != null) throw exchangeError!;
    final session = fakeSession();
    _currentSession = session;
    return session;
  }

  @override
  Future<Session> verifyEmailToken({
    required String tokenHash,
    String? type,
  }) async {
    verifyCallCount++;
    lastTokenHash = tokenHash;
    lastTokenType = type;
    if (verifyError != null) throw verifyError!;
    final session = fakeSession();
    _currentSession = session;
    return session;
  }

  @override
  Session? get currentSession => _currentSession;
}
