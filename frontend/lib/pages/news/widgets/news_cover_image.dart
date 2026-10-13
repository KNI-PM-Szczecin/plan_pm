// Okładka wiadomości z cache'owaniem — placeholder skeleton podczas ładowania.
// [aspectRatio] zamiast stałej wysokości: 2,5 w karcie listy, 1,25 w pełnym
// widoku (makiety 8a / 6a). [borderRadius] zaokrągla samo zdjęcie w pełnym
// widoku, gdzie nie leży w karcie.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/global/utils/logger.dart';
import 'package:skeletonizer/skeletonizer.dart';

class NewsCoverImage extends StatelessWidget {
  const NewsCoverImage({
    super.key,
    required this.imageUrl,
    this.aspectRatio = 2.5,
    this.borderRadius = BorderRadius.zero,
  });

  final String imageUrl;
  final double aspectRatio;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheManager: newsCacheManager,
      imageBuilder: (context, imageProvider) => ClipRRect(
        borderRadius: borderRadius,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Image(image: imageProvider, fit: BoxFit.cover),
        ),
      ),
      placeholder: (context, url) =>
          Skeleton.leaf(child: AspectRatio(aspectRatio: aspectRatio)),
      errorWidget: (context, url, error) {
        AppLogger.w("[NEWS-CACHE] Nie udało się załadować obrazu: $url", error);
        return const SizedBox.shrink();
      },
    );
  }
}
