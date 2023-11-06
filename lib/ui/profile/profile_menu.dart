// Copyright Terry Hancock 2023

import 'package:flutter/material.dart';
import 'package:neptune_fob/data/profile_handler.dart';
import 'package:neptune_fob/data/socket_handler.dart';
import 'package:neptune_fob/data/text_style_handler.dart';
import 'package:neptune_fob/main.dart';
import 'package:neptune_fob/ui/input_prompt.dart';
import 'package:neptune_fob/ui/profile/profile_card.dart';
import 'package:neptune_fob/ui/profile/profile_creation.dart';

class ProfileMenu extends StatefulWidget {
  const ProfileMenu({super.key, required this.profiles});
  final Map<String, dynamic> profiles;

  @override
  State<ProfileMenu> createState() => _ProfileMenuState();
}

class _ProfileMenuState extends State<ProfileMenu> {
  Map<String, dynamic>? profileSources;
  int depth = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> profiles = [];
    profileSources ??= widget.profiles;
    if (depth > 0) {
      profiles.add(
        MaterialButton(
          onPressed: () {
            var split = profileSources!.entries.first.key.split("/");
            if (split.last == "") {
              split = split.sublist(0, split.length - 1);
            }
            split = split.sublist(0, split.length - 2);
            var previous = widget.profiles;
            var current = "";
            for (var element in split) {
              previous = previous["$current$element/"] as Map<String, dynamic>;
              current += "$element/";
            }
            profileSources = previous;
            depth--;
            setState(() {});
          },
          child: const Icon(Icons.arrow_back),
        ),
      );
    }
    profileSources!.forEach((name, value) {
      bool folder = name.endsWith("/");
      if (folder) {
        profiles.add(
          MaterialButton(
            onPressed: () {},
            child: GestureDetector(
              onTap: () {
                profileSources = value;
                depth++;
                setState(() {});
              },
              onLongPress: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      if (value.isNotEmpty) {
                        return const AlertDialog(
                          title: Text('Folder is not empty'),
                          content: Text('Please delete all profiles in the folder before deleting the folder'),
                        );
                      }
                      final controller = TextEditingController();
                      return InputPrompt(
                        controller: controller,
                        formTitle: 'To delete folder, enter the name of the folder and press submit',
                        onSubmit: () {
                          if (controller.text == name.substring(0, name.length - 1)) {
                            // SocketHandler().removeProfile(profile.userName);
                            ProfileHandler().removeFolder(name); //TODO TEST
                            setState(() {});
                            Navigator.of(context).pop();
                          }
                        },
                      );
                    });
              },
              child: Column(
                children: [
                  const Flexible(
                    child: Icon(
                      Icons.folder,
                      size: 110,
                      color: NeptuneFOB.color,
                    ),
                  ),
                  Text(
                    name.substring(0, name.length - 1),
                    style: TextStyle(
                      fontFamily: TextStyleHandler().font,
                      fontSize: 20,
                      // color: NeptuneFOB.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        return;
      }
      profiles.add(
        MaterialButton(
          onPressed: () {},
          child: GestureDetector(
            onTap: () {
              SocketHandler().setUsername(value.userName.split("/").last);
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            onSecondaryTap: () => showDialog(
              context: context,
              builder: (context) => ProfileCreation(
                baseProfile: value.userName.split("/").last,
                onSubmit: () => setState(() {}),
              ),
            ),
            onLongPress: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    final controller = TextEditingController();
                    return InputPrompt(
                      controller: controller,
                      formTitle: 'To delete profile, enter the name of the profile and press submit',
                      onSubmit: () {
                        if (controller.text == value.userName.split("/").last) {
                          SocketHandler().removeProfile(value.userName);
                          ProfileHandler().removeProfile(value.userName.split("/").last);
                          setState(() {});
                          Navigator.of(context).pop();
                        }
                      },
                    );
                  });
            },
            child: ProfileCard(profile: value),
          ),
        ),
      );
    });
    profiles.add(
      MaterialButton(
        color: NeptuneFOB.color,
        onPressed: () => showDialog(
          context: context,
          builder: (context) => ProfileCreation(
            baseProfile: '',
            onSubmit: () => setState(() {}),
          ),
        ),
        child: const Icon(Icons.add_circle),
      ),
    );

    return Center(
      child: SizedBox(
        height: 512,
        width: 512,
        child: Material(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          elevation: 2,
          child: Column(
            children: [
              const Text(
                'Select a Profile',
                style: TextStyle(
                  fontSize: 24,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 483,
                width: 512,
                child: GridView.count(
                  crossAxisSpacing: 1,
                  mainAxisSpacing: 20,
                  crossAxisCount: 4,
                  children: profiles,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
