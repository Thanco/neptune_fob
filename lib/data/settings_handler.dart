// Copyright Terry Hancock 2023

import 'dart:convert';
import 'dart:io';

import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/material.dart';
import 'package:neptune_fob/data/new_client_calls.dart';
import 'package:neptune_fob/data/server_handler.dart';
import 'package:neptune_fob/data/socket_handler.dart';
import 'package:neptune_fob/data/text_style_handler.dart';

class SettingsHandler {
  SettingsHandler();
  SettingsHandler.init(BuildContext context) {
    _initSettings(context);
  }

  void _initSettings(BuildContext context) async {
    if (!Platform.isWindows &&
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
    };
    BiometricStorage()
        .getStorage(
          'settings',
        )
        .then((value) => value.write(settings.toString()));
  }
}
