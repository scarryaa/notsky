import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_state.dart';
import 'package:notsky/features/feed/presentation/components/feed_component.dart';
import 'package:notsky/features/home/presentation/cubits/feed_list_cubit.dart';
import 'package:notsky/features/home/presentation/cubits/feed_list_state.dart';
import 'package:notsky/features/post/presentation/components/reply_component.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  final timelineKey = GlobalKey();
  late ScrollController _scrollController;
  bool _isAppBarVisible = true;
  bool _showScrollTopButton = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isAppBarVisible) {
        setState(() {
          _isAppBarVisible = false;
        });
      }
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isAppBarVisible) {
        setState(() {
          _isAppBarVisible = true;
        });
      }
    }

    if (_scrollController.offset > 100.0) {
      if (!_showScrollTopButton) {
        setState(() {
          _showScrollTopButton = true;
        });
      }
    } else {
      if (_showScrollTopButton) {
        setState(() {
          _showScrollTopButton = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final state = context.watch<FeedListCubit>().state;
    if (state is FeedListLoaded && state.feeds.feeds.isNotEmpty) {
      _updateTabController(state.feeds.feeds.length + 1);
    }
  }

  void _updateTabController(int length) {
    if (_tabController.length != length) {
      final previousIndex = _tabController.index;
      _tabController.dispose();
      _tabController = TabController(length: length, vsync: this);

      if (previousIndex < length) {
        _tabController.index = previousIndex;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeedListCubit, FeedListState>(
      builder: (context, state) {
        if (state is FeedListLoaded && state.feeds.feeds.isNotEmpty) {
          _updateTabController(state.feeds.feeds.length + 1);
        }

        final timelineComponent = FeedComponent(
          key: timelineKey,
          isTimeline: true,
          scrollController: _scrollController,
        );

        return SafeArea(
          child: Scaffold(
            drawer: _buildDrawer(context),
            appBar: PreferredSize(
              preferredSize: Size(double.infinity, 90.0),
              child: AnimatedOpacity(
                opacity: _isAppBarVisible ? 1.0 : 0.0,
                duration: Duration(milliseconds: 300),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  transform: Matrix4.translationValues(
                    0,
                    _isAppBarVisible ? 0.0 : -200.0,
                    0,
                  ),
                  height: _isAppBarVisible ? 150.0 : 0,
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
                    title: Text('Home'),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    scrolledUnderElevation: 0,
                    bottom: PreferredSize(
                      preferredSize: Size(double.infinity, 20.0),
                      child: Builder(
                        builder: (context) {
                          if (state is FeedListLoaded &&
                              state.feeds.feeds.isNotEmpty) {
                            return TabBar(
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              tabs: [
                                Tab(text: 'Following', height: 32),
                                ...state.feeds.feeds.map(
                                  (feed) =>
                                      Tab(height: 32, text: feed.displayName),
                                ),
                              ],
                              controller: _tabController,
                            );
                          }

                          if (state is FeedListLoading) {
                            return Container();
                          } else if (state is FeedListError) {
                            return Text(
                              'An error occurred while loading feeds. ${state.message}',
                            );
                          } else {
                            return Container();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            body: Stack(
              children: [
                state is FeedListLoaded && state.feeds.feeds.isNotEmpty
                    ? TabBarView(
                      controller: _tabController,
                      children: [
                        timelineComponent,
                        ...state.feeds.feeds.map(
                          (feed) => FeedComponent(
                            generatorUri: feed.uri,
                            scrollController: _scrollController,
                          ),
                        ),
                      ],
                    )
                    : timelineComponent,
                _showScrollTopButton
                    ? Positioned(
                      left: 16,
                      bottom: 16,
                      child: OutlinedButton(
                        onPressed: () {
                          _scrollController.animateTo(
                            0,
                            duration: Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: CircleBorder(),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          padding: EdgeInsets.all(14),
                        ),
                        child: Icon(Icons.arrow_upward_rounded),
                      ),
                    )
                    : SizedBox.shrink(),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: IconButton(
                    constraints: BoxConstraints(
                      minWidth: 48.0,
                      minHeight: 48.0,
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        isScrollControlled: true,
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height - 250,
                          maxHeight: MediaQuery.of(context).size.height - 250,
                        ),
                        context: context,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12.0),
                          ),
                        ),
                        builder: (context) {
                          String? avatar;
                          final authState = context.read<AuthCubit>().state;
                          if (authState is AuthSuccess) {
                            final profile = authState.profile;
                            avatar = profile?.avatar;
                          }

                          return ReplyComponent(
                            hideOrWarn: null,
                            onCancel: () {
                              Navigator.pop(context);
                            },
                            onReply: (String text) {
                              final auth = context.read<AuthCubit>();
                              final blueskyService = auth.getBlueskyService();

                              blueskyService.post(text);
                              Navigator.of(context).pop();
                            },
                            replyPost: null,
                            userAvatar: avatar,
                          );
                        },
                      );
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        Theme.of(context).colorScheme.primary,
                      ),
                      foregroundColor: WidgetStatePropertyAll(
                        Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    icon: Icon(Icons.edit_square, size: 22.0),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Container(
      width: 350.0,
      color: Theme.of(context).colorScheme.surfaceContainer,
    );
  }
}
