import 'package:flutter/material.dart';
import 'package:notsky/features/profile/presentation/pages/profile_page.dart';
import 'package:notsky/shared/components/no_background_cupertino_page_route.dart';

class AvatarComponent extends StatelessWidget {
  const AvatarComponent({
    super.key,
    required this.actorDid,
    required this.avatar,
    required this.size,
    this.clickable = true,
  });

  final String? actorDid;
  final String? avatar;
  final double size;
  final bool clickable;

  @override
  Widget build(BuildContext context) {
    if (avatar == null || avatar!.isEmpty) {
      return _buildDefaultAvatar();
    }

    return GestureDetector(
      onTap:
          (clickable && actorDid != null)
              ? () {
                Navigator.of(context).push(
                  NoBackgroundCupertinoPageRoute(
                    builder: (context) => ProfilePage(actorDid: actorDid!),
                  ),
                );
              }
              : null,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outline.withValues(alpha: 0.25),
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
