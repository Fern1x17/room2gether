import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_redirect.dart';
import '../../features/auth/presentation/screens/email_confirmation_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/chat/presentation/screens/conversations_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/feed/presentation/screens/listing_detail_screen.dart';
import '../../features/listing/presentation/screens/create_listing_screen.dart';
import '../../features/listing/presentation/screens/edit_listing_screen.dart';
import '../../features/moderation/presentation/screens/blocked_users_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../layout/adaptive_shell.dart';
import '../supabase/supabase_client.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // RF-13: supabase_flutter guarda la sesión en el dispositivo y la restaura
  // en Supabase.initialize(); si existe, se entra directo al feed sin pasar
  // por la pantalla de bienvenida. La sesión solo se destruye con signOut().
  final hasSession = supabase.auth.currentSession != null;
  return buildAppRouter(
    initialLocation: hasSession ? '/feed' : '/',
    launchParams: authCallbackParamsFromLaunchUrl(),
  );
});

/// Construye el router. Separado del provider para poder crearlo en tests
/// sin inicializar Supabase.
///
/// [launchParams] son los parámetros del enlace de confirmación de email
/// leídos de la URL real del navegador. Si vienen, mandan sobre el resto: la
/// app arranca en `/auth/callback` para confirmar la cuenta, llegue la URL en
/// la forma que llegue (ver `auth_redirect.dart`).
/// [isWeb] existe para poder probar la pantalla de confirmación, que solo vive
/// en la web. No decide layout (eso sigue siendo cosa del ancho): decide si una
/// ruta existe en esta plataforma.
GoRouter buildAppRouter({
  required String initialLocation,
  AuthCallbackParams launchParams = const AuthCallbackParams(),
  bool isWeb = kIsWeb,
}) {
  /// Parámetros del enlace: los de la ruta si go_router los ve, y si no los de
  /// la URL de lanzamiento, que es donde acaban con hash URL strategy.
  AuthCallbackParams confirmationParams(GoRouterState state) {
    final routeParams = state.uri.queryParameters;
    return AuthCallbackParams(
      code: routeParams['code'] ?? launchParams.code,
      tokenHash: routeParams['token_hash'] ?? launchParams.tokenHash,
      type: routeParams['type'] ?? launchParams.type,
      errorDescription:
          routeParams['error_description'] ?? launchParams.errorDescription,
    );
  }

  return GoRouter(
    initialLocation: launchParams.isNotEmpty
        ? '/auth/callback'
        : initialLocation,
    // Cuando los parámetros llegan en el fragmento (`#error=...`) la ubicación
    // no corresponde a ninguna ruta; en vez de la pantalla de error genérica de
    // go_router, atendemos el callback. Sin parámetros se deja el
    // comportamiento por defecto.
    errorBuilder: launchParams.isEmpty
        ? null
        : (context, state) => EmailConfirmationScreen(
            code: launchParams.code,
            tokenHash: launchParams.tokenHash,
            type: launchParams.type,
            errorDescription: launchParams.errorDescription,
          ),
    routes: [
      // --- Fuera del shell: pantalla completa, sin barra ni rail. ---
      GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
      // `confirm=pending` llega desde el callback cuando el enlace ya no vale:
      // el login muestra el aviso con el botón de reenviar.
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          emailNotConfirmed: state.uri.queryParameters['confirm'] == 'pending',
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      // Destino del enlace de confirmación de email, y solo de él. Fuera del
      // shell: pantalla completa sin barra ni rail.
      //
      // Existe únicamente en la web (un enlace de correo siempre abre un
      // navegador) y solo se puede llegar con un enlace: quien abra la URL a
      // mano, sin token ni error, acaba en el inicio como si la ruta no
      // existiera.
      GoRoute(
        path: '/auth/callback',
        redirect: (context, state) {
          if (!isWeb) return '/';
          return confirmationParams(state).isEmpty ? '/' : null;
        },
        builder: (context, state) {
          final params = confirmationParams(state);
          return EmailConfirmationScreen(
            code: params.code,
            tokenHash: params.tokenHash,
            type: params.type,
            errorDescription: params.errorDescription,
          );
        },
      ),
      // Alta tras el registro; la misma pantalla vive también en la pestaña
      // Perfil (/profile), dentro del shell.
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const EditProfileScreen(),
      ),
      // Debe ir antes de '/listings/:id' para que 'new' no se capture como id.
      GoRoute(
        path: '/listings/new',
        builder: (context, state) => const CreateListingScreen(),
      ),
      GoRoute(
        path: '/listings/:id/edit',
        builder: (context, state) =>
            EditListingScreen(listingId: state.pathParameters['id']!),
      ),

      // --- Shell adaptativo: barra inferior (móvil) o rail (escritorio). ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AdaptiveShell(
          navigationShell: navigationShell,
          currentUri: state.uri,
        ),
        branches: [
          // Buscar: el detalle vive en la rama para que en móvil conserve la
          // barra inferior y en escritorio se muestre como panel junto a la
          // lista.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                builder: (context, state) => const FeedScreen(),
              ),
              GoRoute(
                path: '/listings/:id',
                builder: (context, state) =>
                    ListingDetailScreen(listingId: state.pathParameters['id']!),
              ),
            ],
          ),
          // Chats
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chats',
                builder: (context, state) => const ConversationsScreen(),
              ),
              GoRoute(
                path: '/chats/:id',
                builder: (context, state) =>
                    ChatScreen(conversationId: state.pathParameters['id']!),
              ),
            ],
          ),
          // Perfil
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const EditProfileScreen(),
                routes: [
                  // Subpágina dentro de la rama Perfil: conserva la barra
                  // inferior en móvil y el rail en escritorio.
                  GoRoute(
                    path: 'blocked',
                    builder: (context, state) => const BlockedUsersScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
