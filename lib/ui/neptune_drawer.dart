// Copyright Terry Hancock 2023
import 'package:flutter/material.dart';
import 'package:neptune_fob/data/chat_handler.dart';
import 'package:neptune_fob/data/new_client_calls.dart';
import 'package:neptune_fob/data/profile_handler.dart';
import 'package:neptune_fob/data/server_handler.dart';
import 'package:neptune_fob/data/socket_handler.dart';
import 'package:neptune_fob/data/text_style_handler.dart';
import 'package:neptune_fob/main.dart';
import 'package:neptune_fob/ui/profile/profile_card.dart';
import 'package:neptune_fob/ui/profile/profile_menu.dart';
import 'package:provider/provider.dart';

class NeptuneDrawer extends StatefulWidget {
  const NeptuneDrawer({super.key});

  @override
  State<NeptuneDrawer> createState() => _NeptuneDrawerState();
}

class _NeptuneDrawerState extends State<NeptuneDrawer> {
  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Material(
        type: MaterialType.card,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Consumer<TextStyleHandler>(
                builder: (context, value, child) {
                  return Text(
                    'Settings',
                    textScaleFactor: 1.75,
                    style: TextStyle(
                      fontFamily: value.font,
                    ),
                  );
                },
              ),
              const SizedBox(
                height: 15,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Consumer<TextStyleHandler>(
                    builder: (context, textStyleHandler, child) => Text(
                      'Font Size: ${textStyleHandler.fontSize.floor()}   ',
                      style: TextStyle(
                        fontFamily: textStyleHandler.font,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const Spacer(),
                  MaterialButton(
                    onPressed: TextStyleHandler().decreaseFontSize,
                    minWidth: 25,
                    color: NeptuneFOB.color,
                    hoverColor: Colors.amber,
                    child: const Icon(Icons.text_decrease),
                  ),
                  const SizedBox(width: 10),
                  MaterialButton(
                    onPressed: TextStyleHandler().increaseFontSize,
                    minWidth: 25,
                    color: NeptuneFOB.color,
                    hoverColor: Colors.amber,
                    child: const Icon(Icons.text_increase),
                  ),
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              Consumer<TextStyleHandler>(
                builder: (context, textStyleHandler, child) => Row(
                  children: [
                    Text(
                      'Font:',
                      style: TextStyle(
                        fontFamily: textStyleHandler.font,
                        fontSize: 22,
                      ),
                    ),
                    const Spacer(),
                    DropdownButton(
                        value: TextStyleHandler().font,
                        style: TextStyle(
                          fontFamily: textStyleHandler.font,
                          fontSize: 22,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: '',
                            child: Text('Roboto'),
                          ),
                          DropdownMenuItem(
                            value: 'CenturyGothic',
                            child: Text('CenturyGothic'),
                          ),
                          DropdownMenuItem(
                            value: 'Helvetica',
                            child: Text('Helvetica'),
                          ),
                          DropdownMenuItem(
                            value: 'ComicSans',
                            child: Text('ComicSans'),
                          ),
                          DropdownMenuItem(
                            value: 'Impact',
                            child: Text('Impact'),
                          ),
                        ],
                        onChanged: (newFont) {
                          try {
                            TextStyleHandler().changeFont(newFont!);
                          } catch (e) {
                            TextStyleHandler().changeFont('Roboto');
                          }
                        }),
                  ],
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              // Consumer<TextStyleHandler>(
              //   builder: (context, textStyleHandler, child) => Row(
              //     children: [
              //       Text(
              //         'Username: ${SocketHandler().userName}  ',
              //         style: TextStyle(
              //           fontFamily: textStyleHandler.font,
              //           fontSize: 22,
              //         ),
              //       ),
              //       const Spacer(),
              //       MaterialButton(
              //         onPressed: () => NewClientCalls().changeUserName(context),
              //         minWidth: 25,
              //         color: NeptuneFOB.color,
              //         hoverColor: Colors.amber,
              //         child: Text(
              //           'Change',
              //           style: TextStyle(
              //             fontFamily: textStyleHandler.font,
              //             fontSize: 22,
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              SizedBox(
                height: 120,
                width: 100,
                child: ProfileCard(profile: ProfileHandler().profiles[SocketHandler().userName]!),
              ),
              const SizedBox(height: 10),
              Center(
                child: MaterialButton(
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return const ProfileMenu();
                        });
                  },
                  minWidth: 25,
                  color: NeptuneFOB.color,
                  hoverColor: Colors.amber,
                  child: Consumer<TextStyleHandler>(
                    builder: (context, textStyleHandler, child) => Text(
                      'Change Profile',
                      style: TextStyle(
                        fontFamily: textStyleHandler.font,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 25,
              ),
              Row(
                children: [
                  Consumer<TextStyleHandler>(
                    builder: (context, textStyleHandler, child) => Text(
                      'Servers:',
                      style: TextStyle(
                        fontFamily: textStyleHandler.font,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const Spacer(),
                  DropdownButton(
                    value: SocketHandler().uri,
                    items: ServerHandler().serverItemList,
                    onChanged: (serverURL) => SocketHandler().changeServer(serverURL!),
                  ),
                ],
              ),
              const SizedBox(
                height: 25,
              ),
              Center(
                child: MaterialButton(
                  onPressed: () => NewClientCalls().changeServerAddress(context),
                  minWidth: 25,
                  color: NeptuneFOB.color,
                  hoverColor: Colors.amber,
                  child: Consumer<TextStyleHandler>(
                    builder: (context, textStyleHandler, child) => Text(
                      'Change Server Address',
                      style: TextStyle(
                        fontFamily: textStyleHandler.font,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
