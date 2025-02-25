import 'package:bluesky/bluesky.dart' hide Image;
import 'package:flutter/material.dart';
import 'package:notsky/features/post/presentation/components/post_actions_component.dart';

class PostComponent extends StatelessWidget {
  const PostComponent({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // TODO post detail view
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Row(
          spacing: 8.0,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipOval(
              child: Image.network(
                post.author.avatar ?? '',
                width: 40,
                height: 40,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    spacing: 4.0,
                    children: [
                      Flexible(
                        flex: 1,
                        child: Text(
                          post.author.displayName ?? '',
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          post.author.handle,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Text('•'),
                      Text(
                        getRelativeTime(post.indexedAt),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: Text(post.record.text, softWrap: true)),
                    ],
                  ),
                  PostActionsComponent(
                    likeCount: post.likeCount,
                    replyCount: post.replyCount,
                    repostCount: post.repostCount + post.quoteCount,
                    repostedByViewer: post.viewer.isReposted,
                    likedByViewer: post.viewer.isLiked,
                    // TODO post actions
                    onLike: () {},
                    onReply: () {},
                    onMore: () {},
                    onRepost: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo';
    } else {
      return '${(difference.inDays / 365).floor()}y';
    }
  }
}
