// Copyright Terry Hancock 2023

import 'dart:convert';

import 'package:biometric_storage/biometric_storage.dart';
import 'package:neptune_fob/data/server_handler.dart';
import 'package:neptune_fob/data/socket_handler.dart';
import 'package:neptune_fob/data/text_style_handler.dart';

class SettingsHandler {
  static final SettingsHandler _instance = SettingsHandler._constructor();

  factory SettingsHandler() {
    return _instance;
  }
  SettingsHandler._constructor() {
    _initSettings();
  }

  void _initSettings() async {
    if ((await BiometricStorage().canAuthenticate()) != CanAuthenticateResponse.success) {
      // TODO bro idk tbh
    }
    final BiometricStorageFile settingsStore = await BiometricStorage().getStorage('settings');
    final String? settingsJson = await settingsStore.read();
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
  }

  void saveSettings() async {
    final Map settings = {
      '"currentServer"': '"${SocketHandler().uri}"',
      '"username"': '"${SocketHandler().userName}"',
      '"font"': '"${TextStyleHandler().font}"',
      '"fontSize"': TextStyleHandler().fontSize,
      '"serverList"': '"${ServerHandler().serverList.toString()}"',
    };
    final BiometricStorageFile settingsStore = await BiometricStorage().getStorage(
      'settings',
      options: StorageFileInitOptions(
        authenticationRequired: false,
      ),
    );
    settingsStore.write(settings.toString());
  }
}
