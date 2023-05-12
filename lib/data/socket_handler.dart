// Copyright Terry Hancock 2023
import 'dart:io';
import 'dart:typed_data';

import 'package:neptune_fob/data/chat_handler.dart';
import 'package:neptune_fob/data/server_handler.dart';
import 'package:neptune_fob/ui/chat_item.dart';
import 'package:neptune_fob/data/user_handler.dart';
import 'package:neptune_fob/ui/typing_status.dart';
import 'package:socket_io_client/socket_io_client.dart';

class SocketHandler {
  static final SocketHandler _instance = SocketHandler._constructor();
  late Socket _socket;
  String userName = '';

  String get uri => _socket.io.uri;
  set uri(String uri) {
    _socket.io.uri = uri;
  }

  bool get connected => _socket.connected;

  factory SocketHandler() {
    return _instance;
  }

  SocketHandler._constructor() {
    _socket = io(
      '',
      OptionBuilder()
          .setTransports(['websocket'])
          // .setExtraHeaders({
          //   "maxHttpBufferSize": 50000000,
          //   "pingTimeout": 600000,
          // })
          .disableAutoConnect()
          .build(),
    );
    _initSocketRecievers();
  }

  void _initSocketRecievers() {
    _socket.onConnect((data) {
      ChatHandler().changeChannel('Default');
      if (userName != '') {
        _socket.emit('usernameSet', userName);
        ChatHandler().clearLists();
        UserHandler().clearUsers();
      }
    });
    _socket
        .onConnectError((error) => ChatHandler().addChatItem(ChatItem(-1, 'System', 'Default', 't', 'Error! $error')));
    _socket.onConnectTimeout((data) =>
        ChatHandler().addChatItem(ChatItem(-1, 'System', 'Default', 't', 'Im going to stop trying now :) (timeout)')));
    _socket.on(
      'chatMessage',
      (message) {
        ChatItem newMessage = ChatItem.fromJson(message);
        ChatHandler().addNewChatItem(newMessage);
        TypingHandler().userNoLongerTyping(newMessage.userName);
      },
    );
    _socket.on('backlogFill', (itemJson) {
      ChatItem backlogMessage = ChatItem.fromJson(itemJson);
      ChatHandler().addChatItem(backlogMessage);
    });
    _socket.on('image', (imageMessage) {
      ChatItem newImage = ChatItem.fromJson(imageMessage.first);
      ChatHandler().addNewChatItem(newImage);

      // ack response
      imageMessage.last(null);
    });
    _socket.on('backlogImage', (imageMessage) {
      ChatItem newImage = ChatItem.fromJson(imageMessage.first);
      ChatHandler().addChatItem(newImage);

      // ack response
      imageMessage.last(null);
    });
    _socket.on('usernameSend', (clientUserName) {
      userName = clientUserName;
      ServerHandler().addServer();
    });
    _socket.on('userListSend', (userList) {
      UserHandler().addUsers(userList.cast<String>());
    });
    _socket.on('userJoin', (userName) => UserHandler().addUser(userName));
    _socket.on('userLeave', (userName) => UserHandler().removeUser(userName));
    _socket.on('userTyping', (itemJson) {
      ChatItem item = ChatItem.fromJson(itemJson);
      TypingHandler().userIsTyping(item);
    });
    _socket.on('edit', (itemJson) {
      ChatItem editItem = ChatItem.fromJson(itemJson);
      ChatHandler().editItem(editItem);
    });
    _socket.on('delete', (itemJson) {
      ChatItem deleteItem = ChatItem.fromJson(itemJson);
      ChatHandler().deleteItem(deleteItem);
    });
  }

  void connect() {
    _socket.connect();
  }

  void disconnect() {
    _socket.disconnect();
  }

  void setUsername(String userName) {
    _socket.emit('usernameSet', userName);
  }

  void submitEdit(int editIndex, String editText) {
    ChatHandler messages = ChatHandler();
    ChatItem? initialItem = messages.getItem(messages.getCurrentChannel(), editIndex);
    if (initialItem == null) {
      return;
    }
    ChatItem editItem =
        ChatItem(initialItem.itemIndex, initialItem.userName, initialItem.channel, initialItem.type, editText);
    _socket.emit('edit', editItem.toJson().toString());
  }

  void requestDelete(int editIndex) {
    ChatHandler messages = ChatHandler();
    ChatItem? deleteItem = messages.getItem(messages.getCurrentChannel(), editIndex);
    if (deleteItem == null) {
      return;
    }
    _socket.emit('delete', deleteItem.toJson().toString());
  }

  void changeServer(String serverURL) {
    if (_socket.connected) {
      _socket.disconnect();
    }
    _socket.io.uri = serverURL;
    _socket.connect();
  }

  void sendMessage(String message) {
    ChatItem item = ChatItem(-1, userName, ChatHandler().getCurrentChannel(), 't', message);
    _socket.emit('chatMessage', item.toJson().toString());
  }

  Future<Uint8List> _getImage(File image) async {
    return await image.readAsBytes();
  }

  void sendImageFile(String path) async {
    File file = File(path);
    Uint8List bytes = await _getImage(file);
    sendImageBytes(bytes);
  }

  void sendImageBytes(Uint8List bytes) async {
    ChatItem item = ChatItem(-1, userName, ChatHandler().getCurrentChannel(), 'i', bytes);
    _socket.emitWithBinary('image', item.toJson().toString());
  }

  void requestMore() {
    ChatHandler chatHandler = ChatHandler();
    ChatItem item = ChatItem(chatHandler.getOldestItemIndex(chatHandler.getCurrentChannel()), userName,
        chatHandler.getCurrentChannel(), 'r', null);
    _socket.emit('messageRequest', item.toJson().toString());
  }

  void sendTypingPing() {
    _socket.emit('userTyping', ChatItem(-1, userName, ChatHandler().getCurrentChannel(), 't', 't').toJson().toString());
  }
}
