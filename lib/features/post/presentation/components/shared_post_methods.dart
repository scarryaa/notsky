import 'package:bluesky/app_bsky_embed_video.dart';
import 'package:bluesky/bluesky.dart' hide Image;
import 'package:flutter/material.dart';
import 'package:notsky/features/post/presentation/components/video_component.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class SharedPostMethods {
  static Widget buildVideo(Post post) {
    final record = post.record;
    if (record.embed == null ||
        record.embed?.data is! EmbedRecordWithMedia &&
            record.embed?.data is! EmbedVideo) {
      return const SizedBox.shrink();
    }

    bool hasVideoContent = false;

    if (record.embed?.data is EmbedVideo) {
      hasVideoContent = true;
    }

    if (record.embed?.data is EmbedRecordWithMedia) {
      final recordWithMedia = record.embed!.data as EmbedRecordWithMedia;
      if (recordWithMedia.media.data is EmbedVideo) {
        hasVideoContent = true;
      }
    }

    if (!hasVideoContent) {
      return const SizedBox.shrink();
    }

    switch (record.embed?.data) {
      case EmbedVideo():
        final videoContainer = record.embed?.data as EmbedVideo;
        final video = (record.embed?.data as EmbedVideo).video;
        final aspectRatio =
            videoContainer.aspectRatio != null
                ? videoContainer.aspectRatio!.width /
                    videoContainer.aspectRatio!.height
                : 1.0;

        final did = post.author.did;
        final cid = video.ref.link;
        final videoUrl =
            'https://video.bsky.app/watch/$did/$cid/360p/video.m3u8';

        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: VideoComponent(assetUrl: videoUrl),
            ),
          ),
        );
      case EmbedRecordWithMedia():
        final video =
            (record.embed?.data as EmbedRecordWithMedia).media.data
                as EmbedVideo;
        final aspectRatio =
            video.aspectRatio != null
                ? video.aspectRatio!.width / video.aspectRatio!.height
                : 1.0;

        final did = post.author.did;
        final cid = video.video.ref.link;
        final videoUrl =
            'https://video.bsky.app/watch/$did/$cid/360p/video.m3u8';

        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: VideoComponent(assetUrl: videoUrl),
            ),
          ),
        );
      case null:
        return SizedBox.shrink();
      default:
        return SizedBox.shrink();
    }
  }

  static Widget buildGifOrYoutubeVideo(Post post) {
    final record = post.record;
    if (record.embed == null || record.embed?.data is! EmbedExternal) {
      return const SizedBox.shrink();
    }
    final embedExternal = record.embed!.data as EmbedExternal;
    final url = embedExternal.external.uri;

    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      final videoId = YoutubePlayer.convertUrlToId(url);
      if (videoId != null) {
        final controller = YoutubePlayerController(
          initialVideoId: videoId,
          flags: YoutubePlayerFlags(autoPlay: false),
        );

        return ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: YoutubePlayer(controller: controller),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    double aspectRatio = 1.0;

    final imageExtensions = [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.bmp',
      '.webp',
      '.svg',
    ];
    final lowercaseUrl = url.toLowerCase();

    if (!imageExtensions.any((ext) => lowercaseUrl.endsWith(ext))) {
      return SizedBox.shrink();
    }

    try {
      final uri = Uri.parse(url);
      if (uri.queryParameters.containsKey('ww') &&
          uri.queryParameters.containsKey('hh')) {
        double width = double.tryParse(uri.queryParameters['ww']!) ?? 1.0;
        double height = double.tryParse(uri.queryParameters['hh']!) ?? 1.0;
        if (width > 0 && height > 0) {
          aspectRatio = width / height;
        }
      }
    } catch (e) {
      print('Error parsing URL: $e');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final height = maxWidth / aspectRatio;

        return Padding(
          padding: EdgeInsets.only(top: 4.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              url,
              width: maxWidth,
              height: height,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return SizedBox(
                  width: maxWidth,
                  height: height,
                  child: Center(
                    child: CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
