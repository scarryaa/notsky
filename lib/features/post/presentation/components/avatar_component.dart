import 'package:flutter/material.dart';

class AvatarComponent extends StatelessWidget {
  const AvatarComponent({super.key, required this.avatar, required this.size});

  final String? avatar;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (avatar == null || avatar!.isEmpty) {
      return _buildDefaultAvatar();
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.all(Radius.circular(50)),
      ),
      child: ClipOval(
        child: Image.network(
          avatar!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: size,
              height: size,
              color: Colors.grey[300],
              child: Center(child: Container()),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Icon(
      Icons.account_circle_rounded,
      size: size,
      color: Colors.grey[600],
    );
  }
}
