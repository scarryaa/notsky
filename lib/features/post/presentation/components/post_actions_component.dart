import 'package:flutter/material.dart';

class PostActionsComponent extends StatelessWidget {
  const PostActionsComponent({
    super.key,
    required this.likeCount,
    required this.repostCount,
    required this.replyCount,
    required this.repostedByViewer,
    required this.likedByViewer,
    required this.onLike,
    required this.onReply,
    required this.onRepost,
    required this.onMore,
  });

  final int likeCount;
  final int repostCount;
  final int replyCount;
  final bool repostedByViewer;
  final bool likedByViewer;
  final void Function() onReply;
  final void Function() onRepost;
  final void Function() onLike;
  final void Function() onMore;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(-10.0, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionButton(
            context,
            onPressed: () {},
            icon: Icons.chat_bubble_outline,
            metric: replyCount,
          ),
          _buildActionButton(
            context,
            onPressed: onRepost,
            icon: Icons.repeat,
            metric: repostCount,
            color:
                repostedByViewer
                    ? Theme.of(context).brightness == Brightness.light
                        ? Colors.green[700]!
                        : Colors.green
                    : null,
          ),
          _buildActionButton(
            context,
            onPressed: onLike,
            icon: likedByViewer ? Icons.favorite : Icons.favorite_outline,
            metric: likeCount,
            color: likedByViewer ? Colors.red : null,
          ),
          _buildActionButton(context, onPressed: () {}, icon: Icons.more_horiz),
          SizedBox(width: 10.0),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required void Function() onPressed,
    required IconData icon,
    Color? color,
    int? metric,
  }) {
    return SizedBox(
      width: 80.0,
      child: Row(
        children: [
          IconButton(
            onPressed: onPressed,
            icon: Icon(icon, size: 18.0),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          if (metric != null)
            SizedBox(
              width: 32.0,
              child: Text(
                metric > 0 ? _formatCount(metric) : '',
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight:
                      color != null ? FontWeight.bold : FontWeight.normal,
                  color:
                      color ?? Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 10000) {
      // 1,000-9,999
      double formattedCount = count / 1000;
      return '${formattedCount.toStringAsFixed(1)}k'.replaceAll('.0k', 'k');
    } else if (count < 1000000) {
      // 10,000-999,999
      return '${(count / 1000).round()}k';
    } else {
      // 1,000,000+
      double formattedCount = count / 1000000;
      return '${formattedCount.toStringAsFixed(1)}M'.replaceAll('.0M', 'M');
    }
  }
}
