---
name: ui-conventions
description: Convenciones de interfaz, diseño y estructura de widgets en Flutter para este proyecto. Úsala SIEMPRE que crees o modifiques pantallas, widgets, temas o componentes visuales.
---

# Convenciones de UI

## Estructura de carpetas (feature-first)

```
lib/
  core/
    theme/          # AppTheme, colores, tipografía
    constants/
    utils/
    layout/         # breakpoint + shells (AdaptiveShell, MobileShell, DesktopShell)
    router/         # go_router (rutas + StatefulShellRoute)
    supabase/       # cliente Supabase, helpers
    widgets/        # widgets compartidos (botones, inputs, loaders)
  features/
    auth/
      presentation/ # pantallas + widgets de la feature
      domain/       # modelos, lógica
      data/         # repositorios, acceso a datos
    profile/
    feed/
    listing/
    chat/
    moderation/
  main.dart
```

## Reglas de widgets

- Un widget reutilizable = un fichero propio en `core/widgets/`.
- Widgets `const` siempre que sea posible (mejor rendimiento).
- Estado con Riverpod: usa `ConsumerWidget` / `ConsumerStatefulWidget`.
- Nada de lógica de negocio dentro de los widgets de presentación; va en
  providers/repositorios.
- Estados de carga/error/vacío SIEMPRE contemplados en pantallas que leen datos
  (usa `AsyncValue.when` de Riverpod).

## Tema y estilo

- Definir un único `AppTheme` en `core/theme/`. No hardcodear colores en widgets;
  usar `Theme.of(context)` o las constantes del tema.
- Soportar modo claro y oscuro desde el principio.
- Diseño limpio y profesional (el acabado profesional es un requisito del proyecto).
- Espaciados consistentes: usa una escala (4, 8, 16, 24, 32).

## Accesibilidad y UX

- Tamaños de toque mínimos de 48x48.
- Textos legibles, contraste suficiente.
- Feedback visual en toda acción (loaders, snackbars de confirmación/error).
- Formularios: validación clara e inmediata.

## Idioma

- La app es para usuarios en España: **textos de interfaz en español**.
- Centraliza los textos para facilitar una futura internacionalización
  (no los disperses hardcodeados por las pantallas).

## Layout adaptativo (móvil / escritorio)

La app tiene dos formas sobre los mismos widgets de contenido:

- **Móvil** (Android y web estrecha): `MobileShell` — Scaffold +
  `NavigationBar` inferior (Buscar, Chats, Perfil).
- **Escritorio** (solo web ancha): `DesktopShell` — cabecera con logo y botón
  Publicar, `NavigationRail` lateral y, en Buscar, master-detail
  (filtros persistentes | lista | detalle).

Reglas:

- La forma se elige **solo por ancho**: `kDesktopMinWidth` (840 dp, clase
  "expanded" de Material 3) definido en `core/layout/breakpoints.dart`. No
  añadas más breakpoints sin actualizar esa constante única.
- **Prohibido decidir layout con `kIsWeb` o `Platform.*`.** Única excepción
  aprobada (2026-07-14): `desktopLayoutSupportedProvider` en
  `core/layout/adaptive_shell.dart` usa `kIsWeb` como *techo* para que Android
  jamás renderice el escritorio (ni tablet ni apaisado). No añadas otras.
- Los **widgets de contenido son compartidos** (p. ej. `ListingCard`,
  `ListingListView`, `FiltersPanel`): un cambio en ellos debe verse en ambas
  formas sin tocar nada más. Los shells solo disponen, no duplican contenido.
- Las secciones de la navegación principal viven en
  `core/layout/shell_destinations.dart` (única fuente para barra y rail) y
  cada una es una rama del `StatefulShellRoute` en `core/router/app_router.dart`.
  Para añadir una sección nueva (p. ej. "Guardados"): añade el destino ahí,
  su rama en el router, y nada más.
- Rutas a pantalla completa (auth, onboarding, crear/editar publicación, chat
  individual) van **fuera** del shell, como rutas raíz.
- En web, `web/index.html` debe conservar la meta `viewport` con
  `width=device-width`; sin ella el breakpoint no funciona en móviles.
- Los tests de layout fijan `tester.view.physicalSize` y, para simular web,
  sobrescriben `desktopLayoutSupportedProvider` (ver
  `test/core/layout/adaptive_shell_test.dart`).
