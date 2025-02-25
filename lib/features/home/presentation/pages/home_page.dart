import 'package:flutter/material.dart';
import 'package:notsky/features/feed/presentation/components/feed_component.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, 60.0),
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
          ),
        ),
      ),
      body: FeedComponent(),
    );
  }
}
