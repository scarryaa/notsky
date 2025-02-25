import 'package:bluesky/bluesky.dart' hide Image;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/post/presentation/components/post_actions_component.dart';
import 'package:notsky/features/post/presentation/cubits/post_cubit.dart';
import 'package:notsky/features/post/presentation/cubits/post_state.dart';

class PostComponent extends StatefulWidget {
  const PostComponent({super.key, required this.post});

  final Post post;

  @override
  State<PostComponent> createState() => _PostComponentState();
}

class _PostComponentState extends State<PostComponent> {
  @override
  void initState() {
    super.initState();
    context.read<PostCubit>().initializePost(
      widget.post.viewer.isLiked,
      widget.post.viewer.like,
      widget.post.viewer.isReposted,
      widget.post.viewer.repost,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostCubit, PostState>(
      builder:
          (context, state) => InkWell(
            onTap: () {
              // TODO post detail view
            },
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              child: Row(
                spacing: 8.0,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipOval(
                    child: Image.network(
                      widget.post.author.avatar ?? '',
                      width: 40,
                      height: 40,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          spacing: 4.0,
                          children: [
                            Flexible(
                              flex: 1,
                              child: Text(
                                widget.post.author.displayName ?? '',
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                widget.post.author.handle,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Text('•'),
                            Text(
                              getRelativeTime(widget.post.indexedAt),
                              style: TextStyle(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.post.record.text,
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                        PostActionsComponent(
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
            ),
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
