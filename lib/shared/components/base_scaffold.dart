import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_state.dart';
import 'package:notsky/features/feed/presentation/cubits/feed_cubit.dart';
import 'package:notsky/features/home/presentation/pages/home_page.dart';
import 'package:notsky/features/messages/presentation/pages/messages_page.dart';
import 'package:notsky/features/notifications/presentation/pages/notifications_page.dart';
import 'package:notsky/features/post/presentation/components/common/avatar_component.dart';
import 'package:notsky/features/post/presentation/controllers/bottom_nav_visibility_controller.dart';
import 'package:notsky/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:notsky/features/profile/presentation/pages/profile_page.dart';
import 'package:notsky/features/search/presentation/pages/search_page.dart';
import 'package:notsky/main.dart';
import 'package:notsky/shared/components/no_background_cupertino_page_route.dart';
import 'package:provider/provider.dart';

class BaseScaffold extends StatefulWidget {
  const BaseScaffold({super.key});

  @override
  State<BaseScaffold> createState() => _BaseScaffoldState();
}

class _BaseScaffoldState extends State<BaseScaffold> {
  final BottomNavVisibilityController _navController =
      BottomNavVisibilityController();
  int _selectedIndex = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  Widget _buildDrawer() {
    return Container(
      width: 350.0,
      color: Theme.of(context).colorScheme.surfaceContainer,
    );
  }

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
    return BlocProvider<ProfileCubit>(
      create: (context) {
        final bskyService = context.read<AuthCubit>().getBlueskyService();
        return ProfileCubit(bskyService);
      },
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthInitial) {
            // TODO handle logout?
          }
        },
        builder: (context, authState) {
          String? avatar;
          String? did;

          if (authState is AuthSuccess) {
            final profile = authState.profile;
            avatar = profile?.avatar;
            did = profile?.did;
          }

          return ChangeNotifierProvider.value(
            value: _navController,
            child: PopScope(
              child: Scaffold(
                appBar:
                    _selectedIndex == 0 || _selectedIndex == 4
                        ? null
                        : _buildAppBar(_getTitleForIndex(_selectedIndex)),
                drawer: _selectedIndex == 0 ? null : _buildDrawer(),
                body: Stack(
                  children: [
                    _buildOffstageNavigator(
                      0,
                      const HomePage(),
                      _selectedIndex == 0,
                    ),
                    _buildOffstageNavigator(
                      1,
                      const SearchPage(),
                      _selectedIndex == 1,
                    ),
                    _buildOffstageNavigator(
                      2,
                      const MessagesPage(),
                      _selectedIndex == 2,
                    ),
                    _buildOffstageNavigator(
                      3,
                      const NotificationsPage(),
                      _selectedIndex == 3,
                    ),
                    _buildOffstageNavigator(
                      4,
                      BlocProvider.value(
                        value: context.read<ProfileCubit>(),
                        child: BlocProvider(
                          create: (context) {
                            final bskyService =
                                context.read<AuthCubit>().getBlueskyService();
                            return FeedCubit(bskyService);
                          },
                          child: ProfilePage(
                            actorDid: did ?? '',
                            showBackButton: false,
                          ),
                        ),
                      ),
                      _selectedIndex == 4,
                    ),
                  ],
                ),
                bottomNavigationBar: Consumer<BottomNavVisibilityController>(
                  builder: (context, controller, child) {
                    final mediaQuery = MediaQuery.of(context);
                    final bottomNavHeight = mediaQuery.size.height * 0.08;
                    final navigationBarHeight = mediaQuery.size.height * 0.06;

                    final constrainedNavHeight = bottomNavHeight.clamp(
                      60.0,
                      88.0,
                    );
                    final constrainedBarHeight = navigationBarHeight.clamp(
                      48.0,
                      60.0,
                    );

                    final bottomPadding = mediaQuery.padding.bottom;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 1),
                      height:
                          controller.isVisible
                              ? constrainedNavHeight + bottomPadding
                              : 0.0,
                      child:
                          controller.isVisible
                              ? Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withValues(alpha: 0.25),
                                    ),
                                  ),
                                ),
                                child: NavigationBar(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.surface,
                                  height: constrainedBarHeight,
                                  onDestinationSelected: (int index) {
                                    setState(() {
                                      _selectedIndex = index;
                                    });
                                  },
                                  selectedIndex: _selectedIndex,
                                  labelBehavior:
                                      NavigationDestinationLabelBehavior
                                          .alwaysHide,
                                  indicatorColor: Colors.transparent,
                                  destinations: <Widget>[
                                    NavigationDestination(
                                      icon: Icon(Icons.home),
                                      label: 'Home',
                                    ),
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
                                      icon: AvatarComponent(
                                        actorDid: null,
                                        avatar: avatar,
                                        size: 24.0,
                                      ),
                                      label: 'Profile',
                                    ),
                                  ],
                                ),
                              )
                              : const SizedBox.shrink(),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 1:
        return 'Search';
      case 2:
        return 'Messages';
      case 3:
        return 'Notifications';
      case 4:
        return 'Profile';
      default:
        return '';
    }
  }

  Widget _buildOffstageNavigator(int index, Widget page, bool isSelected) {
    return Offstage(
      offstage: !isSelected,
      child:
          _navigatorKeys[index].currentState == null && !isSelected
              ? Container()
              : _buildNavigator(index, page),
    );
  }

  Widget _buildNavigator(int index, Widget page) {
    return Navigator(
      key: _navigatorKeys[index],
      observers: index == 0 ? [NotSkyApp.routeObservers[0]!] : [],
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
