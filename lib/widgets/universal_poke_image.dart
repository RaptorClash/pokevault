import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    if (kIsWeb) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          if (fallbackUrl != null && fallbackUrl!.isNotEmpty) {
            return Image.network(
              fallbackUrl!,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (c, e, s) => Icon(
                Icons.catching_pokemon,
                color: Colors.grey,
                size: errorIconSize,
              ),
            );
          }
          return Icon(
            Icons.catching_pokemon,
            color: Colors.grey,
            size: errorIconSize,
          );
        },
      );
    } else {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder:
            placeholder ??
            (context, url) => Center(
              child: SizedBox(
                width: width != null ? width! * 0.5 : 24,
                height: height != null ? height! * 0.5 : 24,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        errorWidget: (context, url, error) {
          if (fallbackUrl != null && fallbackUrl!.isNotEmpty) {
            return CachedNetworkImage(
              imageUrl: fallbackUrl!,
              width: width,
              height: height,
              fit: fit,
              placeholder:
                  placeholder ??
                  (context, url) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              errorWidget: (c, e, s) => Icon(
                Icons.catching_pokemon,
                color: Colors.grey,
                size: errorIconSize,
              ),
            );
          }
          return Icon(
            Icons.catching_pokemon,
            color: Colors.grey,
            size: errorIconSize,
          );
        },
      );
    }
  }
}
