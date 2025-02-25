import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NoBackgroundCupertinoPageRoute<T> extends CupertinoPageRoute<T> {
  NoBackgroundCupertinoPageRoute({required super.builder, super.settings});

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final Widget coloredChild = Container(
      color: Theme.of(context).colorScheme.surface,
      child: child,
    );

    return super.buildTransitions(
      context,
      animation,
      secondaryAnimation,
      coloredChild,
    );
  }
}
