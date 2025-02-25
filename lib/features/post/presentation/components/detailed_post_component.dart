import 'package:bluesky/bluesky.dart' hide Image;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:notsky/features/post/presentation/components/avatar_component.dart';
import 'package:notsky/features/post/presentation/components/post_actions_component.dart';
import 'package:notsky/features/post/presentation/cubits/post_cubit.dart';
import 'package:notsky/features/post/presentation/cubits/post_state.dart';

class DetailedPostComponent extends StatelessWidget {
  const DetailedPostComponent({super.key, required this.post});

  final Post post;

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
                      AvatarComponent(avatar: post.author.avatar, size: 40.0),
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
                      _buildPostContent(context),
                      SizedBox(height: 6.0),
                      _buildIndexedAt(context),
                      SizedBox(height: 8.0),
                      _buildStats(context),
                      SizedBox(height: 4.0),
                      PostActionsComponent(
                        iconSize: 20.0,
                        indentEnd: false,
                        likeCount: state.likeCount ?? post.likeCount,
                        replyCount: post.replyCount,
                        repostCount:
                            state.repostCount ??
                            (post.repostCount + post.quoteCount),
                        repostedByViewer: state.isReposted,
                        likedByViewer: state.isLiked,
                        // TODO post actions
                        onLike: () async {
                          final newLikeCount =
                              (state.likeCount ?? post.likeCount) +
                              (state.isLiked ? -1 : 1);

                          await context.read<PostCubit>().toggleLike(
                            post.cid,
                            post.uri,
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
                              (post.repostCount + post.quoteCount);
                          final newRepostCount =
                              currentRepostCount + (state.isReposted ? -1 : 1);

                          await context.read<PostCubit>().toggleRepost(
                            post.cid,
                            post.uri,
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

  Widget _buildDisplayName() {
    return Flexible(
      flex: 1,
      child: Text(
        post.author.displayName ?? '',
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Flexible(
      child: Text(
        '@${post.author.handle}',
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildPostContent(BuildContext context) {
    return Text(
      post.record.text,
      softWrap: true,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 15.0,
      ),
    );
  }

  Widget _buildIndexedAt(BuildContext context) {
    return Text(
      formatTime(post.indexedAt),
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 12.0,
      ),
    );
  }

  String formatTime(DateTime indexedAt) {
    return DateFormat('MMMM d, yyyy \'at\' h:mm a').format(indexedAt);
  }

  Widget _buildStats(BuildContext context) {
    return Container(
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
        child: Row(children: [Text('1 like')]),
      ),
    );
  }
}
