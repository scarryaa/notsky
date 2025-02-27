import 'package:bluesky/app_bsky_embed_video.dart';
import 'package:bluesky/bluesky.dart' hide Image;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/post/presentation/components/avatar_component.dart';
import 'package:notsky/features/post/presentation/components/post_actions_component.dart';
import 'package:notsky/features/post/presentation/components/video_component.dart';
import 'package:notsky/features/post/presentation/cubits/post_cubit.dart';
import 'package:notsky/features/post/presentation/cubits/post_state.dart';
import 'package:notsky/features/post/presentation/pages/post_detail_page.dart';
import 'package:notsky/shared/components/no_background_cupertino_page_route.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class PostComponent extends StatefulWidget {
  const PostComponent({
    super.key,
    required this.post,
    required this.reason,
    required this.reply,
    required this.isReplyToMissingPost,
  });

  final Reason? reason;
  final Post post;
  final Reply? reply;
  final bool isReplyToMissingPost;

  @override
  State<PostComponent> createState() => _PostComponentState();
}

class _PostComponentState extends State<PostComponent> {
  @override
  void initState() {
    super.initState();
    context.read<PostCubit>().initializePost(
      widget.post.uri.toString(),
      widget.post.viewer.isLiked,
      widget.post.viewer.like,
      widget.post.viewer.isReposted,
      widget.post.viewer.repost,
      widget.post.likeCount,
      widget.post.repostCount + widget.post.quoteCount,
    );
  }

  void _handlePostTap() {
    Navigator.of(context).push(
      NoBackgroundCupertinoPageRoute(
        builder:
            (context) => PostDetailPage(
              post: widget.post,
              reply: widget.reply,
              reason: widget.reason,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostCubit, PostState>(
      builder:
          (context, state) => InkWell(
            splashColor: Colors.transparent,
            onTap: _handlePostTap,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              child: Column(
                children: [
                  _buildReasonRepost(widget.reason),
                  SizedBox(height: 2.0),
                  Row(
                    spacing: 8.0,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AvatarComponent(
                        avatar: widget.post.author.avatar,
                        size: 40.0,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              spacing: 4.0,
                              children: [
                                _buildDisplayName(),
                                _buildHandle(),
                                Text('•'),
                                _buildIndexedAt(),
                              ],
                            ),
                            if (widget.isReplyToMissingPost)
                              Row(
                                spacing: 2.0,
                                children: [
                                  Icon(
                                    Icons.reply,
                                    size: 12.5,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.8),
                                  ),
                                  Text(
                                    'Reply to a post',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            _buildPostContent(),
                            SizedBox(height: 4.0),
                            PostActionsComponent(
                              likeCount:
                                  state.likeCount ?? widget.post.likeCount,
                              replyCount: widget.post.replyCount,
                              repostCount:
                                  state.repostCount ??
                                  (widget.post.repostCount +
                                      widget.post.quoteCount),
                              repostedByViewer: state.isReposted,
                              likedByViewer: state.isLiked,
                              // TODO post actions
                              onLike: () async {
                                final newLikeCount =
                                    (state.likeCount ?? widget.post.likeCount) +
                                    (state.isLiked ? -1 : 1);

                                await context.read<PostCubit>().toggleLike(
                                  widget.post.cid,
                                  widget.post.uri,
                                );

                                context.read<PostCubit>().updateLikeCount(
                                  newLikeCount,
                                );
                              },
                              onReply: () {},
                              onMore: () {},
                              onRepost: () async {
                                final currentRepostCount =
                                    state.repostCount ??
                                    (widget.post.repostCount +
                                        widget.post.quoteCount);
                                final newRepostCount =
                                    currentRepostCount +
                                    (state.isReposted ? -1 : 1);

                                await context.read<PostCubit>().toggleRepost(
                                  widget.post.cid,
                                  widget.post.uri,
                                );

                                context.read<PostCubit>().updateRepostCount(
                                  newRepostCount,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDisplayName() {
    return Flexible(
      flex: 1,
      child: Text(
        widget.post.author.displayName ?? '',
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHandle() {
    return Flexible(
      child: Text(
        '@${widget.post.author.handle}',
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildReasonRepost(Reason? reason) {
    if (widget.reason == null || widget.reason?.data is! ReasonRepost) {
      return SizedBox.shrink();
    }

    final repostReason = widget.reason?.data as ReasonRepost;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              // TODO go to actor profile
            },
            child: Row(
              children: [
                SizedBox(width: 32.0),
                Icon(Icons.repeat, size: 12.0),
                SizedBox(width: 4.0),
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    'Reposted by ${repostReason.by.displayName}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIndexedAt() {
    return Text(
      getRelativeTime(widget.post.indexedAt),
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }

  Widget _buildPostContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.post.record.text.isNotEmpty)
          Text(
            widget.post.record.text,
            softWrap: true,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14.0,
            ),
          ),
        _buildGifOrYoutubeVideo(),
        _buildVideo(),
        _buildImageGrid(),
      ],
    );
  }

  Widget _buildGifOrYoutubeVideo() {
    final record = widget.post.record;
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

  // TODO merge with detailed video impl
  Widget _buildVideo() {
    final record = widget.post.record;
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

        final did = widget.post.author.did;
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

        final did = widget.post.author.did;
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

  Widget _buildImageGrid() {
    final embed = widget.post.embed;
    if (embed == null || embed.data is! EmbedViewImages) {
      return const SizedBox.shrink();
    }

    final imageEmbed = embed.data as EmbedViewImages;
    final images = imageEmbed.images;

    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    if (images.length == 1) {
      final image = images[0];
      final aspectRatio =
          image.aspectRatio != null
              ? image.aspectRatio!.width / image.aspectRatio!.height
              : 1.0;

      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              image.fullsize,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Icon(Icons.broken_image, color: Colors.grey[600]),
                );
              },
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: images.length <= 2 ? images.length : 2,
          childAspectRatio: 1.0,
          crossAxisSpacing: 4.0,
          mainAxisSpacing: 4.0,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              images[index].fullsize,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Icon(Icons.broken_image, color: Colors.grey[600]),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo';
    } else {
      return '${(difference.inDays / 365).floor()}y';
    }
  }
}
