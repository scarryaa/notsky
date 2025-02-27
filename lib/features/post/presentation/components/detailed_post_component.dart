import 'package:bluesky/app_bsky_embed_video.dart';
import 'package:bluesky/bluesky.dart' hide Image;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:notsky/features/post/presentation/components/avatar_component.dart';
import 'package:notsky/features/post/presentation/components/post_actions_component.dart';
import 'package:notsky/features/post/presentation/components/video_component.dart';
import 'package:notsky/features/post/presentation/cubits/post_cubit.dart';
import 'package:notsky/features/post/presentation/cubits/post_state.dart';

class DetailedPostComponent extends StatefulWidget {
  const DetailedPostComponent({super.key, required this.post});

  final Post post;

  @override
  State<DetailedPostComponent> createState() => _DetailedPostComponentState();
}

class _DetailedPostComponentState extends State<DetailedPostComponent> {
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostCubit, PostState>(
      builder:
          (context, state) => Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.25),
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 2.0),
                  Row(
                    spacing: 8.0,
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AvatarComponent(
                        avatar: widget.post.author.avatar,
                        size: 40.0,
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDisplayName(),
                          _buildHandle(context),
                          SizedBox(height: 2.0),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 2.0),
                      _buildPostContent(),
                      SizedBox(height: 6.0),
                      _buildIndexedAt(context),
                      SizedBox(height: 8.0),
                      _buildStats(context, state),
                      SizedBox(height: 4.0),
                      PostActionsComponent(
                        iconSize: 20.0,
                        indentEnd: false,
                        likeCount: state.likeCount ?? widget.post.likeCount,
                        replyCount: widget.post.replyCount,
                        repostCount:
                            state.repostCount ??
                            (widget.post.repostCount + widget.post.quoteCount),
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
                              currentRepostCount + (state.isReposted ? -1 : 1);

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
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildGif() {
    final record = widget.post.record;
    if (record.embed == null || record.embed?.data is! EmbedExternal) {
      return const SizedBox.shrink();
    }
    final embedExternal = record.embed!.data as EmbedExternal;
    final url = embedExternal.external.uri;

    double aspectRatio = 1.0;

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

  Widget _buildHandle(BuildContext context) {
    return Flexible(
      child: Text(
        '@${widget.post.author.handle}',
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildPostContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.post.record.text,
          softWrap: true,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14.0,
          ),
        ),
        _buildGif(),
        _buildVideo(),
        _buildImageGrid(),
      ],
    );
  }

  Widget _buildIndexedAt(BuildContext context) {
    return Text(
      formatTime(widget.post.indexedAt),
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 12.0,
      ),
    );
  }

  String formatTime(DateTime indexedAt) {
    return DateFormat('MMMM d, yyyy \'at\' h:mm a').format(indexedAt.toLocal());
  }

  Widget _buildStats(BuildContext context, PostState state) {
    return ((state.repostCount ?? widget.post.repostCount) > 0 ||
            widget.post.quoteCount > 0 ||
            (state.likeCount ?? widget.post.likeCount) > 0)
        ? Container(
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.25),
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              spacing: 14.0,
              children: [
                if ((state.repostCount ?? widget.post.repostCount) > 0)
                  Text(
                    '${state.repostCount ?? widget.post.repostCount} repost${(state.repostCount ?? widget.post.repostCount) > 1 ? 's' : ''}',
                  ),
                if (widget.post.quoteCount > 0)
                  Text(
                    '${widget.post.quoteCount} quote${widget.post.quoteCount > 1 ? 's' : ''}',
                  ),
                if ((state.likeCount ?? widget.post.likeCount) > 0)
                  Text(
                    '${state.likeCount ?? widget.post.likeCount} like${(state.likeCount ?? widget.post.likeCount) > 1 ? 's' : ''}',
                  ),
              ],
            ),
          ),
        )
        : SizedBox.shrink();
  }
}
