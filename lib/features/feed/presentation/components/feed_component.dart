import 'package:atproto_core/atproto_core.dart';
import 'package:bluesky/bluesky.dart' hide ListView;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:notsky/features/feed/presentation/components/dashed_line_painter.dart';
import 'package:notsky/features/feed/presentation/cubits/feed_cubit.dart';
import 'package:notsky/features/feed/presentation/cubits/feed_state.dart';
import 'package:notsky/features/post/presentation/components/base_post_component.dart';
import 'package:notsky/features/post/presentation/cubits/post_cubit.dart';

class FeedComponent extends StatefulWidget {
  final bool isTimeline;
  final AtUri? generatorUri;

  const FeedComponent({this.isTimeline = false, this.generatorUri, super.key})
    : assert(
        isTimeline || generatorUri != null,
        'Either isTimeline must be true or generatorUri must be provided',
      );

  @override
  State<FeedComponent> createState() => _FeedComponentState();
}

class _FeedComponentState extends State<FeedComponent> {
  final ScrollController _scrollController = ScrollController();
  late FeedCubit _feedCubit;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
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

        _scrollController.addListener(_onScroll);

        return _feedCubit;
      },
      child: BlocBuilder<FeedCubit, FeedState>(
        builder: (context, state) {
          if (state is FeedLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is FeedLoaded) {
            return RefreshIndicator(
              child: ListView.separated(
                controller: _scrollController,
                itemBuilder: (context, index) {
                  final feedItem = state.feeds.feed[index];

                  if (index == state.feeds.feed.length) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  return BlocProvider(
                    create:
                        (context) => PostCubit(
                          context.read<AuthCubit>().getBlueskyService(),
                        ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (feedItem.reply != null) ...[
                          if (feedItem.post.record.reply?.root.uri !=
                              (feedItem.reply!.parent.data as Post).uri)
                            Stack(
                              children: [
                                // Root post
                                BasePostComponent(
                                  post: feedItem.reply!.root.data as Post,
                                  reason: feedItem.reason,
                                  reply: feedItem.reply,
                                ),
                                if (feedItem.post.record.reply?.root.uri !=
                                    (feedItem.reply?.parent.data as Post)
                                        .record
                                        .reply
                                        ?.parent
                                        .uri)
                                  Positioned(
                                    left: 27,
                                    top: 56,
                                    bottom: 0,
                                    width: 2,
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        return CustomPaint(
                                          size: Size(2, constraints.maxHeight),
                                          painter: DashedLinePainter(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline
                                                .withValues(alpha: 0.25),
                                            dashLength: 4,
                                            dashGap: 4,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                else
                                  Positioned(
                                    left: 27,
                                    top: 56,
                                    bottom: 0,
                                    width: 2,
                                    child: Container(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withValues(alpha: 0.25),
                                    ),
                                  ),
                              ],
                            ),
                          if (feedItem.post.record.reply?.root.uri !=
                              (feedItem.reply!.parent.data as Post).uri)
                            if (feedItem.post.record.reply?.root.uri !=
                                (feedItem.reply?.parent.data as Post)
                                    .record
                                    .reply
                                    ?.parent
                                    .uri)
                              Row(
                                children: [
                                  SizedBox(width: 60.0),
                                  GestureDetector(
                                    onTap: () {
                                      // TODO show full thread
                                    },
                                    child: Text(
                                      'View full thread',
                                      style: TextStyle(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          // Parent post
                          Stack(
                            children: [
                              BasePostComponent(
                                post: feedItem.reply!.parent.data as Post,
                                reason: feedItem.reason,
                                reply: feedItem.reply,
                              ),
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
                            ],
                          ),
                        ],
                        // Reply post
                        BasePostComponent(
                          post: feedItem.post,
                          reason: feedItem.reason,
                          reply: feedItem.reply,
                        ),
                      ],
                    ),
                  );
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
                return context.read<FeedCubit>().loadFeed(
                  generatorUri: widget.isTimeline ? null : widget.generatorUri,
                );
              },
            );
          } else if (state is FeedError) {
            return RefreshIndicator(
              child: Center(child: Text('Error: ${state.message}')),
              onRefresh: () {
                return context.read<FeedCubit>().loadFeed(
                  generatorUri: widget.isTimeline ? null : widget.generatorUri,
                );
              },
            );
          }
          return RefreshIndicator(
            onRefresh: () {
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
