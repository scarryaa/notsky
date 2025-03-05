import 'package:bluesky/bluesky.dart' hide ListView;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:notsky/features/feed/presentation/cubits/feed_cubit.dart';
import 'package:notsky/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:notsky/features/profile/presentation/pages/profile_page.dart';
import 'dart:async';

import 'package:notsky/shared/components/no_background_cupertino_page_route.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  List<dynamic> _searchResults = [];
  String? _errorMessage;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
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
                      _searchQuery.isNotEmpty
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
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
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
                            : _buildSearchResultItem(_searchResults[index - 1]);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchPlaceholder(String query) {
    return GestureDetector(
      onTap: () {
        // TODO
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
    return ListTile(
      leading:
          actor.avatar != null
              ? CircleAvatar(backgroundImage: NetworkImage(actor.avatar!))
              : const CircleAvatar(child: Icon(Icons.person)),
      title: Text(actor.displayName ?? actor.handle),
      subtitle: Text('@${actor.handle}'),
      onTap: () {
        Navigator.of(context).push(
          NoBackgroundCupertinoPageRoute(
            builder: (context) {
              final blueskyService =
                  context.read<AuthCubit>().getBlueskyService();

              return BlocProvider<ProfileCubit>(
                create: (context) => ProfileCubit(blueskyService),
                child: BlocProvider<FeedCubit>(
                  create: (context) => FeedCubit(blueskyService),
                  child: Builder(
                    builder: (context) {
                      return ProfilePage(actorDid: actor.did);
                    },
                  ),
                ),
              );
            },
          ),
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
