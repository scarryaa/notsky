import 'package:bluesky/bluesky.dart';
import 'package:flutter/widgets.dart';
import 'package:notsky/features/post/presentation/components/detailed_post_component.dart';
import 'package:notsky/features/post/presentation/components/post_component.dart';

class BasePostComponent extends StatelessWidget {
  const BasePostComponent({
    super.key,
    required this.post,
    required this.reason,
    this.detailed = false,
  });

  final Post post;
  final Reason? reason;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    return detailed
        ? DetailedPostComponent(post: post)
        : PostComponent(post: post, reason: reason);
  }
}
