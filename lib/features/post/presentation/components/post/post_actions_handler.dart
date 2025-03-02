import 'package:bluesky/bluesky.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:notsky/features/post/presentation/components/interaction/reply_component.dart';
import 'package:notsky/features/post/presentation/components/post/util/content_label_processor.dart';
import 'package:notsky/features/post/presentation/cubits/post_cubit.dart';
import 'package:notsky/features/post/presentation/cubits/post_state.dart';

class PostActionsHandler {
  final BuildContext context;
  final Post post;
  final List<ContentLabelPreference> contentLabelPreferences;

  PostActionsHandler({
    required this.context,
    required this.post,
    required this.contentLabelPreferences,
  });

  Future<void> handleLike(PostState state) async {
    final newLikeCount =
        (state.likeCount ?? post.likeCount) + (state.isLiked ? -1 : 1);

    await context.read<PostCubit>().toggleLike(post.cid, post.uri);

    context.read<PostCubit>().updateLikeCount(newLikeCount);
  }

  Future<void> handleRepost(PostState state) async {
    final currentRepostCount =
        state.repostCount ?? (post.repostCount + post.quoteCount);
    final newRepostCount = currentRepostCount + (state.isReposted ? -1 : 1);

    await context.read<PostCubit>().toggleRepost(post.cid, post.uri);

    context.read<PostCubit>().updateRepostCount(newRepostCount);
  }

  void showReplyModal({String? userAvatar}) {
    final contentVisibility = ContentLabelProcessor.processLabels(
      post.labels,
      contentLabelPreferences,
    );

    showModalBottomSheet(
      isScrollControlled: true,
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height - 250,
        maxHeight: MediaQuery.of(context).size.height - 250,
      ),
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
      ),
      builder:
          (context) => ReplyComponent(
            hideOrWarn:
                contentVisibility.shouldHide || contentVisibility.shouldWarn,
            onCancel: () {
              Navigator.pop(context);
            },
            onReply: (String text) {
              final auth = context.read<AuthCubit>();
              final blueskyService = auth.getBlueskyService();

              blueskyService.reply(
                text,
                rootCid: post.record.reply?.root.cid ?? post.cid,
                rootUri: post.record.reply?.root.uri ?? post.uri,
                parentCid: post.cid,
                parentUri: post.uri,
              );
              Navigator.of(context).pop();
            },
            replyPost: post,
            userAvatar: userAvatar,
          ),
    );
  }

  void showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            // TODO: Implement more options
          ),
    );
  }
}
