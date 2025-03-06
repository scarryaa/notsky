import 'package:bluesky/bluesky.dart' hide ListView;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:notsky/features/feed/presentation/cubits/feed_cubit.dart';
import 'package:notsky/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:notsky/features/profile/presentation/pages/profile_page.dart';
import 'package:notsky/shared/components/author_feed_item_component.dart';
import 'package:notsky/shared/components/author_tile_component.dart';
import 'dart:async';

import 'package:notsky/shared/components/no_background_cupertino_page_route.dart';
import 'package:notsky/shared/cubits/follow/follow_cubit.dart';
import 'package:notsky/shared/cubits/follow/follow_state.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isSpecificSearch = false;
  List<dynamic> _searchResults = [];
  String? _errorMessage;
  Timer? _debounce;

  List<Post> _topPosts = [];
  List<Post> _latestPosts = [];
  List<Actor> _people = [];
  List<FeedGeneratorView> _feeds = [];
  String? _feedsCursor;
  final Map<String, bool> _followingStatus = {};
  final Map<String, bool> _followingLoading = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _handleTabChange() {
    if (_searchQuery.isNotEmpty) {
      _performSearch();
    }
  }

  void _clearSearch() {
    setState(() {
      _searchResults = [];
      _errorMessage = null;
    });
  }

  Widget _buildDrawer() {
    return Container(
      width: 350.0,
      color: Theme.of(context).colorScheme.surfaceContainer,
    );
  }

  Future<void> _performSearch() async {
    if (_searchQuery.isEmpty) {
      _clearSearch();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (!_isSpecificSearch) {
      try {
        final blueskyService = context.read<AuthCubit>().getBlueskyService();

        final results = await blueskyService.searchActors(_searchQuery);

        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Error performing search: ${e.toString()}';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final blueskyService = context.read<AuthCubit>().getBlueskyService();

      switch (_tabController.index) {
        case 0: // Top
          final results = await blueskyService.searchPosts(
            _searchQuery,
            sortBy: 'relevance',
          );
          setState(() {
            _topPosts = results;
          });
          break;
        case 1: // Latest
          final results = await blueskyService.searchPosts(
            _searchQuery,
            sortBy: 'recency',
          );
          setState(() {
            _latestPosts = results;
          });
          break;
        case 2: // People
          final results = await blueskyService.searchActors(_searchQuery);
          setState(() {
            _people = results;
          });
          break;
        case 3: // Feeds
          final results = await blueskyService.searchFeeds(
            _searchQuery,
            cursor: _feedsCursor,
          );
          setState(() {
            _feedsCursor = results.cursor;
            _feeds = results.feeds;
          });
          break;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error performing search: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canPop = Navigator.canPop(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, 60.0),
        child: Builder(
          builder:
              (context) => Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.25),
                    ),
                  ),
                ),
                child: AppBar(
                  leading: IconButton(
                    icon: Icon(Icons.menu),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  scrolledUnderElevation: 0,
                  title: Text('Search'),
                ),
              ),
        ),
      ),
      drawer: canPop ? null : _buildDrawer(),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color:
                      _searchQuery.isNotEmpty && !_isSpecificSearch
                          ? Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.25)
                          : Colors.transparent,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              onTap: () {
                setState(() {
                  _isSpecificSearch = false;
                });
              },
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users, posts, or topics...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 8.0,
                ),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear, size: 20.0),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                            _clearSearch();
                          },
                        )
                        : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });

                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  if (_searchQuery.isNotEmpty) {
                    _performSearch();
                  } else {
                    _clearSearch();
                  }
                });
              },
            ),
          ),
          if (_isSpecificSearch) ...[
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Top'),
                Tab(text: 'Latest'),
                Tab(text: 'People'),
                Tab(text: 'Feeds'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPostsList(_topPosts),
                  _buildPostsList(_latestPosts),
                  _buildPeopleList(_people),
                  _buildFeedsList(_feeds),
                ],
              ),
            ),
          ],
          if (!_isSpecificSearch)
            Expanded(
              child:
                  _searchQuery.isEmpty
                      ? const Center(child: Text('Enter a search term'))
                      : _searchResults.isEmpty && !_isLoading
                      ? const Center(child: Text('No results found'))
                      : ListView.builder(
                        itemCount: _searchResults.length + 1,
                        itemBuilder: (context, index) {
                          return index == 0
                              ? _buildSearchPlaceholder(_searchQuery)
                              : _buildSearchResultItem(
                                _searchResults[index - 1],
                              );
                        },
                      ),
            ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostsList(List<Post> posts) {
    return posts.isEmpty && !_isLoading
        ? const Center(child: Text('No posts found'))
        : ListView.separated(
          separatorBuilder:
              (context, index) => Divider(
                height: 1.0,
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.25),
              ),
          itemCount: posts.length,
          itemBuilder: (context, index) => _buildPostResultItem(posts[index]),
        );
  }

  Widget _buildPeopleList(List<Actor> people) {
    return people.isEmpty && !_isLoading
        ? const Center(child: Text('No people found'))
        : ListView.separated(
          separatorBuilder:
              (context, index) => Divider(
                height: 1.0,
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.25),
              ),
          itemCount: people.length,
          itemBuilder: (context, index) => _buildActorResultItem(people[index]),
        );
  }

  Widget _buildFeedsList(List<FeedGeneratorView> feeds) {
    final sortedFeeds = List<FeedGeneratorView>.of(feeds)
      ..sort((a, b) => b.likeCount.compareTo(a.likeCount));

    return feeds.isEmpty && !_isLoading
        ? const Center(child: Text('No feeds found'))
        : ListView.separated(
          separatorBuilder:
              (context, index) => Divider(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.25),
              ),
          itemCount: sortedFeeds.length,
          itemBuilder:
              (context, index) => _buildFeedResultItem(sortedFeeds[index]),
        );
  }

  Widget _buildFeedResultItem(FeedGeneratorView feed) {
    return AuthorFeedItemComponent(feed: feed);
  }

  Widget _buildSearchPlaceholder(String query) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isSpecificSearch = true;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.25),
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Text('Search for "$query"'),
      ),
    );
  }

  Widget _buildSearchResultItem(dynamic item) {
    if (item is Actor) {
      return _buildActorResultItem(item);
    } else if (item is Post) {
      return _buildPostResultItem(item);
    } else {
      return const ListTile(title: Text('Unknown result type'));
    }
  }

  Widget _buildActorResultItem(Actor actor) {
    return BlocBuilder<FollowCubit, FollowState>(
      builder: (context, followState) {
        if (followState is FollowLoaded) {
          context.read<FollowCubit>().initializeFollowingStatus(
            actor.did,
            actor.viewer.isFollowing,
          );

          final isFollowing =
              followState.followingStatus[actor.did] ??
              actor.viewer.isFollowing;
          final isLoading = followState.followingLoading[actor.did] ?? false;

          return AuthorTileComponent(
            actor: actor,
            isFollowing: isFollowing,
            isLoading: isLoading,
            onFollowTap: (_) {
              try {
                context.read<FollowCubit>().toggleFollow(
                  actor.did,
                  actor.viewer.following,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update following status: $e'),
                  ),
                );
              }
            },
            onTap: () {
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
                          child: ProfilePage(actorDid: actor.did),
                        ),
                      ),
                ),
              );
            },
          );
        }

        return AuthorTileComponent(
          actor: actor,
          isFollowing: actor.viewer.isFollowing,
          onFollowTap: (_) {
            try {
              context.read<FollowCubit>().toggleFollow(
                actor.did,
                actor.viewer.following,
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to update following status: $e'),
                ),
              );
            }
          },
          onTap: () {},
        );
      },
    );
  }

  Widget _buildPostResultItem(Post post) {
    return ListTile(
      leading:
          post.author.avatar != null
              ? CircleAvatar(backgroundImage: NetworkImage(post.author.avatar!))
              : const CircleAvatar(child: Icon(Icons.person)),
      title: Text(post.author.displayName ?? post.author.handle),
      subtitle: Text(post.record.text),
      onTap: () {},
    );
  }
}
