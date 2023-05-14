// Copyright Terry Hancock 2023
import 'package:flutter/material.dart';
import 'package:neptune_fob/data/socket_handler.dart';

class ServerHandler {
  static final ServerHandler _instance = ServerHandler._constructor();
  final List<String> _serverList = [];
  final List<DropdownMenuItem<String>> _serverItemList = [];

  factory ServerHandler() {
    return _instance;
  }
  ServerHandler._constructor();

  List<String> get serverList => _serverList;
  List<DropdownMenuItem<String>> get serverItemList => _serverItemList;

  void addServer() {
    _serverList.removeWhere((element) => element == '');
    final String uri = SocketHandler().uri;
    if (uri.isEmpty) {
      return;
    }
    if (!_serverList.contains(uri)) {
      _serverList.add(uri);
      if (_serverList.length > 5) {
        _serverList.remove(_serverList.first);
      }
    } else {
      _serverList.remove(uri);
      _serverList.add(uri);
    }
    setServerItems();
  }

  void setServerItems() {
    _serverItemList.clear();
    final List<String> serverList = ServerHandler().serverList;
    for (var i = serverList.length - 1; i >= 0; i--) {
      _serverItemList.add(
        DropdownMenuItem(
          value: serverList[i],
          child: Text(serverList[i]),
        ),
      );
    }
  }
}
