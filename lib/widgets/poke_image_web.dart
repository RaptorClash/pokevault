import 'package:flutter/material.dart';

Widget buildPokeImage({
  required BuildContext context,
  required String imageUrl,
  String? fallbackUrl,
  double? width,
  double? height,
  BoxFit fit = BoxFit.contain,
  double errorIconSize = 24.0,
  Widget Function(BuildContext, String)? placeholder,
}) {
  final double pixelRatio = MediaQuery.of(context).devicePixelRatio;
  final int? cacheWidth = width != null ? (width * pixelRatio).toInt() : null;
  final int? cacheHeight = height != null
      ? (height * pixelRatio).toInt()
      : null;

  return Image.network(
    imageUrl,
    width: width,
    height: height,
    fit: fit,
    cacheWidth: cacheWidth,
    cacheHeight: cacheHeight,
    errorBuilder: (context, error, stackTrace) {
      if (fallbackUrl != null && fallbackUrl.isNotEmpty) {
        return Image.network(
          fallbackUrl,
          width: width,
          height: height,
          fit: fit,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
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
}
