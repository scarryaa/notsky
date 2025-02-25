import 'package:flutter/material.dart';

class AvatarComponent extends StatelessWidget {
  const AvatarComponent({super.key, required this.avatar, required this.size});

  final String? avatar;
  final double size;

  @override
  Widget build(BuildContext context) {
    return (avatar != null && avatar!.isNotEmpty)
        ? ClipOval(
          child: Image.network(avatar ?? '', width: size, height: size),
        )
        : Icon(Icons.account_circle_rounded, size: size);
  }
}
