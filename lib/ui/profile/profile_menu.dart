// Copyright Terry Hancock 2023

import 'package:flutter/material.dart';
import 'package:neptune_fob/data/chat_handler.dart';
import 'package:neptune_fob/data/profile_handler.dart';
import 'package:neptune_fob/data/socket_handler.dart';
import 'package:neptune_fob/main.dart';
import 'package:neptune_fob/ui/input_prompt.dart';
import 'package:neptune_fob/ui/profile/profile_card.dart';
import 'package:neptune_fob/ui/profile/profile_creation.dart';

class ProfileMenu extends StatefulWidget {
  const ProfileMenu({super.key});

  @override
  State<ProfileMenu> createState() => _ProfileMenuState();
}

class _ProfileMenuState extends State<ProfileMenu> {
  @override
  Widget build(BuildContext context) {
    final List<Widget> profiles = [];
    ProfileHandler().profiles.forEach((name, profile) {
      profiles.add(
        MaterialButton(
          onPressed: () {},
          child: GestureDetector(
            onTap: () {
              SocketHandler().setUsername(profile.userName);
              Navigator.of(context).pop();
            },
            onSecondaryTap: () => showDialog(
              context: context,
              builder: (context) => ProfileCreation(
                baseProfile: profile.userName,
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
                        if (controller.text == profile.userName) {
                          SocketHandler().removeProfile(profile.userName);
                          ProfileHandler().profiles.remove(profile.userName);
                          setState(() {});
                          Navigator.of(context).pop();
                        }
                      },
                    );
                  });
            },
            child: ProfileCard(profile: profile),
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
