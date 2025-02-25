import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:notsky/features/feed/presentation/cubits/feed_cubit.dart';
import 'package:notsky/features/feed/presentation/cubits/feed_state.dart';
import 'package:notsky/features/post/presentation/components/base_post_component.dart';
import 'package:notsky/features/post/presentation/cubits/post_cubit.dart';

class FeedComponent extends StatelessWidget {
  const FeedComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => FeedCubit(
            context.read<AuthCubit>().state,
            context.read<AuthCubit>(),
          )..loadFeed(),
      child: BlocBuilder<FeedCubit, FeedState>(
        builder: (context, state) {
          if (state is FeedLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is FeedLoaded) {
            return RefreshIndicator(
              child: ListView.separated(
                itemBuilder: (context, index) {
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
                itemCount: state.feeds.feed.length,
                separatorBuilder:
                    (context, index) => Divider(
                      height: 1.0,
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.25),
                    ),
              ),
              onRefresh: () {
                return context.read<FeedCubit>().loadFeed();
              },
            );
          } else if (state is FeedError) {
            return RefreshIndicator(
              child: Center(child: Text('Error: ${state.message}')),
              onRefresh: () {
                return context.read<FeedCubit>().loadFeed();
              },
            );
          }
          return RefreshIndicator(
            onRefresh: () {
              return context.read<FeedCubit>().loadFeed();
            },
            child: Center(child: Text('No feed available')),
          );
        },
      ),
    );
  }
}
