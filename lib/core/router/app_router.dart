import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/feed/presentation/screens/listing_detail_screen.dart';
import '../../features/listing/presentation/screens/create_listing_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../supabase/supabase_client.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // RF-13: supabase_flutter guarda la sesión en el dispositivo y la restaura
  // en Supabase.initialize(); si existe, se entra directo al feed sin pasar
  // por la pantalla de bienvenida. La sesión solo se destruye con signOut().
  final hasSession = supabase.auth.currentSession != null;

  return GoRouter(
    initialLocation: hasSession ? '/feed' : '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(path: '/feed', builder: (context, state) => const FeedScreen()),
      // Debe ir antes de '/listings/:id' para que 'new' no se capture como id.
      GoRoute(
        path: '/listings/new',
        builder: (context, state) => const CreateListingScreen(),
      ),
      GoRoute(
        path: '/listings/:id',
        builder: (context, state) => ListingDetailScreen(
          listingId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
});
