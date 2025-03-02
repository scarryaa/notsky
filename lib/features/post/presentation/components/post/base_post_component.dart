import 'package:bluesky/bluesky.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:notsky/features/post/domain/entities/post_content.dart';
import 'package:notsky/features/post/presentation/components/post/blocked_post_component.dart';
import 'package:notsky/features/post/presentation/components/post/detailed_post_component.dart';
import 'package:notsky/features/post/presentation/components/post/not_found_post_component.dart';
import 'package:notsky/features/post/presentation/components/post/post_component.dart';
import 'package:notsky/features/post/presentation/cubits/post_cubit.dart';

class BasePostComponent extends StatelessWidget {
  const BasePostComponent({
    super.key,
    required this.postContent,
    required this.contentLabelPreferences,
    this.reason,
    this.reply,
    this.detailed = false,
    this.isReplyToMissingPost = false,
    this.isReplyToBlockedPost = false,
  });

  final PostContent postContent;
  final Reason? reason;
  final Reply? reply;
  final bool detailed;
  final bool isReplyToMissingPost;
  final bool isReplyToBlockedPost;
  final List<ContentLabelPreference> contentLabelPreferences;

  @override
  Widget build(BuildContext context) {
    return switch (postContent) {
      BlockPost() => BlockedPostComponent(),
      MissingPost() => NotFoundPostComponent(),
      RegularPost(post: final post) => BlocProvider(
        create:
            (context) =>
                PostCubit(context.read<AuthCubit>().getBlueskyService()),
        child:
            detailed
                ? DetailedPostComponent(
                  post: post,
                  contentLabelPreferences: contentLabelPreferences,
                )
                : PostComponent(
                  post: post,
                  reason: reason,
                  reply: reply,
                  isReplyToMissingPost: isReplyToMissingPost,
                  isReplyToBlockedPost: isReplyToBlockedPost,
                  contentLabelPreferences: contentLabelPreferences,
                ),
      ),
    };
  }
}
