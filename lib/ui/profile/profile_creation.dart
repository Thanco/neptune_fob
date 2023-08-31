// Copyright Terry Hancock 2023

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:neptune_fob/data/chat_handler.dart';
import 'package:neptune_fob/data/profile.dart';
import 'package:neptune_fob/data/profile_handler.dart';
import 'package:neptune_fob/data/socket_handler.dart';
import 'package:neptune_fob/main.dart';
import 'package:pasteboard/pasteboard.dart';

class ProfileCreation extends StatefulWidget {
  const ProfileCreation({super.key, required this.baseProfile, required this.onSubmit});
  final String baseProfile;
  final void Function() onSubmit;

  @override
  State<ProfileCreation> createState() => _ProfileCreationState();
}

class _ProfileCreationState extends State<ProfileCreation> {
  final controller = TextEditingController();
  Uint8List? _imageBytes;
  Color color = NeptuneFOB.color;
  bool init = false;

  void _pasteImage() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null) {
      // _controller.text = _controller.text + data.text!;
      return;
    }
    _imageBytes = await Pasteboard.image;
    if (_imageBytes == null) {
      List<String> files = await Pasteboard.files();
      File file = File(files.single);
      if (!_isStaticImage(file.path)) {
        return;
      }
      _imageBytes = await file.readAsBytes();
    }

    setState(() {});
  }

  bool _isStaticImage(String filePath) {
    if (filePath.endsWith('.png') || filePath.endsWith('.jpg') || filePath.endsWith('.jpeg')) {
      return true;
    }
    return false;
  }

  void _addProfile(TextEditingController controller) {
    // TODO add profile
    Profile newProfile = Profile(controller.text, _imageBytes!, color);
    SocketHandler().addProfile(newProfile);
    ProfileHandler().addProfiles([newProfile]);

    widget.onSubmit.call();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (!init) {
      Profile baseProfile = ProfileHandler().profiles[widget.baseProfile] ?? Profile.blank('');
      controller.text = baseProfile.userName;
      _imageBytes = baseProfile.imageBytes;
      color = baseProfile.color;
      init = true;
    }

    return Center(
      child: SizedBox(
        height: 640,
        width: 512,
        child: Material(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enter a Profile Name:'),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Type here...',
                    ),
                    textAlign: TextAlign.center,
                    onSubmitted: (value) => _addProfile(controller),
                  ),
                  const SizedBox(height: 10),
                  const Text('Copy an image, then click below to add a profile picutre:'),
                  const SizedBox(height: 10),
                  MaterialButton(
                    onPressed: () {
                      _pasteImage();
                    },
                    child: Image.memory(
                      _imageBytes ?? Uint8List(0),
                      height: 99,
                      width: 99,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          size: 100,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Pick a Username Color:'),
                  const SizedBox(height: 10),
                  MaterialPicker(
                    pickerColor: color,
                    enableLabel: true,
                    onColorChanged: (newColor) => color = newColor,
                  ),
                  const Spacer(),
                  MaterialButton(
                    onPressed: () => _addProfile(controller),
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
