/// Breakpoints de layout de la app.
///
/// Regla del proyecto: la forma (móvil o escritorio) se decide SIEMPRE por el
/// ancho disponible, nunca por plataforma. Única excepción aprobada
/// (2026-07-14): el layout de escritorio solo existe en web, para garantizar
/// que Android no lo renderice ni en tablet ni en apaisado (ver AdaptiveShell).
library;

/// Ancho lógico mínimo (dp) a partir del cual se usa el layout de escritorio.
///
/// 840 es el umbral de la clase "expanded" de las window size classes de
/// Material 3: por debajo quedan los móviles en vertical, la mayoría de
/// tablets en vertical y las ventanas de escritorio a media pantalla, que
/// reciben el layout móvil (el master-detail de tres columnas no cabe ahí).
const double kDesktopMinWidth = 840;

/// Ancho máximo (dp) del formulario de perfil en escritorio.
///
/// Lo usan los dos sitios donde aparece ese formulario, para que se vea igual
/// en ambos: la sección Perfil del [kDesktopMinWidth] en adelante (encuadrada
/// por `DesktopShell`) y la ruta `/onboarding`, que vive fuera del shell y se
/// encuadra con `CenteredPageFrame`. Es más ancho que
/// [kAuthContentMaxWidth] porque el formulario tiene campos en pareja
/// (presupuesto mínimo/máximo) y una lista de publicaciones.
const double kProfileContentMaxWidth = 840;

/// Ancho máximo (dp) del contenido de las pantallas sin navegación principal
/// (bienvenida, login, registro) cuando se encuadran en escritorio.
///
/// A partir de [kDesktopMinWidth] estas pantallas dejan de ocupar todo el
/// ancho y se centran dentro de este contenedor. 448 es la anchura habitual
/// de un formulario/diálogo Material —cómoda para una sola columna de campos—
/// y equivale a ~la mitad de la clase "expanded" (840). Por debajo del
/// breakpoint no se aplica: el formulario ocupa el ancho completo (móvil).
const double kAuthContentMaxWidth = 448;
