// Implementación web de [openExternalLink]. Solo se compila en web gracias al
// import condicional de `link_opener.dart`.
import 'dart:html' as html;

/// Abre [url] en una pestaña nueva del navegador.
void openExternalLink(String url) {
  html.window.open(url, '_blank');
}
