import 'package:flutter/material.dart';

/// Logo de la app: el icono oficial (casa blanca sobre coral).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icon/app_icon.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
    );
  }
}
