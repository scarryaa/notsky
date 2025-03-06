import 'package:bluesky/bluesky.dart';
import 'package:flutter/material.dart';
import 'package:notsky/features/post/presentation/components/common/avatar_component.dart';

class AuthorTileComponent extends StatelessWidget {
  const AuthorTileComponent({
    super.key,
    required this.actor,
    this.isFollowing = false,
    this.onFollowTap,
    this.isLoading = true,
    this.onTap,
  });

  final Actor actor;
  final bool isFollowing;
  final bool isLoading;
  final Function(bool)? onFollowTap;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(4.0, 8.0, 16.0, 8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AvatarComponent(
                  size: 40.0,
                  clickable: true,
                  avatar: actor.avatar,
                  actorDid: actor.did,
                ),
                SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        actor.displayName != null && actor.displayName!.isEmpty
                            ? actor.handle
                            : actor.displayName ?? actor.handle,
                      ),
                      Text(
                        '@${actor.handle}',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                      ),
                      if (actor.labels != null && actor.labels!.isNotEmpty) ...[
                        _buildLabels(context),
                      ],
                      SizedBox(height: 8.0),
                      if (actor.description != null) _buildDescription(),
                    ],
                  ),
                ),
                _buildFollowButton(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Text(actor.description ?? '', softWrap: true);
  }

  Widget _buildLabels(BuildContext context) {
    final List<Widget> labels = [];

    for (final label in actor.labels!) {
      if (label.value != '!no-unauthenticated') {
        labels.add(
          Container(
            margin: const EdgeInsets.only(right: 4.0, top: 4.0),
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              label.value,
              style: TextStyle(
                fontSize: 10.0,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }
    }

    return Wrap(direction: Axis.horizontal, children: labels);
  }

  Widget _buildFollowButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        if (onFollowTap != null) {
          onFollowTap!(!isFollowing);
        }
      },
      style: OutlinedButton.styleFrom(
        backgroundColor:
            isFollowing
                ? Colors.transparent
                : Theme.of(context).colorScheme.primary,
        side: BorderSide(color: Theme.of(context).colorScheme.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
      child: Text(
        isFollowing ? 'Following' : 'Follow',
        style: TextStyle(
          color:
              isFollowing
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
