import 'package:bluesky/bluesky.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:notsky/features/post/presentation/components/base_post_component.dart';
import 'package:notsky/features/post/presentation/cubits/post_cubit.dart';

class PostDetailPage extends StatelessWidget {
  const PostDetailPage({super.key, required this.post, required this.reason});

  final Post post;
  final Reason? reason;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => PostCubit(context.read<AuthCubit>().getBlueskyService()),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size(double.infinity, 60.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.25),
                ),
              ),
            ),
            child: AppBar(
              backgroundColor: Theme.of(context).colorScheme.surface,
              scrolledUnderElevation: 0,
              actions: [
                // TODO
              ],
              title: Text('Post'),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              BasePostComponent(post: post, reason: reason, detailed: true),
            ],
          ),
        ),
      ),
    );
  }
}
