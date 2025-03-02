import 'dart:convert';

import 'package:bluesky/bluesky.dart' hide Image, ListView;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_state.dart';
import 'package:notsky/features/post/domain/entities/post_content.dart';
import 'package:notsky/features/post/presentation/components/common/avatar_component.dart';
import 'package:notsky/features/post/presentation/components/interaction/post_actions_component.dart';
import 'package:notsky/features/post/presentation/components/interaction/reply_component.dart';
import 'package:notsky/features/post/presentation/components/media/clickable_image_grid.dart';
import 'package:notsky/features/post/presentation/components/media/image_detail_screen.dart';
import 'package:notsky/features/post/presentation/components/post/base_post_component.dart';
import 'package:notsky/features/post/presentation/components/post/shared_post_methods.dart';
import 'package:notsky/features/post/presentation/controllers/bottom_nav_visibility_controller.dart';
import 'package:notsky/features/post/presentation/cubits/post_cubit.dart';
import 'package:notsky/features/post/presentation/cubits/post_state.dart';
import 'package:notsky/features/post/presentation/pages/post_detail_page.dart';
import 'package:notsky/shared/components/no_background_cupertino_page_route.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class DetailedPostComponent extends StatefulWidget {
  const DetailedPostComponent({
    super.key,
    required this.post,
    required this.contentLabelPreferences,
  });

  final Post post;
  final List<ContentLabelPreference> contentLabelPreferences;

  @override
  State<DetailedPostComponent> createState() => _DetailedPostComponentState();
}

