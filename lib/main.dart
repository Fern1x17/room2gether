import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart'; // <--- ESTA ES LA IMPORTACIÓN CORRECTA
import 'core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
    // PKCE explícito (confirmación de email por código). detectSessionInUri en
    // false porque el canje del código lo hace nuestra página /auth/callback,
    // no el observador automático (que además, con hash URL strategy, no
    // reconoce el código incrustado en el fragmento). Así solo un actor
    // consume el código, que solo puede usarse una vez.
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      detectSessionInUri: false,
    ),
  );
  runApp(const ProviderScope(child: Room2getherApp()));
}

class Room2getherApp extends ConsumerWidget {
  const Room2getherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    // `valueOrNull` y no `value`: este último RELANZA el error si no se pudo
    // leer la preferencia guardada, y aquí eso dejaría la app entera sin
    // pintar. El tema del sistema es un respaldo perfectamente válido.
    final themeMode =
        ref.watch(themeControllerProvider).valueOrNull ?? ThemeMode.system;

    return MaterialApp.router(
      title: 'Room2gether',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
