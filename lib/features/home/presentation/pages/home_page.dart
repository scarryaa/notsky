import 'package:flutter/material.dart';
import 'package:notsky/features/feed/presentation/components/feed_component.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
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
              child: TabBar(
                tabs: [Tab(text: 'Following', height: 32.0)],
                controller: _tabController,
              ),
            ),
          ),
        ),
      ),
      body: FeedComponent(isTimeline: true),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Container(
      width: 350.0,
      color: Theme.of(context).colorScheme.surfaceContainer,
    );
  }
}
