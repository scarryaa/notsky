import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:notsky/features/feed/presentation/cubits/feed_cubit.dart';
import 'package:notsky/features/feed/presentation/cubits/feed_state.dart';
import 'package:notsky/features/post/presentation/components/post_component.dart';

class FeedComponent extends StatelessWidget {
  const FeedComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => FeedCubit(context.read<AuthCubit>().state)..loadFeed(),
      child: BlocBuilder<FeedCubit, FeedState>(
        builder: (context, state) {
          if (state is FeedLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is FeedLoaded) {
            return ListView.separated(
              itemBuilder:
                  (context, index) =>
                      PostComponent(post: state.feeds.feed[index].post),
              itemCount: state.feeds.feed.length,
              separatorBuilder: (context, index) => Divider(),
            );
          } else if (state is FeedError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return Center(child: Text('No feed available'));
        },
      ),
    );
  }
}
