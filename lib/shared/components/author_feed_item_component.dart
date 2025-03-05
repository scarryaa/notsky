import 'package:bluesky/bluesky.dart' hide Image;
import 'package:flutter/material.dart';

class AuthorFeedItemComponent extends StatelessWidget {
  const AuthorFeedItemComponent({
    super.key,
    required this.feed,
    this.onTap,
    this.onSubscribe,
    this.isSubscribed = false,
    this.formatNumber = _defaultFormatNumber,
  });

  final FeedGeneratorView feed;
  final VoidCallback? onTap;
  final VoidCallback? onSubscribe;
  final bool isSubscribed;
  final String Function(int) formatNumber;

  static String _defaultFormatNumber(int number) => number.toString();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsetsDirectional.only(top: 4.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child:
                    feed.avatar != null
                        ? Image.network(
                          feed.avatar!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        )
                        : Container(
                          width: 40,
                          height: 40,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.rss_feed, size: 24),
                        ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feed.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Feed by @${feed.createdBy.handle}',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (feed.description != null && feed.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        feed.description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${formatNumber(feed.likeCount)} likes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onSubscribe,
              icon: Icon(
                isSubscribed ? Icons.push_pin : Icons.add,
                color:
                    isSubscribed
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                size: 22,
              ),
              tooltip: isSubscribed ? 'Subscribed' : 'Subscribe to feed',
            ),
          ],
        ),
      ),
    );
  }
}
