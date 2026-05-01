// Okładka wiadomości z cache'owaniem — placeholder skeleton podczas ładowania.
// [height] pozwala dostosować wysokość: 150 w karcie listy, 300 w pełnym widoku.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:skeletonizer/skeletonizer.dart';

class NewsCoverImage extends StatelessWidget {
  const NewsCoverImage({super.key, required this.imageUrl, this.height = 150});

  final String imageUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheManager: newsCacheManager,
      imageBuilder: (context, imageProvider) => Ink.image(
        image: imageProvider,
        fit: BoxFit.cover,
        width: double.infinity,
        height: height,
      ),
      placeholder: (context, url) =>
          Skeleton.leaf(child: SizedBox(height: height)),
      errorWidget: (context, url, error) => const SizedBox.shrink(),
    );
  }
}
