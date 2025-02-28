import 'package:bluesky/bluesky.dart' hide Image;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_state.dart';
import 'package:notsky/features/post/presentation/components/avatar_component.dart';
import 'package:notsky/features/post/presentation/components/post_actions_component.dart';
import 'package:notsky/features/post/presentation/components/reply_component.dart';
import 'package:notsky/features/post/presentation/components/shared_post_methods.dart';
import 'package:notsky/features/post/presentation/cubits/post_cubit.dart';
import 'package:notsky/features/post/presentation/cubits/post_state.dart';
import 'package:notsky/features/post/presentation/pages/post_detail_page.dart';
import 'package:notsky/shared/components/no_background_cupertino_page_route.dart';

class PostComponent extends StatefulWidget {
  const PostComponent({
    super.key,
    required this.post,
    required this.reason,
    required this.reply,
    required this.isReplyToMissingPost,
    required this.isReplyToBlockedPost,
    required this.contentLabelPreferences,
  });

  final Reason? reason;
  final Post post;
  final Reply? reply;
  final bool isReplyToMissingPost;
  final bool isReplyToBlockedPost;
  final List<ContentLabelPreference> contentLabelPreferences;

  @override
  State<PostComponent> createState() => _PostComponentState();
}

class _PostComponentState extends State<PostComponent> {
  bool _mediaContentExpanded = false;

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
              contentLabelPreferences: widget.contentLabelPreferences,
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
                            if (widget.isReplyToBlockedPost)
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
                                    'Reply to a blocked post',
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
                              onReply: () {
                                String? avatar;
                                final authState =
                                    context.read<AuthCubit>().state;
                                if (authState is AuthSuccess) {
                                  final profile = authState.profile;
                                  avatar = profile?.avatar;
                                }

                                bool shouldHide = false;
                                bool shouldWarn = false;
                                List<String> warningLabels = [];

                                // TODO extract reused logic to util function
                                for (var postLabel in widget.post.labels!) {
                                  for (var preference
                                      in widget.contentLabelPreferences) {
                                    if (postLabel.value.toLowerCase() ==
                                        preference.label.toLowerCase()) {
                                      if (preference.labelerDid == null ||
                                          postLabel.src ==
                                              preference.labelerDid) {
                                        if (preference.visibility ==
                                            ContentLabelVisibility.hide) {
                                          shouldHide = true;
                                          break;
                                        } else if (preference.visibility ==
                                            ContentLabelVisibility.warn) {
                                          shouldWarn = true;
                                          if (!warningLabels.contains(
                                            postLabel.value,
                                          )) {
                                            warningLabels.add(postLabel.value);
                                          }
                                        }
                                      }
                                    }
                                  }

                                  if (shouldHide) break;
                                }

                                showModalBottomSheet(
                                  isScrollControlled: true,
                                  constraints: BoxConstraints(
                                    minHeight:
                                        MediaQuery.of(context).size.height -
                                        250,
                                    maxHeight:
                                        MediaQuery.of(context).size.height -
                                        250,
                                  ),
                                  context: context,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(12.0),
                                    ),
                                  ),
                                  builder:
                                      (context) => ReplyComponent(
                                        hideOrWarn: shouldHide || shouldWarn,
                                        onCancel: () {
                                          Navigator.pop(context);
                                        },
                                        onReply: (String text) {
                                          final auth =
                                              context.read<AuthCubit>();
                                          final blueskyService =
                                              auth.getBlueskyService();

                                          blueskyService.reply(
                                            text,
                                            rootCid:
                                                widget
                                                    .post
                                                    .record
                                                    .reply
                                                    ?.root
                                                    .cid ??
                                                widget.post.cid,
                                            rootUri:
                                                widget
                                                    .post
                                                    .record
                                                    .reply
                                                    ?.root
                                                    .uri ??
                                                widget.post.uri,
                                            parentCid: widget.post.cid,
                                            parentUri: widget.post.uri,
                                          );
                                          Navigator.of(context).pop();
                                        },
                                        replyPost: widget.post,
                                        userAvatar: avatar,
                                      ),
                                );
                              },
                              onMore: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder:
                                      (context) => Container(
                                        // TODO
                                      ),
                                );
                              },
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
        widget.post.author.displayName
                ?.replaceAll('\r\n', '')
                .replaceAll('\n', '') ??
            '',
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHandle() {
    return Flexible(
      child: Text(
        '@${widget.post.author.handle.replaceAll('\r\n', '').replaceAll('\n', '')}',
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
    bool shouldHide = false;
    bool shouldWarn = false;
    List<String> warningLabels = [];

    for (var postLabel in widget.post.labels!) {
      for (var preference in widget.contentLabelPreferences) {
        if (postLabel.value.toLowerCase() == preference.label.toLowerCase()) {
          if (preference.labelerDid == null ||
              postLabel.src == preference.labelerDid) {
            if (preference.visibility == ContentLabelVisibility.hide) {
              shouldHide = true;
              break;
            } else if (preference.visibility == ContentLabelVisibility.warn) {
              shouldWarn = true;
              if (!warningLabels.contains(postLabel.value)) {
                warningLabels.add(postLabel.value);
              }
            }
          }
        }
      }

      if (shouldHide) break;
    }

    if (shouldHide) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'Content hidden',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

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

        if (shouldWarn)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                margin: EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.amber, size: 18.0),
                    SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        warningLabels.join(', '),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _mediaContentExpanded = !_mediaContentExpanded;
                        });
                      },
                      child: Text(_mediaContentExpanded ? 'Hide' : 'Show'),
                    ),
                  ],
                ),
              ),
              if (_mediaContentExpanded) _buildMediaContent(),
            ],
          )
        else
          _buildMediaContent(),
      ],
    );
  }

  Widget _buildMediaContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SharedPostMethods.buildGifOrYoutubeVideo(widget.post),
        SharedPostMethods.buildVideo(widget.post),
        _buildImageGrid(),
      ],
    );
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
