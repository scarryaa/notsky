import 'package:bluesky/bluesky.dart';
import 'package:flutter/material.dart';
import 'package:notsky/features/post/presentation/components/media/clickable_image_grid.dart';
import 'package:notsky/features/post/presentation/components/media/image_detail_screen.dart';
import 'package:notsky/features/post/presentation/components/post/shared_post_methods.dart';
import 'package:notsky/features/post/presentation/controllers/bottom_nav_visibility_controller.dart';
import 'package:provider/provider.dart';

class PostMediaRenderer {
  static Widget build(
    BuildContext context,
    Post post, {
    bool detailed = false,
  }) {
    if (detailed) {
      return _buildMediaContent(context, post);
    } else {
      return _buildMediaContent(context, post);
    }
  }

  static Widget _buildMediaContent(BuildContext context, Post post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SharedPostMethods.buildGifOrYoutubeVideo(post),
        SharedPostMethods.buildVideo(post),
        _buildImageGrid(context, post),
      ],
    );
  }

  static Widget _buildImageGrid(BuildContext context, Post post) {
    final embed = post.embed;
    if (embed == null ||
        embed.data is! EmbedViewImages &&
            embed.data is! EmbedViewRecordWithMedia) {
      return const SizedBox.shrink();
    }

    if (embed.data is EmbedViewImages) {
      final imageEmbed = embed.data as EmbedViewImages;
      final images = imageEmbed.images;

      return ClickableImageGrid(
        images: images,
        onImageTap: (image, index) {
          final navController = Provider.of<BottomNavVisibilityController>(
            context,
            listen: false,
          );
          navController.hide();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (context) => ImageDetailScreen(
                    images: images,
                    initialIndex: index,
                    onExit: () {
                      navController.show();
                    },
                  ),
            ),
          );
        },
      );
    } else if (embed.data is EmbedViewRecordWithMedia) {
      final recordWithMedia = embed.data as EmbedViewRecordWithMedia;

      if (recordWithMedia.media.data is EmbedViewImages) {
        final imageEmbed = recordWithMedia.media.data as EmbedViewImages;
        final images = imageEmbed.images;

        return ClickableImageGrid(
          images: images,
          onImageTap: (image, index) {
            final navController = Provider.of<BottomNavVisibilityController>(
              context,
              listen: false,
            );
            navController.hide();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) => ImageDetailScreen(
                      images: images,
                      initialIndex: index,
                      onExit: () {
                        navController.show();
                      },
                    ),
              ),
            );
          },
        );
      } else {
        return SizedBox.shrink();
      }
    } else {
      return SizedBox.shrink();
    }
  }
}
