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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: Scaffold(
        body:
            _selectedIndex == 0
                ? _buildHome()
                : Scaffold(
                  appBar: PreferredSize(
                    preferredSize: Size(double.infinity, 60.0),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
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
                        title: Text(
                          [
                            'Home',
                            'Search',
                            'Messages',
                            'Notifications',
                            'Profile',
                          ][_selectedIndex],
                        ),
                      ),
                    ),
                  ),
                  body: IndexedStack(
                    index: _selectedIndex - 1,
                    children: [
                      _buildNavigator(1, const SearchPage()),
                      _buildNavigator(2, const MessagesPage()),
                      _buildNavigator(3, const NotificationsPage()),
                      _buildNavigator(4, const ProfilePage()),
                    ],
                  ),
                ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Theme.of(context).colorScheme.outline),
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

  Widget _buildHome() {
    return Navigator(
      key: _navigatorKeys[0],
      onGenerateRoute: (RouteSettings settings) {
        return NoBackgroundCupertinoPageRoute(
          settings: settings,
          builder: (BuildContext context) {
            return const HomePage();
          },
        );
      },
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
