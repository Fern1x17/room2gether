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
  Publicar, `NavigationRail` lateral y master-detail en las secciones que lo
  tienen: **Buscar** (filtros persistentes | lista | detalle) y **Chats**
  (lista de conversaciones | chat). Perfil es sección de contenido único
  (formulario centrado, ancho máx. 840 dp).

Reglas:

- La forma se elige **solo por ancho**: `kDesktopMinWidth` (840 dp, clase
  "expanded" de Material 3) definido en `core/layout/breakpoints.dart`. No
  añadas más breakpoints sin actualizar esa constante única.
- **Prohibido decidir layout con `kIsWeb` o `Platform.*`.** Única excepción
  aprobada (2026-07-14): `desktopLayoutSupportedProvider` en
  `core/layout/adaptive_shell.dart` usa `kIsWeb` como *techo* para que Android
  jamás renderice el escritorio (ni tablet ni apaisado). No añadas otras.
- Los **widgets de contenido son compartidos** (p. ej. `ListingCard`,
  `ListingListView`, `FiltersPanel`, `ConversationsListView`): un cambio en
  ellos debe verse en ambas formas sin tocar nada más. Los shells solo
  disponen, no duplican contenido.
- Las secciones de la navegación principal viven en
  `core/layout/shell_destinations.dart` (única fuente para barra y rail) y
  cada una es una rama del `StatefulShellRoute` en `core/router/app_router.dart`.
  Para añadir una sección nueva (p. ej. "Guardados"): añade el destino ahí,
  su rama en el router, y nada más.
- Rutas a pantalla completa **sin** navegación principal (auth, onboarding,
  crear/editar publicación) van **fuera** del shell, como rutas raíz. Las
  rutas de detalle que forman un master-detail (`/listings/:id`, `/chats/:id`)
  viven **dentro** de la rama de su sección (ver "Patrón master-detail").
- En web, `web/index.html` debe conservar la meta `viewport` con
  `width=device-width`; sin ella el breakpoint no funciona en móviles.
- Los tests de layout fijan `tester.view.physicalSize` y, para simular web,
  sobrescriben `desktopLayoutSupportedProvider` (ver
  `test/core/layout/adaptive_shell_test.dart`).

## Patrón master-detail (panel de detalle)

El panel de detalle **no es un widget**: es un patrón de routing. No busques un
"SidePanel" que extraer. Una sección con master-detail es una rama del
`StatefulShellRoute` con **dos rutas**: la lista (`/feed`, `/chats`) y el detalle
(`/listings/:id`, `/chats/:id`). En escritorio, el `DesktopShell` dispone, para
esa sección, columnas persistentes + **el navegador de la rama** como panel
derecho; el navegador muestra la lista-como-placeholder (en la ruta de lista) o
el detalle (en la ruta `:id`). La selección viaja por la **URL**, así que el
deep-link y compartir enlaces siguen funcionando.

Piezas por sección (ejemplo Chats, espeja Buscar):

- **Widget de lista compartido** (`ConversationsListView`): estados
  carga/error/vacío + resaltado del seleccionado. Lo usan móvil y escritorio.
- **Pantalla de la ruta de lista** (`ConversationsScreen`): en móvil pinta la
  lista; en escritorio devuelve un *placeholder* ("Selecciona…"), porque la
  lista la pinta el shell.
- **Pane de escritorio** (`ConversationsListPane`): columna persistente que
  envuelve el widget de lista; calcula el seleccionado desde `currentUri` y
  navega con `push`/`pushReplacement` (sustituye si ya hay detalle abierto, para
  no apilar).
- **Composición en `DesktopShell`**: `if (currentIndex == <sección>) ...[ pane,
  divisor ]` antes del `Expanded` del navegador de la rama. El `Expanded`
  keyado (`ValueKey('desktop-content')`) es siempre el último hijo y su árbol
  interior no cambia de forma (solo el `maxWidth`), para no perder estado al
  cambiar de sección.

**Para añadir un tercer panel** (p. ej. "Guardados"): añade el destino en
`shell_destinations.dart`, una rama con `/saved` + `/saved/:id` en el router,
un `SavedListView` compartido, haz que `SavedScreen` devuelva placeholder en
escritorio, crea un `SavedListPane` y componlo en `DesktopShell` para ese índice.
No dupliques contenido en el shell.

**Secciones son ramas independientes** (`IndexedStack`): solo una está en
pantalla a la vez y cada una conserva su propio detalle abierto. No hay conflicto
entre el panel de publicación y el de chat: cambiar de sección preserva el otro.

**Navegación entre ramas:** para abrir un detalle que vive en la rama de *otra*
sección (p. ej. "Enviar mensaje" abre `/chats/:id` desde el detalle de una
publicación) usa **`context.go`**, no `push`: `push` no cruza ramas.

## Pantallas sin navegación principal en escritorio

Bienvenida, login y registro no llevan barra ni rail y quedan fuera del shell.
Para que en escritorio no se estiren de borde a borde, envuelve su contenido en
`CenteredFormFrame` (`core/widgets/`): a partir de `kDesktopMinWidth` centra y
limita a `kAuthContentMaxWidth`; por debajo devuelve el hijo intacto (móvil sin
cambios). La decisión es **100 % por ancho** (sin `kIsWeb`): no hay master-detail
que romper en Android, un formulario centrado es deseable en cualquier pantalla
ancha. Reutiliza el formulario existente; no dupliques campos ni validación.

Hay **dos encuadres**, según qué envuelvas:

- `CenteredFormFrame` — el contenido **dentro** del `body` de una pantalla que
  ya tiene su `Scaffold` (bienvenida, login, registro). Ancho
  `kAuthContentMaxWidth`.
- `CenteredPageFrame` — una **pantalla entera**, con su `Scaffold` y su
  `AppBar`, cuando es ruta raíz y no pasa por el shell. Añade un `Scaffold`
  exterior que pinta el fondo alrededor. Lo usa `/onboarding`, que es el mismo
  formulario de perfil de la pestaña Perfil, con `kProfileContentMaxWidth`
  (840) para que se vea idéntico en los dos sitios. Esa constante la comparten
  la ruta y `DesktopShell`: si cambia el ancho del perfil, cambia en un único
  sitio.

Los dos devuelven el hijo intacto por debajo de `kDesktopMinWidth`. Si creas
otra ruta raíz a pantalla completa (`/listings/new`, `/listings/:id/edit`…),
encuádrala con `CenteredPageFrame` o se estirará en escritorio.
