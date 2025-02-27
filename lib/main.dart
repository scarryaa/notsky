import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_state.dart';
import 'package:notsky/features/auth/presentation/pages/login_page.dart';
import 'package:notsky/features/feed/data/providers/feed_repository_provider.dart';
import 'package:notsky/features/home/presentation/cubits/feed_list_cubit.dart';
import 'package:notsky/shared/components/base_scaffold.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NotSkyApp());
}

class NotSkyApp extends StatelessWidget {
  const NotSkyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthCubit()..checkAuthStatus()),
      ],
      child: MaterialApp(
        title: 'notsky',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            floatingLabelStyle: const TextStyle(backgroundColor: Colors.white),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            floatingLabelStyle: const TextStyle(),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ),
        home: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthSuccess) {
              return BlocProvider(
                create:
                    (context) => FeedListCubit(
                      feedRepository:
                          FeedRepositoryProvider.provideFeedRepository(
                            state,
                            context.read<AuthCubit>(),
                          ),
                    )..loadFeeds(),
                child: const BaseScaffold(),
              );
            }
            return const LoginPage();
          },
        ),
        routes: {
          '/login': (context) => const LoginPage(),
          '/home':
              (context) => BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  return BlocProvider(
                    create:
                        (context) => FeedListCubit(
                          feedRepository:
                              FeedRepositoryProvider.provideFeedRepository(
                                state,
                                context.read<AuthCubit>(),
                              ),
                        )..loadFeeds(),
                    child: const BaseScaffold(),
                  );
                },
              ),
        },
      ),
    );
  }
}
