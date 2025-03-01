import 'package:flutter/material.dart';

class ClickableImageGrid extends StatelessWidget {
  final List<dynamic> images;
  final Function(dynamic image, int index) onImageTap;

  const ClickableImageGrid({
    super.key,
    required this.images,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    if (images.length == 1) {
      return _buildSingleImage(context, images[0], 0);
    }

    return _buildImageGrid(context);
  }

  Widget _buildSingleImage(BuildContext context, dynamic image, int index) {
    final aspectRatio =
        image.aspectRatio != null
            ? image.aspectRatio!.width / image.aspectRatio!.height
            : 1.0;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: GestureDetector(
        onTap: () => onImageTap(image, index),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: _buildNetworkImage(context, image.fullsize),
        ),
      ),
    );
  }

  Widget _buildImageGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: images.length <= 2 ? images.length : 2,
          childAspectRatio: 1.0,
          crossAxisSpacing: 4.0,
          mainAxisSpacing: 4.0,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => onImageTap(images[index], index),
            child: _buildNetworkImage(context, images[index].fullsize),
          );
        },
      ),
    );
  }

  Widget _buildNetworkImage(BuildContext context, String imageUrl) {
    try {
      if (imageUrl.isEmpty) {
        return _buildErrorPlaceholder();
      }

      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorPlaceholder();
            },
          ),
        ),
      );
    } catch (e) {
      print('Error loading image: $e');
      return _buildErrorPlaceholder();
    }
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Icon(Icons.broken_image, color: Colors.grey[600]),
    );
  }
}
