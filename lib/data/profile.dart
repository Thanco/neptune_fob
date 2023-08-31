// Copyright Terry Hancock 2023

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:neptune_fob/main.dart';

class Profile {
  final String userName;
  late Uint8List imageBytes = Uint8List(0);
  String? compressedImageBytes;
  Color color = NeptuneFOB.color;

  Profile.blank(this.userName);
  Profile(this.userName, this.imageBytes, this.color);

  Profile.fromJson(Map<String, dynamic> json)
      : userName = json['userName'],
        imageBytes = json['imageBytes'],
        color = Color(json['color'].toInt());

  Map<String, dynamic> toJson() => {
        'userName': '"$userName"',
        'imageBytes': imageBytes,
        'compressedImageBytes': '"$compressedImageBytes"',
        'color': color.value,
      };
}
