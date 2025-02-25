import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:notsky/features/home/presentation/pages/home_page.dart';
import 'package:notsky/features/messages/presentation/pages/messages_page.dart';
import 'package:notsky/features/notifications/presentation/pages/notifications_page.dart';
import 'package:notsky/features/profile/presentation/pages/profile_page.dart';
import 'package:notsky/features/search/presentation/pages/search_page.dart';
import 'package:notsky/shared/components/no_background_cupertino_page_route.dart';

class BaseScaffold extends StatefulWidget {
  const BaseScaffold({super.key});

  @override
  State<BaseScaffold> createState() => _BaseScaffoldState();
}

class _BaseScaffoldState extends State<BaseScaffold> {
  int _selectedIndex = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  late final List<Widget> _pages = [
    _buildNavigator(0, const HomePage()),
    Scaffold(
      appBar: _buildAppBar('Search'),
      body: _buildNavigator(1, const SearchPage()),
    ),
    Scaffold(
      appBar: _buildAppBar('Messages'),
      body: _buildNavigator(2, const MessagesPage()),
    ),
    Scaffold(
      appBar: _buildAppBar('Notifications'),
      body: _buildNavigator(3, const NotificationsPage()),
    ),
    Scaffold(
      appBar: _buildAppBar('Profile'),
      body: _buildNavigator(4, const ProfilePage()),
    ),
  ];

  PreferredSizeWidget _buildAppBar(String title) {
    return PreferredSize(
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
                backgroundColor: Theme.of(context).colorScheme.surface,
                scrolledUnderElevation: 0,
                actions: [
                  IconButton(
                    onPressed: () {
                      context.read<AuthCubit>().logout();
                    },
                    icon: Icon(Icons.logout),
                  ),
                ],
                title: Text(title),
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: _pages),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.25),
              ),
            ),
          ),
          child: NavigationBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            height: 48.0,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            selectedIndex: _selectedIndex,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            indicatorColor: Colors.transparent,
            destinations: const <Widget>[
              NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(
                selectedIcon: Icon(Icons.search_rounded),
                icon: Icon(Icons.search_outlined),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Icon(Icons.message_rounded),
                label: 'Messages',
              ),
              NavigationDestination(
                icon: Icon(Icons.notifications),
                label: 'Notifications',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_circle),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigator(int index, Widget page) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (RouteSettings settings) {
        return NoBackgroundCupertinoPageRoute(
          settings: settings,
          builder: (BuildContext context) {
            if (settings.name == '/') {
              return page;
            }
            return page;
          },
        );
      },
    );
  }
}
