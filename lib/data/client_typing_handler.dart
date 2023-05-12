// Copyright Terry Hancock 2023
import 'package:neptune_fob/data/socket_handler.dart';

class ClientTypingHandler {
  static final ClientTypingHandler _instance = ClientTypingHandler._contstructor();
  final Stopwatch _sentTypingPing = Stopwatch();

  factory ClientTypingHandler() {
    return _instance;
  }

  ClientTypingHandler._contstructor() {
    _sentTypingPing.start();
  }

  void thisClientTyping() {
    if (_sentTypingPing.elapsedMilliseconds > 1000) {
      SocketHandler().sendTypingPing();
      _sentTypingPing.reset();
    }
  }
}
