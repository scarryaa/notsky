import 'package:bluesky/bluesky.dart' hide Image;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_state.dart';
import 'package:notsky/features/post/presentation/components/common/avatar_component.dart';
import 'package:notsky/features/post/presentation/components/common/faceted_text_builder.dart';
import 'package:notsky/features/post/presentation/components/interaction/post_actions_component.dart';
import 'package:notsky/features/post/presentation/components/post/post_actions_handler.dart';
import 'package:notsky/features/post/presentation/components/post/post_external_content_renderer.dart';
import 'package:notsky/features/post/presentation/components/post/post_media_renderer.dart';
import 'package:notsky/features/post/presentation/components/post/quoted_post_renderer.dart';
import 'package:notsky/features/post/presentation/components/post/util/content_label_processor.dart';
import 'package:notsky/features/post/presentation/components/post/util/time_formatter.dart';
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
    final actionsHandler = PostActionsHandler(
      context: context,
      post: widget.post,
      contentLabelPreferences: widget.contentLabelPreferences,
    );

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
                        actorDid: widget.post.author.did,
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
                              onLike: () => actionsHandler.handleLike(state),
                              onRepost:
                                  () => actionsHandler.handleRepost(state),
                              onQuote: () {
                                String? avatar;
                                String? did;
                                final authState =
                                    context.read<AuthCubit>().state;
                                if (authState is AuthSuccess) {
                                  final profile = authState.profile;
                                  avatar = profile?.avatar;
                                  did = profile?.did;
                                }
                                actionsHandler.showReplyModal(
                                  userDid: did,
                                  userAvatar: avatar,
                                  isQuotePosting: true,
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
                                actionsHandler.showReplyModal(
                                  userAvatar: avatar,
                                );
                              },
                              onMore: () => actionsHandler.showMoreOptions(),
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
      TimeFormatter.getRelativeTime(widget.post.indexedAt),
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
        if (widget.post.record.text.isNotEmpty)
          FacetedTextBuilder.build(
            context,
            widget.post.record.text,
            widget.post.record.facets,
            fontSize: 14.0,
          ),

        if (contentVisibility.shouldWarn)
          _buildContentGate(contentVisibility)
        else
          PostMediaRenderer.build(context, widget.post),
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
          PostMediaRenderer.build(context, widget.post),
      ],
    );
  }
}
