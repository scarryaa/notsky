import 'package:bluesky/bluesky.dart' hide Image, ListView;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_state.dart';
import 'package:notsky/features/post/domain/entities/post_content.dart';
import 'package:notsky/features/post/presentation/components/common/avatar_component.dart';
import 'package:notsky/features/post/presentation/components/common/faceted_text_builder.dart';
import 'package:notsky/features/post/presentation/components/interaction/post_actions_component.dart';
import 'package:notsky/features/post/presentation/components/post/base_post_component.dart';
import 'package:notsky/features/post/presentation/components/post/post_actions_handler.dart';
import 'package:notsky/features/post/presentation/components/post/post_external_content_renderer.dart';
import 'package:notsky/features/post/presentation/components/post/post_media_renderer.dart';
import 'package:notsky/features/post/presentation/components/post/quoted_post_renderer.dart';
import 'package:notsky/features/post/presentation/components/post/util/content_label_processor.dart';
import 'package:notsky/features/post/presentation/components/post/util/time_formatter.dart';
import 'package:notsky/features/post/presentation/cubits/post_cubit.dart';
import 'package:notsky/features/post/presentation/cubits/post_state.dart';

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
    final actionsHandler = PostActionsHandler(
      context: context,
      post: widget.post,
      contentLabelPreferences: widget.contentLabelPreferences,
    );

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
                            actorDid: widget.post.author.did,
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
                            onLike: () => actionsHandler.handleLike(state),
                            onRepost: () => actionsHandler.handleRepost(state),
                            onQuote: () {
                              String? avatar;
                              final authState = context.read<AuthCubit>().state;
                              if (authState is AuthSuccess) {
                                final profile = authState.profile;
                                avatar = profile?.avatar;
                              }
                              actionsHandler.showReplyModal(
                                userAvatar: avatar,
                                isQuotePosting: true,
                              );
                            },
                            onReply: () {
                              String? avatar;
                              final authState = context.read<AuthCubit>().state;
                              if (authState is AuthSuccess) {
                                final profile = authState.profile;
                                avatar = profile?.avatar;
                              }
                              actionsHandler.showReplyModal(userAvatar: avatar);
                            },
                            onMore: () => actionsHandler.showMoreOptions(),
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
    final contentVisibility = ContentLabelProcessor.processLabels(
      widget.post.labels,
      widget.contentLabelPreferences,
    );

    if (contentVisibility.shouldHide) {
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
        FacetedTextBuilder.build(
          context,
          widget.post.record.text,
          widget.post.record.facets,
          fontSize: 16.5,
        ),

        if (contentVisibility.shouldWarn)
          _buildContentGate(contentVisibility)
        else
          PostMediaRenderer.build(context, widget.post, detailed: true),
        PostExternalContentRenderer.buildExternal(context, widget.post),
        QuotedPostRenderer.buildQuotedPost(
          context,
          widget.post,
          widget.contentLabelPreferences,
        ),
      ],
    );
  }

  Widget _buildContentGate(ContentVisibility contentVisibility) {
    return Column(
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
                  contentVisibility.warningLabels.join(', '),
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
        if (_mediaContentExpanded)
          PostMediaRenderer.build(context, widget.post, detailed: true),
      ],
    );
  }

  Widget _buildIndexedAt(BuildContext context) {
    return Text(
      TimeFormatter.formatTimeToExpanded(widget.post.indexedAt),
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 12.0,
      ),
    );
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
