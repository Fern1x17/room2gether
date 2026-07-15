// Apertura de enlaces externos sin dependencias de pub.dev.
//
// Usa import condicional: en web delega en `dart:html` (window.open); en
// otras plataformas (Android/iOS) usa la implementación stub, que no hace
// nada. La pantalla que lo llame debe comprobar `kIsWeb` para ofrecer una
// alternativa en móvil (p. ej. un SnackBar). Cuando la app se publique en
// tiendas, aquí es donde se integraría algo como `url_launcher`.
export 'link_opener_stub.dart' if (dart.library.html) 'link_opener_web.dart';
