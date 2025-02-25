import 'package:bluesky/bluesky.dart';
import 'package:flutter/widgets.dart';
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
      child: BasePostComponent(post: post, reason: reason, detailed: true),
    );
  }
}
