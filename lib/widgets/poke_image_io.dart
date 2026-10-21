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
  int? cacheWidth,
  int? cacheHeight,
}) {
  final double pixelRatio = MediaQuery.of(context).devicePixelRatio;

  final int? resolvedCacheWidth =
      cacheWidth ?? (width != null ? (width * pixelRatio).toInt() : null);
  final int? resolvedCacheHeight =
      cacheHeight ?? (height != null ? (height * pixelRatio).toInt() : null);

  // Safety fallback: if no dimensions are given, clamp decoding to max 400x400
  // to prevent uncompressed full-res sprites from causing 1GB RAM spikes.
  final int? effectiveCacheWidth =
      resolvedCacheWidth ?? (resolvedCacheHeight == null ? 400 : null);
  final int? effectiveCacheHeight =
      resolvedCacheHeight ?? (resolvedCacheWidth == null ? 400 : null);

  return CachedNetworkImage(
    imageUrl: imageUrl,
    width: width,
    height: height,
    fit: fit,
    memCacheWidth: effectiveCacheWidth,
    memCacheHeight: effectiveCacheHeight,
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
