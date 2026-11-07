// Okładka wiadomości z cache'owaniem — placeholder skeleton podczas ładowania.
// [aspectRatio] zamiast stałej wysokości: 2,5 w karcie listy (makieta 8a);
// `null` = wypełnia rodzica (hero na pełną szerokość w [FullNewsPage]).
// [borderRadius] zaokrągla samo zdjęcie tam, gdzie nie leży w karcie.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/global/theme/colors.dart';
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
  final double? aspectRatio;
  final BorderRadius borderRadius;

  /// Ramka o docelowym rozmiarze: proporcja albo cały rodzic.
  Widget _frame(Widget child) {
    final ratio = aspectRatio;
    return ratio == null
        ? SizedBox.expand(child: child)
        : AspectRatio(aspectRatio: ratio, child: child);
  }

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheManager: newsCacheManager,
      imageBuilder: (context, imageProvider) => ClipRRect(
        borderRadius: borderRadius,
        child: _frame(Image(image: imageProvider, fit: BoxFit.cover)),
      ),
      placeholder: (context, url) =>
          Skeleton.leaf(child: _frame(const SizedBox())),
      errorWidget: (context, url, error) {
        AppLogger.w("[NEWS-CACHE] Nie udało się załadować obrazu: $url", error);
        // Hero bez obrazu zostaje pustym nagłówkiem w kolorze karty — pasek
        // i tak dostaje tło dopiero po przewinięciu.
        return aspectRatio == null
            ? ColoredBox(color: AppColor.surfaceSecondary)
            : const SizedBox.shrink();
      },
    );
  }
}
