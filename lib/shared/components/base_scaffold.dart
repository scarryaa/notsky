import 'package:flutter/material.dart';
import 'package:notsky/features/home/presentation/pages/home_page.dart';
import 'package:notsky/features/messages/presentation/pages/messages_page.dart';
import 'package:notsky/features/notifications/presentation/pages/notifications_page.dart';
import 'package:notsky/features/profile/presentation/pages/profile_page.dart';
import 'package:notsky/features/search/presentation/pages/search_page.dart';

class BaseScaffold extends StatefulWidget {
  const BaseScaffold({super.key});

  @override
  State<BaseScaffold> createState() => _BaseScaffoldState();
}

class _BaseScaffoldState extends State<BaseScaffold> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
      body:
          <Widget>[
            const HomePage(),
            const SearchPage(),
            const MessagesPage(),
            const NotificationsPage(),
            const ProfilePage(),
          ][_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        child: NavigationBar(
          onDestinationSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedIndex: _selectedIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          destinations: const <Widget>[
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(
              selectedIcon: Icon(Icons.search_rounded),
              icon: Icon(Icons.search_outlined),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Badge(label: Text('2'), child: Icon(Icons.messenger_sharp)),
              label: 'Messages',
            ),
            NavigationDestination(
              icon: Badge(child: Icon(Icons.notifications)),
              label: 'Notifications',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_circle),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
