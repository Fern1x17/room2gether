import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/chat/presentation/screens/conversations_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/feed/presentation/screens/home_selection_screen.dart'; // <--- Nueva pantalla añadida
import '../../features/feed/presentation/screens/listing_detail_screen.dart';
import '../../features/listing/presentation/screens/create_listing_screen.dart';
import '../../features/listing/presentation/screens/edit_listing_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../layout/adaptive_shell.dart';
import '../supabase/supabase_client.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // RF-13: supabase_flutter guarda la sesión en el dispositivo y la restaura
  // en Supabase.initialize(); si existe, se entra directo a la pantalla de
  // selección sin pasar por la pantalla de bienvenida.
  final hasSession = supabase.auth.currentSession != null;
  // Cambiamos la ruta inicial de '/feed' a '/home'
  return buildAppRouter(initialLocation: hasSession ? '/home' : '/');
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
          // Buscar: Nueva pantalla de selección como raíz de la rama.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeSelectionScreen(),
              ),
              GoRoute(
                path: '/feed',
                builder: (context, state) {
                  // Recuperamos el parámetro que pasamos desde HomeSelectionScreen
                  final isLookingForRoommate = state.extra as bool? ?? true;
                  return FeedScreen(isLookingForRoommate: isLookingForRoommate);
                },
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
              ),
            ],
          ),
        ],
      ),
    ],
  );
}