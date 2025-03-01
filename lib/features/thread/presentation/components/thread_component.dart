import 'package:bluesky/bluesky.dart';
import 'package:flutter/material.dart';
import 'package:notsky/features/feed/presentation/components/dashed_line_painter.dart';
import 'package:notsky/features/post/domain/entities/post_content.dart';
import 'package:notsky/features/post/presentation/components/base_post_component.dart';
import 'package:notsky/features/post/presentation/pages/post_detail_page.dart';
import 'package:notsky/shared/components/no_background_cupertino_page_route.dart';

class ThreadComponent extends StatelessWidget {
  final FeedView feedItem;
  final List<ContentLabelPreference> contentLabelPreferences;

  const ThreadComponent({
    super.key,
    required this.feedItem,
    required this.contentLabelPreferences,
  });

  Widget _buildBlockedPostComponent(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          padding: const EdgeInsets.only(
            left: 8.0,
            right: 8.0,
            top: 6.0,
            bottom: 10.0,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                ),
                child: Icon(
                  Icons.person_outline,
                  size: 24,
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username placeholder
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.15),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Content placeholder
                    Row(
                      children: [
                        Text(
                          'Blocked post',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 27,
          top: 56,
          bottom: 0,
          width: 2,
          child: Container(
            color: Theme.of(
              context,
            ).colorScheme.outline.withValues(alpha: 0.25),
          ),
        ),
      ],
    );
  }

  Widget _buildDeletedPostComponent(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          padding: const EdgeInsets.only(
            left: 8.0,
            right: 8.0,
            top: 6.0,
            bottom: 10.0,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                ),
                child: Icon(
                  Icons.person_outline,
                  size: 24,
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username placeholder
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.15),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Content placeholder
                    Row(
                      children: [
                        Text(
                          'Deleted post',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 27,
          top: 56,
          bottom: 0,
          width: 2,
          child: Container(
            color: Theme.of(
              context,
            ).colorScheme.outline.withValues(alpha: 0.25),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (feedItem.reply == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (feedItem.reply!.parent.data is NotFoundPost)
          BasePostComponent(
            postContent: MissingPost(feedItem.reply!.root.data as NotFoundPost),
            reason: feedItem.reason,
            reply: feedItem.reply,
            contentLabelPreferences: contentLabelPreferences,
          )
        else if (feedItem.reply!.parent.data is BlockedPost)
          _buildBlockedPostComponent(context)
        else if (feedItem.post.record.reply?.root.uri !=
            (feedItem.reply!.parent.data as Post).uri)
          Stack(
            children: [
              // Root post
              if (feedItem.reply!.root.data is Post)
                BasePostComponent(
                  postContent: RegularPost(feedItem.reply!.root.data as Post),
                  reason: feedItem.reason,
                  reply: feedItem.reply,
                  contentLabelPreferences: contentLabelPreferences,
                )
              else if (feedItem.reply!.root.data is NotFoundPost)
                _buildDeletedPostComponent(context),
              if (feedItem.post.record.reply?.root.uri !=
                  (feedItem.reply?.parent.data as Post)
                      .record
                      .reply
                      ?.parent
                      .uri)
                Positioned(
                  left: 27,
                  top: 56,
                  bottom: 0,
                  width: 2,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return CustomPaint(
                        size: Size(2, constraints.maxHeight),
                        painter: DashedLinePainter(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.25),
                          dashLength: 4,
                          dashGap: 4,
                        ),
                      );
                    },
                  ),
                )
              else
                Positioned(
                  left: 27,
                  top: 56,
                  bottom: 0,
                  width: 2,
                  child: Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.25),
                  ),
                ),
            ],
          ),

        if (feedItem.reply!.parent.data is! NotFoundPost &&
            feedItem.reply!.parent.data is! BlockedPost &&
            feedItem.post.record.reply?.root.uri !=
                (feedItem.reply!.parent.data as Post).uri &&
            feedItem.post.record.reply?.root.uri !=
                (feedItem.reply?.parent.data as Post).record.reply?.parent.uri)
          Padding(
            padding: const EdgeInsets.only(left: 60.0, top: 4.0, bottom: 4.0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  NoBackgroundCupertinoPageRoute(
                    builder:
                        (context) => PostDetailPage(
                          post: feedItem.reply?.root.data as Post,
                          reply: feedItem.reply,
                          reason: feedItem.reason,
                          contentLabelPreferences: contentLabelPreferences,
                        ),
                  ),
                );
              },
              child: Text(
                'View full thread',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ),

        // Parent post
        Stack(
          children: [
            if (feedItem.reply!.parent.data is NotFoundPost)
              BasePostComponent(
                postContent: MissingPost(
                  feedItem.reply!.parent.data as NotFoundPost,
                ),
                reason: feedItem.reason,
                reply: feedItem.reply,
                contentLabelPreferences: contentLabelPreferences,
              )
            else if (feedItem.reply!.parent.data is BlockedPost)
              SizedBox.shrink()
            else
              BasePostComponent(
                postContent: RegularPost(feedItem.reply!.parent.data as Post),
                reason: null,
                reply: feedItem.reply,
                contentLabelPreferences: contentLabelPreferences,
              ),
            Positioned(
              left: 27,
              top: 56,
              bottom: 0,
              width: 2,
              child: Container(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
