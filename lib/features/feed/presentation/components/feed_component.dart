import 'package:atproto_core/atproto_core.dart';
import 'package:bluesky/bluesky.dart' hide ListView;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:notsky/features/feed/presentation/cubits/feed_cubit.dart';
import 'package:notsky/features/feed/presentation/cubits/feed_state.dart';
import 'package:notsky/features/post/domain/entities/post_content.dart';
import 'package:notsky/features/post/presentation/components/post/base_post_component.dart';
import 'package:notsky/features/post/presentation/cubits/post_cubit.dart';
import 'package:notsky/features/thread/presentation/components/thread_component.dart';

class FeedComponent extends StatefulWidget {
  final bool isTimeline;
  final AtUri? generatorUri;
  final ScrollController scrollController;
  final VoidCallback? onRefresh;

  const FeedComponent({
    this.isTimeline = false,
    this.generatorUri,
    super.key,
    required this.scrollController,
    this.onRefresh,
  }) : assert(
         isTimeline || generatorUri != null,
         'Either isTimeline must be true or generatorUri must be provided',
       );

  @override
  State<FeedComponent> createState() => FeedComponentState();
}

class FeedComponentState extends State<FeedComponent> {
  late FeedCubit _feedCubit;

  String? getLatestPostId() {
    final state = _feedCubit.state;
    if (state is FeedLoaded && state.feeds.feed.isNotEmpty) {
      return state.feeds.feed.first.post.cid.toString();
    }
    return null;
  }

  void refreshFeed() {
    if (mounted) {
      _feedCubit.loadFeed(
        generatorUri: widget.isTimeline ? null : widget.generatorUri,
      );

      if (widget.onRefresh != null) {
        widget.onRefresh!();
      }
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = widget.scrollController.position.maxScrollExtent;
    final currentScroll = widget.scrollController.position.pixels;
    const delta = 200.0;

    if (maxScroll - currentScroll <= delta) {
      _feedCubit.loadMoreFeed(
        generatorUri: widget.isTimeline ? null : widget.generatorUri,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        _feedCubit = FeedCubit(context.read<AuthCubit>().getBlueskyService())
          ..loadFeed(
            generatorUri: widget.isTimeline ? null : widget.generatorUri,
          );

        widget.scrollController.addListener(_onScroll);

        return _feedCubit;
      },
      child: BlocBuilder<FeedCubit, FeedState>(
        builder: (context, state) {
          if (state is FeedLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is FeedLoaded) {
            return RefreshIndicator(
              child: ListView.separated(
                controller: widget.scrollController,
                itemBuilder: (context, index) {
                  final feedItem = state.feeds.feed.elementAtOrNull(index);

                  if (index == state.feeds.feed.length) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (feedItem != null) {
                    return BlocProvider(
                      create:
                          (context) => PostCubit(
                            context.read<AuthCubit>().getBlueskyService(),
                          ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ThreadComponent(
                            feedItem: feedItem,
                            contentLabelPreferences:
                                context
                                    .read<FeedCubit>()
                                    .contentLabelPreferences,
                          ),
                          // Reply post
                          BasePostComponent(
                            postContent: RegularPost(feedItem.post),
                            reason: feedItem.reason,
                            reply: feedItem.reply,
                            isReplyToMissingPost:
                                feedItem.reply?.parent.data is NotFoundPost,
                            isReplyToBlockedPost:
                                feedItem.reply?.parent.data is BlockedPost,
                            contentLabelPreferences:
                                context
                                    .read<FeedCubit>()
                                    .contentLabelPreferences,
                          ),
                        ],
                      ),
                    );
                  }
                  return null;
                },
                itemCount:
                    state.feeds.feed.length + (state.isLoadingMore ? 1 : 0),
                separatorBuilder:
                    (context, index) => Divider(
                      height: 1.0,
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.25),
                    ),
              ),
              onRefresh: () {
                if (widget.onRefresh != null) {
                  widget.onRefresh!();
                }

                return context.read<FeedCubit>().loadFeed(
                  generatorUri: widget.isTimeline ? null : widget.generatorUri,
                );
              },
            );
          } else if (state is FeedError) {
            return RefreshIndicator(
              child: Center(child: Text('Error: ${state.message}')),
              onRefresh: () {
                if (widget.onRefresh != null) {
                  widget.onRefresh!();
                }

                return context.read<FeedCubit>().loadFeed(
                  generatorUri: widget.isTimeline ? null : widget.generatorUri,
                );
              },
            );
          }
          return RefreshIndicator(
            onRefresh: () {
              if (widget.onRefresh != null) {
                widget.onRefresh!();
              }

              return context.read<FeedCubit>().loadFeed(
                generatorUri: widget.isTimeline ? null : widget.generatorUri,
              );
            },
            child: Center(child: Text('No feed available')),
          );
        },
      ),
    );
  }
}
