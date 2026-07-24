import 'dart:async';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/image_processing.dart';

/// Abre el recorte a pantalla completa y devuelve los bytes recortados, o
/// `null` si el usuario cancela.
Future<Uint8List?> showAvatarCropper(
  BuildContext context,
  Uint8List imageBytes,
) {
  return Navigator.of(context, rootNavigator: true).push<Uint8List>(
    MaterialPageRoute<Uint8List>(
      fullscreenDialog: true,
      builder: (_) => AvatarCropperScreen(imageBytes: imageBytes),
    ),
  );
}

/// Recorte cuadrado (1:1) de la foto de perfil, al estilo de WhatsApp o
/// Instagram: el marco está fijo y es la imagen la que se mueve y se amplía
/// con dos dedos (o con la rueda del ratón).
///
/// `crop_your_image` es Flutter puro, así que la misma pantalla vale para
/// Android y para web sin condicionales de plataforma.
class AvatarCropperScreen extends StatefulWidget {
  const AvatarCropperScreen({super.key, required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<AvatarCropperScreen> createState() => _AvatarCropperScreenState();
}

/// Tras esta espera se ofrece el recorte automático: o el recortador no ha
/// conseguido abrir la foto, o va tan lento que da igual.
const Duration _kCropperStuckAfter = Duration(seconds: 12);

class _AvatarCropperScreenState extends State<AvatarCropperScreen> {
  final _controller = CropController();
  bool _cropping = false;
  bool _ready = false;
  bool _stuck = false;
  Timer? _stuckTimer;

  @override
  void initState() {
    super.initState();
    _armStuckTimer();
  }

  @override
  void dispose() {
    _stuckTimer?.cancel();
    super.dispose();
  }

  /// El recortador decodifica en Dart y puede no volver nunca con según qué
  /// foto. Sin esto, la pantalla se queda cargando para siempre y la única
  /// salida es cancelar.
  void _armStuckTimer() {
    _stuckTimer?.cancel();
    _stuckTimer = Timer(_kCropperStuckAfter, () {
      if (mounted && !_ready) setState(() => _stuck = true);
    });
  }

  void _onStatusChanged(CropStatus status) {
    if (status == CropStatus.ready && !_ready) {
      _stuckTimer?.cancel();
      setState(() {
        _ready = true;
        _stuck = false;
      });
    }
  }

  void _confirm() {
    setState(() => _cropping = true);
    // Si el recorte tampoco vuelve, se vuelve a ofrecer la salida automática.
    _stuckTimer = Timer(_kCropperStuckAfter, () {
      if (mounted) setState(() => _stuck = true);
    });
    _controller.crop();
  }

  /// Salida garantizada: recorte cuadrado al centro con nuestra propia
  /// tubería, sin pasar por el recortador.
  void _useWithoutCropping() {
    final bytes = cropSquareCenterAndEncodeJpeg(widget.imageBytes);
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo usar esta foto.')),
      );
      return;
    }
    Navigator.of(context).pop(bytes);
  }

  void _onCropped(CropResult result) {
    if (!mounted) return;
    switch (result) {
      case CropSuccess(:final croppedImage):
        Navigator.of(context).pop(croppedImage);
      case CropFailure():
        _stuckTimer?.cancel();
        setState(() {
          _cropping = false;
          _stuck = true;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recorta tu foto'),
        leading: IconButton(
          onPressed: _cropping ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          tooltip: 'Cancelar',
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_stuck)
              MaterialBanner(
                content: const Text(
                  'Esta foto está tardando demasiado en abrirse para '
                  'recortarla a mano.',
                ),
                leading: const Icon(Icons.info_outline),
                actions: [
                  TextButton(
                    onPressed: _useWithoutCropping,
                    child: const Text('Usar recortada al centro'),
                  ),
                ],
              ),
            Expanded(
              child: Crop(
                image: widget.imageBytes,
                controller: _controller,
                onCropped: _onCropped,
                onStatusChanged: _onStatusChanged,
                aspectRatio: 1,
                withCircleUi: true,
                // Marco fijo + imagen movible: el gesto es el que espera
                // cualquiera que haya cambiado su foto en otra app.
                interactive: true,
                fixCropRect: true,
                initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
                  size: 0.8,
                  aspectRatio: 1,
                ),
                baseColor: theme.colorScheme.surfaceContainerHighest,
                maskColor: theme.colorScheme.scrim.withValues(alpha: 0.6),
                progressIndicator: const CircularProgressIndicator(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Pellizca para ampliar y arrastra para encuadrar.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _cropping
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text('Cancelar'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: _cropping ? null : _confirm,
                            child: _cropping
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Confirmar'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
