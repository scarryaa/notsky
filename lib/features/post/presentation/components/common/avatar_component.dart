import 'package:bluesky/bluesky.dart' hide Image;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:notsky/features/feed/presentation/cubits/feed_cubit.dart';
import 'package:notsky/features/post/presentation/components/media/image_detail_screen.dart';
import 'package:notsky/features/post/presentation/controllers/bottom_nav_visibility_controller.dart';
import 'package:notsky/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:notsky/features/profile/presentation/pages/profile_page.dart';
import 'package:notsky/shared/components/no_background_cupertino_page_route.dart';
import 'package:provider/provider.dart';

class AvatarComponent extends StatelessWidget {
  const AvatarComponent({
    super.key,
    required this.actorDid,
    required this.avatar,
    required this.size,
    this.clickable = true,
    this.fullscreenable = false,
  });

  final String? actorDid;
  final String? avatar;
  final double size;
  final bool clickable;
  final bool fullscreenable;

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
                    builder:
                        (context) => BlocProvider<ProfileCubit>(
                          create: (context) {
                            final bskyService =
                                context.read<AuthCubit>().getBlueskyService();

                            return ProfileCubit(bskyService);
                          },
                          child: BlocProvider(
                            create: (context) {
                              final bskyService =
                                  context.read<AuthCubit>().getBlueskyService();
                              return FeedCubit(bskyService);
                            },
                            child: ProfilePage(actorDid: actorDid!),
                          ),
                        ),
                  ),
                );
              }
              : fullscreenable
              ? () {
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
                          images: [
                            EmbedViewImagesView(
                              thumbnail: avatar ?? '',
                              fullsize: avatar ?? '',
                              alt: '',
                            ),
                          ],
                          initialIndex: 0,
                          onExit: () {
                            navController.show();
                          },
                        ),
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
