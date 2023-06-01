// Copyright Terry Hancock 2023
import 'package:flutter/material.dart';

class ImageView extends StatelessWidget {
  final Image image;

  const ImageView({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    Color none = const Color.fromARGB(0, 0, 0, 0);
    return MaterialButton(
      mouseCursor: MouseCursor.defer,
      hoverColor: none,
      splashColor: none,
      highlightColor: none,
      onPressed: () => Navigator.of(context).pop(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 70, 0, 100),
        child: image,
      ),
    );
  }
}
