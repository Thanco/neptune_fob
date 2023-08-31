// Copyright Terry Hancock 2023

import 'package:flutter/material.dart';
import 'package:neptune_fob/data/profile.dart';
import 'package:neptune_fob/data/text_style_handler.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key, required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
          child: Image.memory(
            profile.imageBytes,
            height: 128,
            width: 128,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.person,
                size: 110,
              );
            },
          ),
        ),
        Text(
          profile.userName,
          style: TextStyle(
            // fontSize: 12,
            fontFamily: TextStyleHandler().font,
            fontSize: 20,
            color: profile.color,
          ),
        ),
      ],
    );
  }
}
