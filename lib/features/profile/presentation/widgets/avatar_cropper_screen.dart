import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

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

class _AvatarCropperScreenState extends State<AvatarCropperScreen> {
  final _controller = CropController();
  bool _cropping = false;

  void _confirm() {
    setState(() => _cropping = true);
    _controller.crop();
  }

  void _onCropped(CropResult result) {
    if (!mounted) return;
    switch (result) {
      case CropSuccess(:final croppedImage):
        Navigator.of(context).pop(croppedImage);
      case CropFailure():
        setState(() => _cropping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo recortar la foto. Inténtalo de nuevo.'),
          ),
        );
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
            Expanded(
              child: Crop(
                image: widget.imageBytes,
                controller: _controller,
                onCropped: _onCropped,
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
