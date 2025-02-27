import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/feed/presentation/components/feed_component.dart';
import 'package:notsky/features/home/presentation/cubits/feed_list_cubit.dart';
import 'package:notsky/features/home/presentation/cubits/feed_list_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  final timelineKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        );

        return Scaffold(
          drawer: _buildDrawer(context),
          appBar: PreferredSize(
            preferredSize: Size(double.infinity, 90.0),
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
                              (feed) => Tab(height: 32, text: feed.displayName),
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
          body:
              state is FeedListLoaded && state.feeds.feeds.isNotEmpty
                  ? TabBarView(
                    controller: _tabController,
                    children: [
                      timelineComponent,
                      ...state.feeds.feeds.map(
                        (feed) => FeedComponent(generatorUri: feed.uri),
                      ),
                    ],
                  )
                  : timelineComponent,
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
