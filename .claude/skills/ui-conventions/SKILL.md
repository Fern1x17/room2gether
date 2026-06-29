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
