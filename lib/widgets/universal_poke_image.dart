import 'package:flutter/material.dart';

import 'poke_image_io.dart' if (dart.library.html) 'poke_image_web.dart';

class UniversalPokeImage extends StatelessWidget {
  final String imageUrl;
  final String? fallbackUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double errorIconSize;
  final Widget Function(BuildContext, String)? placeholder;

  const UniversalPokeImage({
    super.key,
    required this.imageUrl,
    this.fallbackUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.errorIconSize = 24.0,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return buildPokeImage(
      context: context,
      imageUrl: imageUrl,
      fallbackUrl: fallbackUrl,
      width: width,
      height: height,
      fit: fit,
      errorIconSize: errorIconSize,
      placeholder: placeholder,
    );
  }
}
