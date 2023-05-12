// Copyright Terry Hancock 2023
import 'package:flutter/material.dart';

class ImageView extends StatelessWidget {
  final Image image;

  const ImageView({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(0, 0, 0, 0),
      appBar: AppBar(
        title: const Text('Project Neptune FOB'),
      ),
      body: Center(
        child: MaterialButton(
          hoverColor: const Color.fromARGB(0, 0, 0, 0),
          splashColor: const Color.fromARGB(0, 0, 0, 0),
          onPressed: () => Navigator.of(context).pop(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 100),
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                width: MediaQuery.of(context).size.width * 0.8,
                child: image,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
