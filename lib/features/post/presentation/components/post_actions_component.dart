import 'package:flutter/material.dart';

class PostActionsComponent extends StatelessWidget {
  const PostActionsComponent({
    super.key,
    this.iconSize = 18.0,
    this.indentEnd = true,
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

  final double iconSize;
  final bool indentEnd;
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
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildActionButton(
          context,
          onPressed: () {},
          icon: Icons.chat_bubble_outline,
          metric: replyCount,
          iconAlignment: Alignment.centerLeft,
          mainAxisAlignment: MainAxisAlignment.start,
          isFirst: true,
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
          iconAlignment: Alignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
        ),
        _buildActionButton(
          context,
          onPressed: onLike,
          icon: likedByViewer ? Icons.favorite : Icons.favorite_outline,
          metric: likeCount,
          color: likedByViewer ? Colors.red : null,
          iconAlignment: Alignment.center,
          mainAxisAlignment: MainAxisAlignment.end,
        ),
        _buildActionButton(
          context,
          onPressed: () {},
          icon: Icons.more_horiz,
          iconAlignment: Alignment.centerRight,
          mainAxisAlignment: MainAxisAlignment.end,
        ),
        if (indentEnd) SizedBox(width: 10.0),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required void Function() onPressed,
    required IconData icon,
    bool isFirst = false,
    Color? color,
    int? metric,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.center,
    Alignment iconAlignment = Alignment.center,
  }) {
    return SizedBox(
      width: 65.0,
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: isFirst ? Offset(-5, 0) : Offset.zero,
            child: IconButton(
              onPressed: onPressed,
              icon: Icon(icon, size: iconSize),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
              style: ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          if (metric != null)
            SizedBox(
              width: 30,
              child: Transform.translate(
                offset: isFirst ? Offset(-5, -1) : Offset(0, -1),
                child: Text(
                  metric > 0 ? _formatCount(metric) : '',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: iconSize - 6.0,
                    fontWeight:
                        color != null ? FontWeight.bold : FontWeight.normal,
                    color:
                        color ?? Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
