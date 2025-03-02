import 'package:bluesky/bluesky.dart' hide Image;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PostExternalContentRenderer {
  static Widget buildExternal(BuildContext context, Post post) {
    final embed = post.embed;

    if (embed?.data is EmbedViewExternal) {
      final external = (embed!.data as EmbedViewExternal).external;
      // These are handled in other methods already
      if (external.uri.contains('youtu.be') ||
          external.uri.contains('youtube') ||
          external.uri.contains('tenor')) {
        return SizedBox.shrink();
      }
      return _buildExternalContent(context, external);
    }

    if (embed?.data is EmbedViewRecordWithMedia) {
      final recordWithMedia = embed!.data as EmbedViewRecordWithMedia;
      if (recordWithMedia.media.data is EmbedViewExternal) {
        final external = recordWithMedia.media.data as EmbedViewExternal;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildExternalContent(context, external.external)],
        );
      }
    }

    return SizedBox.shrink();
  }

  static Widget _buildExternalContent(
    BuildContext context,
    EmbedViewExternalView external,
  ) {
    return InkWell(
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      onTap: () {
        launchUrl(Uri.parse(external.uri));
      },
      child: Container(
        width: double.infinity,
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
            if (external.thumbnail != null && external.thumbnail!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(7.0)),
                child: Image.network(
                  external.thumbnail!,
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
                    external.title,
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
                      external.description,
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Text(
                      Uri.parse(external.uri).host,
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
