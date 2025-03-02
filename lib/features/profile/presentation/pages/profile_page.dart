import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/post/presentation/components/common/avatar_component.dart';
import 'package:notsky/features/profile/presentation/cubits/post_state.dart';
import 'package:notsky/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:notsky/util/util.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.actorDid,
    this.showBackButton = true,
  });

  final String actorDid;
  final bool showBackButton;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();

    context.read<ProfileCubit>().getProfile(widget.actorDid);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoaded) {
          return _buildProfile(context, state);
        } else if (state is ProfileError) {
          return Center(
            child: Text('Error: could not load profile. ${state.message}'),
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildProfile(BuildContext context, ProfileLoaded state) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                spacing: 6.0,
                children: [
                  Image.network(state.profile.banner ?? ''),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      spacing: 6.0,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildProfileButton(
                          context,
                          () {},
                          icon: Icons.message,
                        ),
                        _buildProfileButton(
                          context,
                          () {},
                          label:
                              state.profile.viewer.isFollowing
                                  ? 'Following'
                                  : 'Follow',
                          icon:
                              state.profile.viewer.isFollowing
                                  ? Icons.check
                                  : Icons.add,
                        ),
                        _buildProfileButton(
                          context,
                          () {},
                          icon: Icons.more_horiz,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 0.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              state.profile.displayName ?? '',
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 28.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.0),
                        Row(
                          spacing: 8.0,
                          children: [
                            if (state.profile.viewer.isFollowing)
                              _buildFollowTag(context, state),
                            _buildHandle(context, state),
                          ],
                        ),
                        SizedBox(height: 4.0),
                        Row(
                          spacing: 8.0,
                          children: [
                            _buildFollowersCount(context, state),
                            _buildFollowingCount(context, state),
                            _buildPostCount(context, state),
                          ],
                        ),
                        SizedBox(height: 4.0),
                        Text(state.profile.description ?? '', softWrap: true),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 52.0,
                left: 8.0,
                child: IconButton(
                  constraints: BoxConstraints(maxWidth: 32.0, maxHeight: 32.0),
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(
                      Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: Icon(
                    Icons.arrow_back,
                    size: 16.0,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Positioned(
                top: 104.0,
                left: 8.0,
                child: AvatarComponent(
                  actorDid: widget.actorDid,
                  avatar: state.profile.avatar,
                  size: 96.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileButton(
    BuildContext context,
    void Function()? onPressed, {
    IconData? icon,
    String? label,
  }) {
    return TextButton(
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(0, 0)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: WidgetStatePropertyAll(EdgeInsets.all(10.0)),
        backgroundColor: WidgetStatePropertyAll(
          Theme.of(context).colorScheme.primary,
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16.0,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          if (label != null && label.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: 4.0),
              child: Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 12.0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFollowTag(BuildContext context, ProfileLoaded state) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(6.0)),
      child: Container(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.65),
        padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        child: Text(
          'Following',
          style: TextStyle(
            fontSize: 12.0,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(BuildContext context, ProfileLoaded state) {
    return Text(
      '@${state.profile.handle}',
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 14.0,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildPostCount(BuildContext context, ProfileLoaded state) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: formatNumber(state.profile.postsCount).toString(),
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          TextSpan(
            text: ' posts',
            style: TextStyle(
              fontSize: 14.0,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowersCount(BuildContext context, ProfileLoaded state) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: formatNumber(state.profile.followersCount).toString(),
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          TextSpan(
            text: ' followers',
            style: TextStyle(
              fontSize: 14.0,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowingCount(BuildContext context, ProfileLoaded state) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: formatNumber(state.profile.followsCount).toString(),
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          TextSpan(
            text: ' following',
            style: TextStyle(
              fontSize: 14.0,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
