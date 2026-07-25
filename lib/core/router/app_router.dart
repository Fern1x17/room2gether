import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/auth_callback_screen.dart';
import '../../features/auth/presentation/screens/confirm_email_screen.dart';
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
  return buildAppRouter(initialLocation: hasSession ? '/feed' : '/');
});

/// Construye el router. Separado del provider para poder crearlo en tests
/// sin inicializar Supabase.
GoRouter buildAppRouter({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      // --- Fuera del shell: pantalla completa, sin barra ni rail. ---
      GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      // Espera de confirmación con auto-login por polling (CU-01). Las
      // credenciales llegan por `extra` (en memoria, nunca en la URL). Si se
      // recarga la página se pierde el `extra`: en ese caso caemos a login.
      GoRoute(
        path: '/confirm-email',
        builder: (context, state) {
          final args = state.extra as ({String email, String password})?;
          if (args == null) return const LoginScreen();
          return ConfirmEmailScreen(email: args.email, password: args.password);
        },
      ),
      // Callback del enlace de confirmación de email (flujo PKCE). Con hash URL
      // strategy el `code` llega en el fragmento y go_router lo expone aquí como
      // query. Fuera del shell: pantalla completa sin barra ni rail.
      GoRoute(
        path: '/auth/callback',
        builder: (context, state) => AuthCallbackScreen(
          code: state.uri.queryParameters['code'],
          errorDescription: state.uri.queryParameters['error_description'],
        ),
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
