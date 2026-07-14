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
