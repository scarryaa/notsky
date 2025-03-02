import 'package:bluesky/bluesky.dart' hide Image;
import 'package:flutter/material.dart' hide ListView;
import 'package:notsky/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:notsky/features/post/presentation/components/common/avatar_component.dart';
import 'package:notsky/features/post/presentation/components/media/clickable_image_grid.dart';
import 'package:notsky/features/post/presentation/components/media/image_detail_screen.dart';
import 'package:notsky/features/post/presentation/components/post/util/time_formatter.dart';
import 'package:notsky/features/post/presentation/controllers/bottom_nav_visibility_controller.dart';
import 'package:notsky/features/post/presentation/pages/post_detail_page.dart';
import 'package:notsky/shared/components/no_background_cupertino_page_route.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class QuotedPostRenderer {
  static Widget buildQuotedPost(
    BuildContext context,
    Post post,
    List<ContentLabelPreference> contentLabelPreferences,
  ) {
    final embed = post.embed;

    if (embed?.data is EmbedViewRecordWithMedia) {
      final recordWithMedia = embed!.data as EmbedViewRecordWithMedia;
      final quoteEmbed = recordWithMedia.record;

      if ((quoteEmbed.record).data is EmbedViewRecordViewBlocked) {
        return _buildQuoteBlockedView(context);
      } else if ((quoteEmbed.record).data is EmbedViewRecordViewNotFound) {
        return _buildQuoteDeletedView(context);
      }

      final quotedRecord =
          (quoteEmbed.record).data as EmbedViewRecordViewRecord;
      return _buildQuotePostView(
        context,
        quotedRecord,
        contentLabelPreferences,
      );
    } else if (embed?.data is EmbedViewRecord) {
      final quoteEmbed = embed!.data as EmbedViewRecord;

      if ((quoteEmbed.record).data is EmbedViewRecordViewBlocked) {
        return _buildQuoteBlockedView(context);
      } else if ((quoteEmbed.record).data is EmbedViewRecordViewNotFound) {
        return _buildQuoteDeletedView(context);
      }

      if (((quoteEmbed.record).data) is ListView) {
        return _buildQuoteListView(context, quoteEmbed.record.data as ListView);
      }

      final quotedRecord =
          (quoteEmbed.record).data as EmbedViewRecordViewRecord;
      return _buildQuotePostView(
        context,
        quotedRecord,
        contentLabelPreferences,
      );
    }

    return const SizedBox.shrink();
  }

  static Widget _buildQuoteListView(BuildContext context, ListView listView) {
    return GestureDetector(
      onTap: () {
        // TODO Navigate to list
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outline.withValues(alpha: 0.25),
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            spacing: 8.0,
            children: [
              Row(
                spacing: 8.0,
                children: [
                  SizedBox(
                    width: 30.0,
                    height: 30.0,
                    child:
                        listView.avatar != null && listView.avatar!.isNotEmpty
                            ? Image.network(listView.avatar!)
                            : Container(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          listView.name,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${_parseListPurpose(listView.purpose)} by ${listView.createdBy.handle}',
                          style: const TextStyle(fontSize: 12.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      listView.description ?? '',
                      softWrap: true,
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _parseListPurpose(String purpose) {
    switch (purpose) {
      case 'app.bsky.graph.defs#modlist':
        return 'Moderation list';
      default:
        return 'Unknown list';
    }
  }

  static Widget _buildQuoteDeletedView(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 8.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Row(
          spacing: 4.0,
          children: [Icon(Icons.info_outline, size: 16.0), Text('Deleted')],
        ),
      ),
    );
  }

  static Widget _buildQuoteBlockedView(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 8.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Row(
          spacing: 4.0,
          children: [Icon(Icons.info_outline, size: 16.0), Text('Blocked')],
        ),
      ),
    );
  }

  static Widget _buildQuotePostView(
    BuildContext context,
    EmbedViewRecordViewRecord quotedPost,
    List<ContentLabelPreference> contentLabelPreferences,
  ) {
    return InkWell(
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      onTap: () {
        final auth = context.read<AuthCubit>();
        final blueskyService = auth.getBlueskyService();

        blueskyService.getPost(quotedPost.uri).then((fetchedPost) {
          if (fetchedPost != null) {
            Navigator.of(context).push(
              NoBackgroundCupertinoPageRoute(
                builder:
                    (context) => PostDetailPage(
                      post: fetchedPost,
                      reply: null,
                      reason: null,
                      contentLabelPreferences: contentLabelPreferences,
                    ),
              ),
            );
          }
        });
      },
      child: Container(
        margin: EdgeInsets.only(top: 8.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outline.withValues(alpha: 0.25),
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AvatarComponent(
                    actorDid: quotedPost.author.did,
                    avatar: quotedPost.author.avatar,
                    size: 20.0,
                  ),
                  SizedBox(width: 8.0),
                  Flexible(
                    child: Text(
                      quotedPost.author.displayName ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: 4.0),
                  Flexible(
                    child: Text(
                      '@${quotedPost.author.handle}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(' • '),
                  Flexible(
                    child: Text(
                      TimeFormatter.getRelativeTime(quotedPost.indexedAt),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.0),
              if (quotedPost.value.text.isNotEmpty) Text(quotedPost.value.text),
              _buildQuotedPostMedia(context, quotedPost),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildQuotedPostMedia(
    BuildContext context,
    EmbedViewRecordViewRecord quotedPost,
  ) {
    if (quotedPost.embeds != null) {
      for (final embed in quotedPost.embeds!) {
        if (embed.data is EmbedViewImages) {
          final imageEmbed = embed.data as EmbedViewImages;
          return ClickableImageGrid(
            images: imageEmbed.images,
            onImageTap: (image, index) {
              final navController = Provider.of<BottomNavVisibilityController>(
                context,
                listen: false,
              );
              navController.hide();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => ImageDetailScreen(
                        images: imageEmbed.images,
                        initialIndex: index,
                        onExit: () {
                          navController.show();
                        },
                      ),
                ),
              );
            },
          );
        } else if (embed.data is EmbedViewRecordWithMedia) {
          final recordWithMediaEmbed = embed.data as EmbedViewRecordWithMedia;

          if (recordWithMediaEmbed.media.data is EmbedViewImages) {
            final imageEmbed =
                recordWithMediaEmbed.media.data as EmbedViewImages;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuotedRecord(recordWithMediaEmbed.record),

                ClickableImageGrid(
                  images: imageEmbed.images,
                  onImageTap: (image, index) {
                    final navController =
                        Provider.of<BottomNavVisibilityController>(
                          context,
                          listen: false,
                        );
                    navController.hide();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (context) => ImageDetailScreen(
                              images: imageEmbed.images,
                              initialIndex: index,
                              onExit: () {
                                navController.show();
                              },
                            ),
                      ),
                    );
                  },
                ),
              ],
            );
          }
        } else if (embed.data is EmbedViewExternal) {
          final external = embed.data as EmbedViewExternal;
          final url = (embed.data as EmbedViewExternal).external.uri;

          if (url.contains('youtube.com') || url.contains('youtu.be')) {
            final videoId = YoutubePlayer.convertUrlToId(url);
            if (videoId != null) {
              final controller = YoutubePlayerController(
                initialVideoId: videoId,
                flags: YoutubePlayerFlags(autoPlay: false),
              );

              return Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: YoutubePlayer(controller: controller),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          } else {
            return InkWell(
              splashFactory: NoSplash.splashFactory,
              splashColor: Colors.transparent,
              onTap: () {
                launchUrl(Uri.parse(url));
              },
              child: Container(
                margin: EdgeInsets.only(top: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.25),
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (external.external.thumbnail != null)
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(7.0),
                        ),
                        child: Image.network(
                          external.external.thumbnail!,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            external.external.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 4.0),
                            child: Text(
                              external.external.description,
                              style: TextStyle(
                                fontSize: 12.0,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 4.0),
                            child: Text(
                              Uri.parse(external.external.uri).host,
                              style: TextStyle(
                                fontSize: 12.0,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }
      }
    }

    return SizedBox.shrink();
  }

  static Widget _buildQuotedRecord(EmbedViewRecord record) {
    if (record.record is EmbedViewRecordViewRecord) {
      final recordData = record.record as EmbedViewRecordViewRecord;
      return Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (recordData.author.avatar != null)
                  CircleAvatar(
                    backgroundImage: NetworkImage(recordData.author.avatar!),
                    radius: 16,
                  ),
                SizedBox(width: 8),
                Text(
                  recordData.author.displayName ?? recordData.author.handle,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),

            Text(recordData.value.text),
          ],
        ),
      );
    }

    return SizedBox.shrink();
  }
}
