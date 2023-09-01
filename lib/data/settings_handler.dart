// Copyright Terry Hancock 2023

import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:neptune_fob/data/chat_handler.dart';
import 'package:neptune_fob/data/chat_item.dart';
import 'package:neptune_fob/data/new_client_calls.dart';
import 'package:neptune_fob/data/server_handler.dart';
import 'package:neptune_fob/data/socket_handler.dart';
import 'package:neptune_fob/data/text_style_handler.dart';
import 'package:neptune_fob/ui/input_prompt.dart';
import 'package:path_provider/path_provider.dart';

class SettingsHandler {
  SettingsHandler();
  SettingsHandler.init(BuildContext context) {
    _initSettings(context);
  }

  void _initSettings(BuildContext context) async {
    if ((kIsWeb || !Platform.isWindows) &&
        await BiometricStorage().canAuthenticate().then((value) => value != CanAuthenticateResponse.success)) {
      NewClientCalls().newClientCalls(context);
      return;
      // TODO bro idk tbh
    }
    try {
      final String? settingsJson = await BiometricStorage().getStorage('settings').then((value) => value.read());
      final Map settings = jsonDecode(settingsJson!);
      SocketHandler().uri = settings['currentServer'];
      if (!SocketHandler().connected && SocketHandler().uri.isNotEmpty) {
        SocketHandler().connect();
      }
      SocketHandler().userName = settings['username'];
      TextStyleHandler().font = settings['font'];
      TextStyleHandler().fontSize = settings['fontSize'];
      if (settings['notificationSound'].isNotEmpty) {
        ChatHandler().notificationSound = DeviceFileSource(settings['notificationSound']);
      }
      String serverListJson = settings['serverList'];
      serverListJson = serverListJson.substring(1, (serverListJson.length - 1));
      final List<String> servers = serverListJson.split(", ");
      for (int i = 0; i < servers.length; i++) {
        if (!ServerHandler().serverList.contains(servers[i]) && !(servers[i] == '')) {
          ServerHandler().serverList.add(servers[i]);
        }
      }
      ServerHandler().setServerItems();
    } finally {
      NewClientCalls().newClientCalls(context);
    }
  }

  void saveSettings() async {
    final Map settings = {
      '"currentServer"': '"${SocketHandler().uri}"',
      '"username"': '"${SocketHandler().userName}"',
      '"font"': '"${TextStyleHandler().font}"',
      '"fontSize"': TextStyleHandler().fontSize,
      '"serverList"': '"${ServerHandler().serverList.toString()}"',
      '"notificationSound"': '"${ChatHandler().notificationSound?.path.toString() ?? ''}"'
    };
    BiometricStorage().getStorage('settings').then((value) => value.write(settings.toString()));
  }

  void saveImage(BuildContext context, ChatItem item) {
    if (item.type != 'i') {
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return InputPrompt(
          controller: controller,
          formTitle: 'What should the image name be?',
          onSubmit: () async {
            Navigator.of(context).pop();
            Directory? appDocumentsDirectory = await getDownloadsDirectory();
            String filePath = '${appDocumentsDirectory!.path}/${controller.text}.jpeg';
            File imageFile = File(filePath);
            await imageFile.writeAsBytes(item.content);
          },
        );
      },
    );
  }
}
