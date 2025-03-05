import 'dart:async';
import 'dart:math';

import 'package:atproto_core/atproto_core.dart';
import 'package:bluesky/bluesky.dart' hide Image;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_state.dart';
import 'package:notsky/features/feed/presentation/cubits/feed_cubit.dart';
import 'package:notsky/features/post/domain/entities/post_content.dart';
import 'package:notsky/features/post/presentation/components/common/avatar_component.dart';
import 'package:notsky/features/post/presentation/components/post/base_post_component.dart';
import 'package:notsky/features/post/presentation/cubits/post_cubit.dart';
import 'package:notsky/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:notsky/features/profile/presentation/cubits/profile_state.dart';
import 'package:notsky/features/thread/presentation/components/thread_component.dart';
import 'package:notsky/shared/components/author_feed_item_component.dart';
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

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  TabController? _tabController;
  StreamSubscription? _profileSubscription;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  late final SavedFeedsPreference savedFeedsPreference;
  late final SavedFeedsPrefV2 savedFeedsPrefV2;

  void _handleTabChange(bool isOwnProfile) {
    if (_tabController!.indexIsChanging) {
      setState(() {});
      loadDataForTab(isOwnProfile, _tabController!.index);
    }
  }

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    context.read<ProfileCubit>().getProfile(widget.actorDid);

    final authState = context.read<AuthCubit>().state as AuthSuccess;
    final isOwnProfile = authState.profile?.did == widget.actorDid;

    // Move async operations to a separate method
    _loadSavedFeedsPreferences();

    bool loaded = false;
    _profileSubscription = context.read<ProfileCubit>().stream.listen((state) {
      if (state is ProfileLoaded && !loaded) {
        _tabController = TabController(
          length:
              isOwnProfile
                  ? 8
                  : 4 +
                      (state.profile.associated!.feedgens > 0 ? 1 : 0) +
                      (state.profile.associated!.lists > 0 ? 1 : 0) +
                      (state.profile.associated!.starterPacks > 0 ? 1 : 0),
          vsync: this,
          initialIndex: _tabController?.index ?? 0,
        );
        _tabController!.addListener(() => _handleTabChange(isOwnProfile));

        setState(() {});
        loaded = true;
      }
    });
  }

  Future<void> _loadSavedFeedsPreferences() async {
    try {
      final savedFeedsPrefs =
          await context
              .read<AuthCubit>()
              .getBlueskyService()
              .getSavedFeedsPreference();

      final savedFeedsPrefV2List =
          await context
              .read<AuthCubit>()
              .getBlueskyService()
              .getSavedFeedsPreferenceV2();

      setState(() {
        savedFeedsPreference = savedFeedsPrefs.firstWhere(
          (pref) => pref.type.contains('savedFeedsPref'),
        );

        savedFeedsPrefV2 = savedFeedsPrefV2List.firstWhere(
          (pref) => pref.type.contains('savedFeedsPrefV2'),
        );
      });
    } catch (e) {
      print('Error loading saved feeds preferences: $e');
    }
  }

  @override
  void dispose() {
    _tabController!.removeListener(() => _handleTabChange(false));
    _tabController!.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _profileSubscription?.cancel();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoaded && _tabController != null) {
          final authState = context.read<AuthCubit>().state as AuthSuccess;
          final isOwnProfile = authState.profile?.did == widget.actorDid;

          return _buildProfile(state, authState, isOwnProfile);
        } else if (state is ProfileError) {
          return Center(child: Text('Error: ${state.message}'));
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildProfile(
    ProfileLoaded state,
    AuthSuccess authState,
    bool isOwnProfile,
  ) {
    return SafeArea(
      top: _scrollOffset > 150 - MediaQuery.of(context).padding.top,
      child: _buildCustomScrollView(state, authState, isOwnProfile),
    );
  }

  Future<void> loadDataForTab(bool isOwnProfile, int index) async {
    setState(() {});
    switch (index) {
      case 0:
        await context.read<ProfileCubit>().loadFeed(
          widget.actorDid,
          FeedType.posts,
        );
        break;
      case 1:
        await context.read<ProfileCubit>().loadFeed(
          widget.actorDid,
          FeedType.replies,
        );
        break;
      case 2:
        await context.read<ProfileCubit>().loadFeed(
          widget.actorDid,
          FeedType.media,
        );
        break;
      case 3:
        await context.read<ProfileCubit>().loadFeed(
          widget.actorDid,
          FeedType.videos,
        );
        break;
    }

    if (isOwnProfile) {
      switch (index) {
        case 4:
          await context.read<ProfileCubit>().loadFeed(
            widget.actorDid,
            FeedType.likes,
          );
          break;
        case 5:
          await context.read<ProfileCubit>().loadActorFeeds(widget.actorDid);
          break;
      }
    } else {
      switch (index) {
        case 4:
          await context.read<ProfileCubit>().loadActorFeeds(widget.actorDid);
          break;
      }
    }
  }

  Widget _buildCustomScrollView(
    ProfileLoaded state,
    AuthSuccess authState,
    bool isOwnProfile,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<ProfileCubit>().getProfile(widget.actorDid);
        return loadDataForTab(isOwnProfile, _tabController!.index);
      },
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            // Swipe right - go to previous tab
            if (_tabController!.index > 0) {
              setState(() {
                _tabController!.animateTo(_tabController!.index - 1);
              });
            }
          } else if (details.primaryVelocity! < 0) {
            // Swipe left - go to next tab
            if (_tabController!.index < _tabController!.length - 1) {
              setState(() {
                _tabController!.animateTo(_tabController!.index + 1);
              });
            }
          }
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        spacing: 6.0,
                        children: [
                          Container(
                            color: Theme.of(context).primaryColor,
                            height:
                                _scrollOffset >
                                        150 - MediaQuery.of(context).padding.top
                                    ? 150 - MediaQuery.of(context).padding.top
                                    : 150,
                            child:
                                state.profile.banner != null &&
                                        state.profile.banner!.isNotEmpty
                                    ? Image.network(
                                      state.profile.banner!,
                                      fit: BoxFit.cover,
                                    )
                                    : null,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              spacing: 6.0,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: _buildProfileButtonsSection(
                                state,
                                authState.profile?.did == widget.actorDid,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 0.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDisplayName(state),
                                SizedBox(height: 4.0),
                                Row(
                                  spacing: 8.0,
                                  children: [
                                    if (state.profile.viewer.isFollowedBy)
                                      _buildFollowsYouTag(context, state),
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
                                Text(
                                  state.profile.description ?? '',
                                  softWrap: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (widget.showBackButton)
                        Positioned(
                          top: 52.0,
                          left: 8.0,
                          child: IconButton(
                            constraints: BoxConstraints(
                              maxWidth: 32.0,
                              maxHeight: 32.0,
                            ),
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
                        top:
                            _scrollOffset >
                                    150 - MediaQuery.of(context).padding.top
                                ? 104.0 - MediaQuery.of(context).padding.top
                                : 104.0,
                        left: 8.0,
                        child: AvatarComponent(
                          actorDid: widget.actorDid,
                          avatar: state.profile.avatar,
                          size: 96.0,
                          clickable: false,
                          fullscreenable: true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.0),
                  if (state.profile.viewer.knownFollowers != null)
                    GestureDetector(
                      onTap: () {
                        // TODO
                      },
                      child: Padding(
                        padding: EdgeInsetsDirectional.symmetric(
                          horizontal: 8.0,
                        ),
                        child: Row(
                          spacing: 8.0,
                          children: [
                            if (!isOwnProfile) _buildKnownFollowers(state),
                            if (!isOwnProfile)
                              Flexible(
                                child: Builder(
                                  builder: (context) {
                                    final knownFollowers =
                                        state.profile.viewer.knownFollowers;
                                    final followerCount =
                                        knownFollowers?.count ?? 0;
                                    final followers =
                                        knownFollowers?.followers ?? [];

                                    if (followers.isEmpty) {
                                      return const SizedBox.shrink();
                                    } else if (followers.length == 1) {
                                      // Only one follower
                                      return Text(
                                        'Followed by ${followers[0].displayName}',
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                        ),
                                      );
                                    } else if (followers.length == 2) {
                                      // Exactly two followers
                                      return Text(
                                        'Followed by ${followers[0].displayName} and ${followers[1].displayName}',
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                        ),
                                      );
                                    } else {
                                      // More than two followers
                                      return Text(
                                        'Followed by ${followers[0].displayName}, ${followers[1].displayName}, and ${followerCount - 2} others',
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (!isOwnProfile) SizedBox(height: 8.0),
                ],
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                _buildTabBar(state, isOwnProfile),
                _scrollOffset,
              ),
              pinned: true,
              floating: true,
            ),
            SliverVisibility(
              visible: true,
              sliver: _getSliver(_tabController!.index, isOwnProfile, state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getSliver(int index, bool isOwnProfile, ProfileLoaded state) {
    if (isOwnProfile) {
      switch (index) {
        case 0:
          return _buildPostsTabSliver();
        case 1:
          return _buildRepliesTabSliver();
        case 2:
          return _buildMediaTabSliver();
        case 3:
          return _buildVideosTabSliver();
        case 4:
          return _buildLikesTabSliver();
        case 5:
          return _buildFeedsTabSliver();
        case 6:
          return _buildStarterPacksTabSliver();
        case 7:
          return _buildListsTabSliver();
        default:
          return SliverToBoxAdapter(child: SizedBox.shrink());
      }
    } else {
      if (index == 0) return _buildPostsTabSliver();
      if (index == 1) return _buildRepliesTabSliver();
      if (index == 2) return _buildMediaTabSliver();
      if (index == 3) return _buildVideosTabSliver();

      int offset = 4;

      if (state.profile.associated!.feedgens > 0) {
        if (index == offset) return _buildFeedsTabSliver();
        offset++;
      }

      if (state.profile.associated!.lists > 0) {
        if (index == offset) return _buildListsTabSliver();
        offset++;
      }

      if (state.profile.associated!.starterPacks > 0) {
        if (index == offset) return _buildStarterPacksTabSliver();
      }

      return SliverToBoxAdapter(child: SizedBox.shrink());
    }
  }

  Widget _buildTabLoadingSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildEmptyTabSliver(String feedType) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: Text('No $feedType found')),
      ),
    );
  }

  Widget _buildFeedTabSliver({
    required String feedType,
    required List<FeedView>? feed,
    required bool isLoading,
    required bool hasMorePosts,
    required bool isLoadingMorePosts,
    required Function(String) loadMoreFunction,
  }) {
    if (isLoading) {
      return _buildTabLoadingSliver();
    }

    if (feed == null || feed.isEmpty) {
      return _buildEmptyTabSliver(feedType);
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == feed.length) {
          return isLoadingMorePosts
              ? Center(child: CircularProgressIndicator())
              : hasMorePosts
              ? SizedBox.shrink()
              : Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No more posts to load'),
                ),
              );
        }

        // Check if we need to load more posts
        if (index >= feed.length - 5 && hasMorePosts && !isLoadingMorePosts) {
          loadMoreFunction(widget.actorDid);
        }

        // Show loading indicator at the end when loading more
        if (index == feed.length) {
          return isLoadingMorePosts
              ? Center(child: CircularProgressIndicator())
              : SizedBox.shrink();
        }

        // Don't render beyond the available posts
        if (index >= feed.length) {
          return SizedBox.shrink();
        }

        final feedItem = feed[index];
        return _buildFeedItem(context, feedItem, index, feed.length);
      }, childCount: feed.length + (hasMorePosts ? 1 : 0)),
    );
  }

  Widget _buildFeedItem(
    BuildContext context,
    FeedView feedItem,
    int index,
    int totalItems,
  ) {
    return BlocProvider(
      create:
          (context) => PostCubit(context.read<AuthCubit>().getBlueskyService()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ThreadComponent(
            feedItem: feedItem,
            contentLabelPreferences:
                context.read<FeedCubit>().contentLabelPreferences,
          ),
          BasePostComponent(
            postContent: RegularPost(feedItem.post),
            reason: feedItem.reason,
            reply: feedItem.reply,
            isReplyToMissingPost: feedItem.reply?.parent.data is NotFoundPost,
            isReplyToBlockedPost: feedItem.reply?.parent.data is BlockedPost,
            contentLabelPreferences:
                context.read<FeedCubit>().contentLabelPreferences,
          ),
          if (index < totalItems - 1)
            Divider(
              height: 1.0,
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.25),
            ),
        ],
      ),
    );
  }

  Widget _buildPostsTabSliver() {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is! ProfileLoaded) {
          return SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return _buildFeedTabSliver(
          feedType: 'posts',
          feed: state.authorFeed?.feed,
          isLoading: state.isLoadingPosts,
          hasMorePosts: state.hasMorePosts,
          isLoadingMorePosts: state.isLoadingMorePosts,
          loadMoreFunction:
              (did) => context.read<ProfileCubit>().loadMoreFeed(
                did,
                FeedType.posts,
              ),
        );
      },
    );
  }

  Widget _buildRepliesTabSliver() {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is! ProfileLoaded) {
          return SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return _buildFeedTabSliver(
          feedType: 'replies',
          feed: state.repliesFeed?.feed,
          isLoading: state.isLoadingPosts,
          hasMorePosts: state.hasMorePosts,
          isLoadingMorePosts: state.isLoadingMorePosts,
          loadMoreFunction:
              (did) => context.read<ProfileCubit>().loadMoreFeed(
                did,
                FeedType.replies,
              ),
        );
      },
    );
  }

  Widget _buildMediaTabSliver() {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is! ProfileLoaded) {
          return SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return _buildFeedTabSliver(
          feedType: 'media',
          feed: state.mediaFeed?.feed,
          isLoading: state.isLoadingPosts,
          hasMorePosts: state.hasMorePosts,
          isLoadingMorePosts: state.isLoadingMorePosts,
          loadMoreFunction:
              (did) => context.read<ProfileCubit>().loadMoreFeed(
                did,
                FeedType.media,
              ),
        );
      },
    );
  }

  Widget _buildVideosTabSliver() {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is! ProfileLoaded) {
          return SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return _buildFeedTabSliver(
          feedType: 'videos',
          feed: state.videosFeed?.feed,
          isLoading: state.isLoadingPosts,
          hasMorePosts: state.hasMorePosts,
          isLoadingMorePosts: state.isLoadingMorePosts,
          loadMoreFunction:
              (did) => context.read<ProfileCubit>().loadMoreFeed(
                did,
                FeedType.videos,
              ),
        );
      },
    );
  }

  Widget _buildLikesTabSliver() {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is! ProfileLoaded) {
          return SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return _buildFeedTabSliver(
          feedType: 'likes',
          feed: state.likesFeed?.feed,
          isLoading: state.isLoadingPosts,
          hasMorePosts: state.hasMorePosts,
          isLoadingMorePosts: state.isLoadingMorePosts,
          loadMoreFunction:
              (did) => context.read<ProfileCubit>().loadMoreFeed(
                did,
                FeedType.likes,
              ),
        );
      },
    );
  }

  Widget _buildFeedsTabSliver() {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is! ProfileLoaded) {
          return SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.isLoadingFeeds) {
          return _buildTabLoadingSliver();
        }

        if (state.actorFeeds == null || state.actorFeeds!.feeds.isEmpty) {
          return _buildEmptyTabSliver('feeds');
        }

        final int totalItemCount =
            state.actorFeeds!.feeds.length + (state.hasMoreFeeds ? 1 : 1);

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            if (index % 2 == 1) {
              return Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.25),
              );
            }

            final itemIndex = index ~/ 2;

            if (itemIndex >= state.actorFeeds!.feeds.length) {
              return state.isLoadingMoreFeeds
                  ? Center(child: CircularProgressIndicator())
                  : state.hasMoreFeeds
                  ? SizedBox.shrink()
                  : Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No more feeds to load'),
                    ),
                  );
            }

            if (itemIndex >= state.actorFeeds!.feeds.length - 5 &&
                state.hasMoreFeeds &&
                !state.isLoadingMoreFeeds) {
              context.read<ProfileCubit>().loadMoreActorFeeds(widget.actorDid);
            }

            final sortedFeeds = List<FeedGeneratorView>.from(
              state.actorFeeds!.feeds,
            )..sort((a, b) => b.likeCount.compareTo(a.likeCount));
            final feed = sortedFeeds[itemIndex];

            return _buildAuthorFeedItem(
              context,
              feed,
              savedFeedsPreference as SavedFeedsPreference,
              savedFeedsPrefV2 as SavedFeedsPrefV2,
              itemIndex,
            );
          }, childCount: totalItemCount * 2 - 1),
        );
      },
    );
  }

  Widget _buildAuthorFeedItem(
    BuildContext context,
    FeedGeneratorView feed,
    SavedFeedsPreference savedFeeds,
    SavedFeedsPrefV2 savedFeedsPrefV2,
    int index,
  ) {
    return AuthorFeedItemComponent(
      feed: feed,
      onTap: () {
        //TODO
      },
      onSubscribe: () {
        // TODO
      },
      isSubscribed:
          savedFeedsPrefV2.items.any(
            (savedFeed) => AtUri.parse(savedFeed.value) == feed.uri,
          ) ||
          savedFeeds.pinnedUris.contains(feed.uri),
    );
  }

  Widget _buildStarterPacksTabSliver() {
    return SliverToBoxAdapter(
      child: Center(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Text('Starter packs tab content'),
        ),
      ),
    );
  }

  Widget _buildListsTabSliver() {
    return SliverToBoxAdapter(
      child: Center(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Text('Lists tab content'),
        ),
      ),
    );
  }

  Widget _buildKnownFollowers(ProfileLoaded state) {
    final followers = state.profile.viewer.knownFollowers?.followers;
    if (followers == null || followers.isEmpty) {
      return SizedBox.shrink();
    }

    List<Widget> avatars = [];
    final count = min(4, followers.length);

    final stackWidth = 28.0 + (count - 1) * 16.0;

    for (int i = count - 1; i >= 0; i--) {
      avatars.add(
        Positioned(
          left: i * 16.0,
          child: AvatarComponent(
            actorDid: null,
            avatar: followers[i].avatar,
            size: 28.0,
            clickable: false,
          ),
        ),
      );
    }

    return SizedBox(
      width: stackWidth,
      height: 32.0,
      child: Stack(clipBehavior: Clip.none, children: avatars),
    );
  }

  Widget _buildDisplayName(ProfileLoaded state) {
    return Text(
      state.profile.displayName ?? '',
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.bold,
        height: 1.0,
      ),
    );
  }

  TabBar _buildTabBar(ProfileLoaded state, bool isUserProfile) {
    return TabBar(
      tabAlignment: TabAlignment.start,
      isScrollable: true,
      controller: _tabController,
      tabs:
          isUserProfile
              ? [
                _buildProfileTab('Posts'),
                _buildProfileTab('Replies'),
                _buildProfileTab('Media'),
                _buildProfileTab('Videos'),
                _buildProfileTab('Likes'),
                _buildProfileTab('Feeds'),
                _buildProfileTab('Starter Packs'),
                _buildProfileTab('Lists'),
              ]
              : [
                _buildProfileTab('Posts'),
                _buildProfileTab('Replies'),
                _buildProfileTab('Media'),
                _buildProfileTab('Videos'),
                if (state.profile.associated!.feedgens > 0)
                  _buildProfileTab('Feeds'),
                if (state.profile.associated!.lists > 0)
                  _buildProfileTab('Lists'),
                if (state.profile.associated!.starterPacks > 0)
                  _buildProfileTab('Starter Packs'),
              ],
    );
  }

  Widget _buildProfileTab(String title) {
    return Tab(text: title);
  }

  List<Widget> _buildProfileButtonsSection(
    ProfileLoaded state,
    bool isUserProfile,
  ) {
    if (isUserProfile) {
      return [
        _buildProfileButton(context, () {}, label: 'Edit profile'),
        _buildProfileButton(context, () {}, icon: Icons.more_horiz),
      ];
    } else {
      return [
        _buildProfileButton(context, () {}, icon: Icons.message),
        _buildProfileButton(
          context,
          state.profile.viewer.isFollowing ? () {} : () {},
          label: state.profile.viewer.isFollowing ? 'Following' : 'Follow',
          icon: state.profile.viewer.isFollowing ? Icons.check : Icons.add,
        ),
        _buildProfileButton(context, () {}, icon: Icons.more_horiz),
      ];
    }
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
          if (icon != null)
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

  Widget _buildFollowsYouTag(BuildContext context, ProfileLoaded state) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(6.0)),
      child: Container(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.65),
        padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        child: Text(
          'Follows you',
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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final double _scrollOffset;

  _SliverAppBarDelegate(this._tabBar, this._scrollOffset);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return oldDelegate._scrollOffset != _scrollOffset;
  }
}
