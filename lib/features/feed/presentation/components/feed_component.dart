import 'package:atproto_core/atproto_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_cubit.dart';
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
                  if (index == state.feeds.feed.length) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final feedItem = state.feeds.feed[index];
                  return BlocProvider(
                    create:
                        (context) => PostCubit(
                          context.read<AuthCubit>().getBlueskyService(),
                        ),
                    child: BasePostComponent(
                      post: feedItem.post,
                      reason: feedItem.reason,
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
