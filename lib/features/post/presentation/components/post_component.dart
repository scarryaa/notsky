import 'package:bluesky/bluesky.dart';
import 'package:flutter/widgets.dart';

class PostComponent extends StatelessWidget {
  const PostComponent({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Container(child: Text(post.record.text));
  }
}
