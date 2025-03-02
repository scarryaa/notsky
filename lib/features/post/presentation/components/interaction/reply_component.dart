import 'package:bluesky/bluesky.dart' hide Image;
import 'package:flutter/material.dart';
import 'package:notsky/features/post/presentation/components/common/avatar_component.dart';
import 'package:notsky/features/post/presentation/components/common/character_count_painter.dart';

class ReplyComponent extends StatefulWidget {
  const ReplyComponent({
    super.key,
    required this.userDid,
    required this.replyPost,
    required this.userAvatar,
    required this.hideOrWarn,
    required this.isQuotePosting,
    this.onCancel,
    this.onReply,
  });

  final String? userDid;
  final Post? replyPost;
  final String? userAvatar;
  final bool? hideOrWarn;
  final bool isQuotePosting;
  final void Function()? onCancel;
  final void Function(String, bool)? onReply;

  @override
  State<ReplyComponent> createState() => _ReplyComponentState();
}

class _ReplyComponentState extends State<ReplyComponent> {
  final TextEditingController _controller = TextEditingController();
  final int maxLength = 300;
  double progress = 0.0;
  bool _isReplyEnabled = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateProgress);
    _controller.addListener(_updateReplyButtonState);
  }

  void _updateReplyButtonState() {
    setState(() {
      _isReplyEnabled =
          _controller.text.isNotEmpty && _controller.text.length <= maxLength;
    });
  }

  void _updateProgress() {
    setState(() {
      progress = _controller.text.length / maxLength;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_updateProgress);
    _controller.removeListener(_updateReplyButtonState);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 8.0,
        right: 8.0,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              TextButton(
                onPressed: widget.onCancel,
                style: ButtonStyle(
                  foregroundColor: WidgetStatePropertyAll(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                child: Text('Cancel'),
              ),
              Spacer(),
              TextButton(
                onPressed:
                    _isReplyEnabled
                        ? () => widget.onReply?.call(
                          _controller.text,
                          widget.isQuotePosting,
                        )
                        : () {},
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    _isReplyEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  foregroundColor: WidgetStatePropertyAll(
                    Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                child: Text(widget.replyPost == null ? 'Post' : 'Reply'),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (!widget.isQuotePosting) _buildReplyPost(context),
                  if (widget.replyPost != null) Divider(height: 1.0),
                  _buildReplySection(context),
                  if (widget.isQuotePosting) _buildQuotePost(),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: 8.0,
              top: 4.0,
              left: 8.0,
              right: 8.0,
            ),
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    int remaining = maxLength - _controller.text.length;
    bool isOverLimit = remaining < 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Spacer(),
        SizedBox(
          width: 45,
          child: Text(
            _formatCharCount(_controller.text.length),
            style: TextStyle(color: isOverLimit ? Colors.red : null),
          ),
        ),
        SizedBox(
          height: 20,
          width: 20,
          child: CustomPaint(
            painter: CharacterCountPainter(
              progress: progress,
              innerProgress: _calculateInnerProgress(),
              primaryColor:
                  progress > 0.9
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary,
              backgroundColor: Colors.grey[300]!,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuotePost() {
    if (widget.replyPost == null) return SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(10.0, 16.0, 10.0, 16.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outline.withValues(alpha: 0.25),
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AvatarComponent(
                    actorDid: widget.replyPost!.author.did,
                    avatar: widget.replyPost!.author.avatar,
                    size: 24.0,
                  ),
                  SizedBox(width: 8.0),
                  Text(
                    widget.replyPost!.author.displayName ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.0),
              Text(
                widget.replyPost!.record.text,
                style: TextStyle(fontSize: 14.0),
              ),
              if (!widget.hideOrWarn! && _hasImages())
                Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: _buildQuoteImagePreview(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasImages() {
    final embed = widget.replyPost!.embed;
    if (embed == null || embed.data is! EmbedViewImages) {
      return false;
    }

    final imageEmbed = embed.data as EmbedViewImages;
    return imageEmbed.images.isNotEmpty;
  }

  Widget _buildQuoteImagePreview() {
    final embed = widget.replyPost!.embed;
    final imageEmbed = embed!.data as EmbedViewImages;
    final images = imageEmbed.images;

    const double previewSize = 40.0;

    return Row(
      children: [
        for (int i = 0; i < images.length && i < 3; i++)
          Padding(
            padding: EdgeInsets.only(right: 4.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: Image.network(
                images[i].thumbnail,
                width: previewSize,
                height: previewSize,
                fit: BoxFit.cover,
              ),
            ),
          ),
        if (images.length > 3)
          Container(
            width: previewSize,
            height: previewSize,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Center(
              child: Text(
                '+${images.length - 3}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  String _formatCharCount(int count) {
    int remaining = maxLength - count;

    if (remaining >= 0) {
      return remaining.toString();
    } else {
      int overLimit = -remaining;

      if (overLimit < 1000) {
        return '-$overLimit';
      } else if (overLimit < 10000) {
        double k = overLimit / 1000;
        return '-${k.toStringAsFixed(1)}k';
      } else {
        int k = (overLimit / 1000).round();
        return '-${k}k';
      }
    }
  }

  double _calculateInnerProgress() {
    if (_controller.text.length <= maxLength) return 0.0;

    return (_controller.text.length - maxLength) / maxLength;
  }

  Widget _buildReplyPost(BuildContext context) {
    if (widget.replyPost == null) return SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(10.0, 4.0, 10.0, 16.0),
      child: Row(
        spacing: 12.0,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarComponent(
            actorDid: widget.replyPost!.author.did,
            avatar: widget.replyPost!.author.avatar,
            size: 40.0,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.replyPost!.author.displayName ?? '',
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.inverseSurface,
                  ),
                ),
                Text(
                  widget.replyPost!.record.text,
                  softWrap: true,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inverseSurface,
                  ),
                ),
              ],
            ),
          ),
          if (!widget.hideOrWarn!) _buildImagePreview(context),
        ],
      ),
    );
  }

  Widget _buildReplySection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(10.0, 16.0, 10.0, 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarComponent(
            actorDid: widget.userDid,
            avatar: widget.userAvatar,
            size: 40.0,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.only(left: 12.0, top: 6.0),
                    hintText:
                        'Write your ${widget.replyPost == null ? 'post' : 'reply'}...',
                    border: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    final embed = widget.replyPost!.embed;
    if (embed == null || embed.data is! EmbedViewImages) {
      return const SizedBox.shrink();
    }

    final imageEmbed = embed.data as EmbedViewImages;
    final images = imageEmbed.images;

    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    const double previewSize = 60.0;

    if (images.length == 1) {
      return Padding(
        padding: const EdgeInsets.only(left: 4.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: SizedBox(
            width: previewSize,
            height: previewSize,
            child: Image.network(
              images[0].thumbnail,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.broken_image,
                    size: 16.0,
                    color: Colors.grey[600],
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: SizedBox(
        width: previewSize,
        height: previewSize,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: Image.network(
                images[0].thumbnail,
                fit: BoxFit.cover,
                width: previewSize,
                height: previewSize,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.broken_image,
                      size: 16.0,
                      color: Colors.grey[600],
                    ),
                  );
                },
              ),
            ),
            if (images.length > 1)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '+${images.length - 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
