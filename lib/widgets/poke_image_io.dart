import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

  return CachedNetworkImage(
    imageUrl: imageUrl,
    width: width,
    height: height,
    fit: fit,
    memCacheWidth: cacheWidth,
    memCacheHeight: cacheHeight,
    fadeInDuration: const Duration(milliseconds: 200),
    placeholder:
        placeholder ??
        (context, url) => Center(
          child: SizedBox(
            width: width != null ? width * 0.5 : 24,
            height: height != null ? height * 0.5 : 24,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
    errorWidget: (context, url, error) {
      if (fallbackUrl != null && fallbackUrl.isNotEmpty) {
        return CachedNetworkImage(
          imageUrl: fallbackUrl,
          width: width,
          height: height,
          fit: fit,
          memCacheWidth: cacheWidth,
          memCacheHeight: cacheHeight,
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