class _DetailedPostComponentState extends State<DetailedPostComponent> {
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
      widget.post.repostCount,
    );

    context.read<PostCubit>().getThread(widget.post.uri);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostCubit, PostState>(
      builder:
          (context, state) => Column(
            children: [
              _buildParentPostsSection(state),

              Container(
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
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDisplayName(),
                                _buildHandle(context),
                                SizedBox(height: 2.0),
                              ],
                            ),
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
                            onReply: () {
                              String? avatar;
                              final authState = context.read<AuthCubit>().state;
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
                                      MediaQuery.of(context).size.height - 250,
                                  maxHeight:
                                      MediaQuery.of(context).size.height - 250,
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
                                        final auth = context.read<AuthCubit>();
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
                    ],
                  ),
                ),
              ),

              _buildRepliesSection(state),
            ],
          ),
    );
  }

  Widget _buildTextWithFacets(String text, List<Facet>? facets) {
    if (facets == null || facets.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 16.5,
        ),
      );
    }

    final sortedFacets = List<Facet>.from(facets);
    sortedFacets.sort((a, b) => a.index.byteStart.compareTo(b.index.byteStart));

    final utf8Bytes = utf8.encode(text);
    final List<InlineSpan> spans = [];
    int currentIndex = 0;

    for (var facet in sortedFacets) {
      final byteStart = facet.index.byteStart;
      final byteEnd = facet.index.byteEnd;

      if (byteStart > currentIndex) {
        final beforeText = utf8.decode(
          utf8Bytes.sublist(currentIndex, byteStart),
        );
        spans.add(
          TextSpan(
            text: beforeText,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16.5,
            ),
          ),
        );
      }

      final facetText = utf8.decode(utf8Bytes.sublist(byteStart, byteEnd));

      if (facet.features.isNotEmpty) {
        var feature = facet.features.first;

        if (feature.data is FacetLink) {
          spans.add(
            TextSpan(
              text: facetText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16.5,
                decoration: TextDecoration.underline,
              ),
              recognizer:
                  TapGestureRecognizer()
                    ..onTap = () {
                      launchUrl(Uri.parse((feature.data as FacetLink).uri));
                    },
            ),
          );
        } else if (feature.data is FacetMention) {
          spans.add(
            TextSpan(
              text: facetText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16.5,
              ),
              recognizer:
                  TapGestureRecognizer()
                    ..onTap = () {
                      // TODO navigate to profile
                    },
            ),
          );
        } else {
          spans.add(
            TextSpan(
              text: facetText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16.5,
              ),
            ),
          );
        }
      } else {
        spans.add(
          TextSpan(
            text: facetText,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16.5,
            ),
          ),
        );
      }

      currentIndex = byteEnd;
    }

    if (currentIndex < utf8Bytes.length) {
      final remainingText = utf8.decode(utf8Bytes.sublist(currentIndex));
      spans.add(
        TextSpan(
          text: remainingText,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16.5,
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildParentPostsSection(PostState state) {
    if (state.isThreadLoading || state.postThread == null) {
      return SizedBox.shrink();
    }

    final threadData = state.postThread!.thread.data as PostThreadViewRecord;
    if (threadData.parent == null) {
      return SizedBox.shrink();
    }

    return _buildParentPosts(threadData.parent!.data);
  }

  Widget _buildRepliesSection(PostState state) {
    if (state.isThreadLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (state.threadError != null) {
      return Text('Error loading thread: ${state.threadError}');
    }

    if (state.postThread == null) {
      return SizedBox.shrink();
    }

    final threadData = state.postThread!.thread.data as PostThreadViewRecord;
    if (threadData.replies == null || threadData.replies!.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outline.withValues(alpha: 0.25),
          ),
        ),
      ),
      child: _buildReplies(threadData.replies!),
    );
  }

  Widget _buildParentPosts(dynamic parent) {
    if (parent is PostThreadViewRecord) {
      final postContent = RegularPost(parent.post);

      Widget parentWidget = BasePostComponent(
        postContent: postContent,
        contentLabelPreferences: widget.contentLabelPreferences,
        detailed: false,
      );

      if (parent.parent != null) {
        return Stack(
          children: [
            Positioned(
              left: 27,
              top: 56,
              bottom: 0,
              width: 2,
              child: Container(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.25),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_buildParentPosts(parent.parent!.data), parentWidget],
            ),
          ],
        );
      }

      return Stack(
        children: [
          Positioned(
            left: 27,
            top: 56,
            bottom: 0,
            width: 2,
            child: Container(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.25),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [parentWidget],
          ),
        ],
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildReplies(List<dynamic> replies) {
    return ListView.separated(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: replies.length,
      separatorBuilder:
          (context, index) => Divider(
            color: Theme.of(
              context,
            ).colorScheme.outline.withValues(alpha: 0.25),
            height: 1,
          ),
      itemBuilder: (context, index) {
        final reply = replies[index];

        if (reply.data is PostThreadViewRecord) {
          final data = reply.data;
          final postContent = RegularPost(data.post);

          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BasePostComponent(
                    postContent: postContent,
                    contentLabelPreferences: widget.contentLabelPreferences,
                    detailed: false,
                  ),
                  if (data.replies != null && data.replies!.isNotEmpty)
                    _buildFlattenedReplies(data.replies!, 1),
                ],
              ),
            ],
          );
        }
        return SizedBox.shrink();
      },
    );
  }

  Widget _buildFlattenedReplies(List<dynamic> replies, int indentLevel) {
    return Stack(
      children: [
        Positioned(
          left: 8.0 * indentLevel,
          top: 0,
          bottom: 0,
          width: 2,
          child: Container(
            color: Theme.of(
              context,
            ).colorScheme.outline.withValues(alpha: 0.25),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              replies.map((reply) {
                if (reply.data is PostThreadViewRecord) {
                  final data = reply.data;
                  final postContent = RegularPost(data.post);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 8.0 * indentLevel),
                        child: BasePostComponent(
                          postContent: postContent,
                          contentLabelPreferences:
                              widget.contentLabelPreferences,
                          detailed: false,
                        ),
                      ),
                      if (data.replies != null && data.replies!.isNotEmpty)
                        _buildFlattenedReplies(data.replies!, indentLevel + 1),
                    ],
                  );
                }
                return SizedBox.shrink();
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildImageGrid() {
    final embed = widget.post.embed;
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

  Widget _buildHandle(BuildContext context) {
    return Flexible(
      child: Text(
        '@${widget.post.author.handle.replaceAll('\r\n', '').replaceAll('\n', '')}',
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
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
        _buildTextWithFacets(
          widget.post.record.text,
          widget.post.record.facets,
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
        _buildExternal(),
        _buildQuotedPost(),
      ],
    );
  }

  Widget _buildExternal() {
    final embed = widget.post.embed;

    if (embed?.data is EmbedViewExternal) {
      final external = (embed!.data as EmbedViewExternal).external;
      // These are handled in other methods already
      if (external.uri.contains('youtu.be') ||
          external.uri.contains('youtube') ||
          external.uri.contains('tenor')) {
        return SizedBox.shrink();
      }
      return _buildExternalContent(external);
    }

    if (embed?.data is EmbedViewRecordWithMedia) {
      final recordWithMedia = embed!.data as EmbedViewRecordWithMedia;
      if (recordWithMedia.media.data is EmbedViewExternal) {
        final external = recordWithMedia.media.data as EmbedViewExternal;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildExternalContent(external.external)],
        );
      }
    }

    return SizedBox.shrink();
  }

  Widget _buildExternalContent(EmbedViewExternalView external) {
    return InkWell(
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      onTap: () {
        launchUrl(Uri.parse(external.uri));
      },
      child: Container(
        margin: EdgeInsets.only(top: 8.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outline.withValues(alpha: 0.25),
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (external.thumbnail != null)
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(7.0)),
                child: Image.network(
                  external.thumbnail!,
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    external.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.0,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Text(
                      external.description,
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Text(
                      Uri.parse(external.uri).host,
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotedPost() {
    final embed = widget.post.embed;

    if (embed?.data is EmbedViewRecordWithMedia) {
      final recordWithMedia = embed!.data as EmbedViewRecordWithMedia;
      final quoteEmbed = recordWithMedia.record;

      if ((quoteEmbed.record).data is EmbedViewRecordViewBlocked) {
        return _buildQuoteBlockedView();
      } else if ((quoteEmbed.record).data is EmbedViewRecordViewNotFound) {
        return _buildQuoteDeletedView();
      }

      final quotedRecord =
          (quoteEmbed.record).data as EmbedViewRecordViewRecord;
      return _buildQuotePostView(quotedRecord);
    } else if (embed?.data is EmbedViewRecord) {
      final quoteEmbed = embed!.data as EmbedViewRecord;

      if ((quoteEmbed.record).data is EmbedViewRecordViewBlocked) {
        return _buildQuoteBlockedView();
      } else if ((quoteEmbed.record).data is EmbedViewRecordViewNotFound) {
        return _buildQuoteDeletedView();
      }

      final quotedRecord =
          (quoteEmbed.record).data as EmbedViewRecordViewRecord;
      return _buildQuotePostView(quotedRecord);
    }

    return const SizedBox.shrink();
  }

  Widget _buildQuoteBlockedView() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 8.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Row(
          spacing: 4.0,
          children: [Icon(Icons.info_outline, size: 16.0), Text('Blocked')],
        ),
      ),
    );
  }

  Widget _buildQuoteDeletedView() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 8.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Row(
          spacing: 4.0,
          children: [Icon(Icons.info_outline, size: 16.0), Text('Deleted')],
        ),
      ),
    );
  }

  Widget _buildQuotePostView(EmbedViewRecordViewRecord quotedPost) {
    return InkWell(
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      onTap: () {
        final auth = context.read<AuthCubit>();
        final blueskyService = auth.getBlueskyService();

        blueskyService.getPost(quotedPost.uri).then((fetchedPost) {
          if (fetchedPost != null) {
            Navigator.of(context).push(
              NoBackgroundCupertinoPageRoute(
                builder:
                    (context) => PostDetailPage(
                      post: fetchedPost,
                      reply: null,
                      reason: null,
                      contentLabelPreferences: widget.contentLabelPreferences,
                    ),
              ),
            );
          }
        });
      },
      child: Container(
        margin: EdgeInsets.only(top: 8.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outline.withValues(alpha: 0.25),
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AvatarComponent(avatar: quotedPost.author.avatar, size: 20.0),
                  SizedBox(width: 8.0),
                  Flexible(
                    child: Text(
                      quotedPost.author.displayName ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: 4.0),
                  Flexible(
                    child: Text(
                      '@${quotedPost.author.handle}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.0),
              Text(quotedPost.value.text),
              _buildQuotedPostMedia(quotedPost),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuotedPostMedia(EmbedViewRecordViewRecord quotedPost) {
    if (quotedPost.embeds != null) {
      for (final embed in quotedPost.embeds!) {
        if (embed.data is EmbedViewImages) {
          final imageEmbed = embed.data as EmbedViewImages;
          return ClickableImageGrid(
            images: imageEmbed.images,
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
                        images: imageEmbed.images,
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
          final recordWithMediaEmbed = embed.data as EmbedViewRecordWithMedia;

          if (recordWithMediaEmbed.media.data is EmbedViewImages) {
            final imageEmbed =
                recordWithMediaEmbed.media.data as EmbedViewImages;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuotedRecord(recordWithMediaEmbed.record),

                ClickableImageGrid(
                  images: imageEmbed.images,
                  onImageTap: (image, index) {
                    final navController =
                        Provider.of<BottomNavVisibilityController>(
                          context,
                          listen: false,
                        );
                    navController.hide();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (context) => ImageDetailScreen(
                              images: imageEmbed.images,
                              initialIndex: index,
                              onExit: () {
                                navController.show();
                              },
                            ),
                      ),
                    );
                  },
                ),
              ],
            );
          }
        } else if (embed.data is EmbedViewExternal) {
          final external = embed.data as EmbedViewExternal;
          final url = external.external.uri;

          if (url.contains('youtube.com') || url.contains('youtu.be')) {
            final videoId = YoutubePlayer.convertUrlToId(url);
            if (videoId != null) {
              final controller = YoutubePlayerController(
                initialVideoId: videoId,
                flags: YoutubePlayerFlags(autoPlay: false),
              );

              return Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: YoutubePlayer(controller: controller),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          } else {
            return InkWell(
              splashFactory: NoSplash.splashFactory,
              splashColor: Colors.transparent,
              onTap: () {
                launchUrl(Uri.parse(url));
              },
              child: Container(
                margin: EdgeInsets.only(top: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.25),
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (external.external.thumbnail != null)
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(7.0),
                        ),
                        child: Image.network(
                          external.external.thumbnail!,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            external.external.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 4.0),
                            child: Text(
                              external.external.description,
                              style: TextStyle(
                                fontSize: 12.0,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 4.0),
                            child: Text(
                              Uri.parse(external.external.uri).host,
                              style: TextStyle(
                                fontSize: 12.0,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }
      }
    }

    return SizedBox.shrink();
  }

  Widget _buildQuotedRecord(EmbedViewRecord record) {
    if (record.record is EmbedViewRecordViewRecord) {
      final recordData = record.record as EmbedViewRecordViewRecord;
      return Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (recordData.author.avatar != null)
                  CircleAvatar(
                    backgroundImage: NetworkImage(recordData.author.avatar!),
                    radius: 16,
                  ),
                SizedBox(width: 8),
                Text(
                  recordData.author.displayName ?? recordData.author.handle,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),

            Text(recordData.value.text),
          ],
        ),
      );
    }

    return SizedBox.shrink();
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
