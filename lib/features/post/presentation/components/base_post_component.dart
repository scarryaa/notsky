import 'package:bluesky/bluesky.dart';
import 'package:flutter/widgets.dart';
import 'package:notsky/features/post/domain/entities/post_content.dart';
import 'package:notsky/features/post/presentation/components/detailed_post_component.dart';
import 'package:notsky/features/post/presentation/components/not_found_post_component.dart';
import 'package:notsky/features/post/presentation/components/post_component.dart';

class BasePostComponent extends StatelessWidget {
  const BasePostComponent({
    super.key,
    required this.postContent,
    this.reason,
    this.reply,
    this.detailed = false,
  });

  final PostContent postContent;
  final Reason? reason;
  final Reply? reply;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    return switch (postContent) {
      RegularPost(post: final post) =>
        detailed
            ? DetailedPostComponent(post: post)
            : PostComponent(post: post, reason: reason, reply: reply),
      MissingPost() => NotFoundPostComponent(),
    };
  }
}
