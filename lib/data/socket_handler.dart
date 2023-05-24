// Copyright Terry Hancock 2023
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:neptune_fob/data/chat_handler.dart';
import 'package:neptune_fob/data/server_handler.dart';
import 'package:neptune_fob/data/chat_item.dart';
import 'package:neptune_fob/data/user_handler.dart';
import 'package:neptune_fob/security/encryption_handler.dart';
import 'package:neptune_fob/ui/typing_status.dart';
import 'package:socket_io_client/socket_io_client.dart';

class SocketHandler {
  static final SocketHandler _instance = SocketHandler._constructor();
  late Socket _socket;
  late final EncryptionHandler _encryptionHandler = EncryptionHandler();
  String userName = '';
  bool _currentlyRequesting = false;

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
      _socket.emit('publicKey', json.encode(_encryptionHandler.getPublicKey()));
    });
    _socket.on('sessionKey', (data) {
      _encryptionHandler.putSessionKey(data);
      _socket.emit('chatClient');
      ChatHandler().changeChannel('Default');
      if (userName != '') {
        _send('usernameSet', userName);
        ChatHandler().clearLists();
        UserHandler().clearUsers();
      }
    });
    _socket.onConnectError(
      (error) => ChatHandler().addChatItem(
        ChatItem(-1, 'System', 'Default', 't', 'Error! $error'),
      ),
    );
    _socket.onConnectTimeout((data) =>
        ChatHandler().addChatItem(ChatItem(-1, 'System', 'Default', 't', 'Im going to stop trying now :) (timeout)')));
    _socket.on(
      'chatMessage',
      (message) {
        String decryptedMessage = _encryptionHandler.decrypt(message);
        ChatItem newMessage = ChatItem.fromJson(json.decode(decryptedMessage));
        ChatHandler().addNewChatItem(newMessage);
        TypingHandler().userNoLongerTyping(newMessage.userName);
      },
    );
    _socket.on('backlogFill', (itemListJson) {
      String decryptedItemListJson = _encryptionHandler.decrypt(itemListJson);
      var items = json.decode(decryptedItemListJson);
      List<ChatItem> backlogItems = [];
      for (int i = 0; i < items.length; i++) {
        backlogItems.add(ChatItem.fromJson(items[i]));
      }
      ChatHandler().addChatItems(backlogItems);
      _currentlyRequesting = false;
    });
    _socket.on('image', (imageMessage) {
      String decryptedImageMessage = _encryptionHandler.decrypt(imageMessage.first);
      // var items = json.decode(decryptedImageMessage);
      Map<String, dynamic> itemJson = json.decode(decryptedImageMessage);
      List<dynamic> imageBytes = itemJson['content'];
      itemJson['content'] = Uint8List(imageBytes.length)..setRange(0, imageBytes.length, imageBytes.cast<int>());

      ChatItem newImage = ChatItem.fromJson(itemJson);
      ChatHandler().addNewChatItem(newImage);

      // ack response
      imageMessage.last(null);
    });
    _socket.on('backlogImage', (imageMessage) {
      String imageMessageJson = _encryptionHandler.decrypt(imageMessage);
      // var imageChat = json.decode(imageMessageJson);
      Map<String, dynamic> itemJson = json.decode(imageMessageJson);
      List<dynamic> imageBytes = itemJson['content'];

      itemJson['content'] = Uint8List(imageBytes.length)..setRange(0, imageBytes.length, imageBytes.cast<int>());

      ChatItem newImage = ChatItem.fromJson(itemJson);
      ChatHandler().addChatItem(newImage);

      // ack response
      // imageMessage.last(null);
      _currentlyRequesting = false;
    });
    _socket.on('usernameSend', (clientUserName) {
      String decryptedClientUserName = _encryptionHandler.decrypt(clientUserName);
      userName = decryptedClientUserName;
      ServerHandler().addServer();
    });
    _socket.on('userListSend', (userList) {
      String decryptedUserList = _encryptionHandler.decrypt(userList);
      var items = json.decode(decryptedUserList);
      UserHandler().addUsers(items.cast<String>());
    });
    _socket.on(
      'userJoin',
      (userName) => UserHandler().addUser(_encryptionHandler.decrypt(userName)),
    );
    _socket.on(
      'userLeave',
      (userName) => UserHandler().addUser(_encryptionHandler.decrypt(userName)),
    );
    _socket.on('userTyping', (itemJson) {
      String decryptedItemJson = _encryptionHandler.decrypt(itemJson);
      ChatItem item = ChatItem.fromJson(json.decode(decryptedItemJson));
      TypingHandler().userIsTyping(item);
    });
    _socket.on('edit', (itemJson) {
      String decryptedItemJson = _encryptionHandler.decrypt(itemJson);
      ChatItem editItem = ChatItem.fromJson(json.decode(decryptedItemJson));
      ChatHandler().editItem(editItem);
    });
    _socket.on('delete', (itemJson) {
      String decryptedItemJson = _encryptionHandler.decrypt(itemJson);
      ChatItem deleteItem = ChatItem.fromJson(json.decode(decryptedItemJson));
      ChatHandler().deleteItem(deleteItem);
    });
  }

  void _sendChatMessage(String event, ChatItem item) {
    _send(event, item.toJson().toString());
  }

  void _send(String event, String message) {
    String encryptedMessage = _encryptionHandler.encrypt(message);
    _socket.emit(event, encryptedMessage);
  }

  void _sendImageMessage(String message) {
    _socket.emitWithBinary('image', _encryptionHandler.encrypt(message));
  }

  void connect() {
    _socket.connect();
  }

  void disconnect() {
    _socket.disconnect();
  }

  void setUsername(String userName) {
    _send('usernameSet', userName);
  }

  void submitEdit(int editIndex, String editText) {
    final ChatHandler messages = ChatHandler();
    final ChatItem? initialItem = messages.getItem(messages.getCurrentChannel(), editIndex);
    if (initialItem == null) {
      return;
    }
    final ChatItem editItem =
        ChatItem(initialItem.itemIndex, initialItem.userName, initialItem.channel, initialItem.type, editText);
    _sendChatMessage('edit', editItem);
  }

  void requestDelete(int editIndex) {
    final ChatHandler messages = ChatHandler();
    final ChatItem? deleteItem = messages.getItem(messages.getCurrentChannel(), editIndex);
    if (deleteItem == null) {
      return;
    }
    _sendChatMessage('delete', deleteItem);
  }

  void changeServer(String serverURL) {
    if (_socket.connected) {
      _socket.disconnect();
    }
    _socket.io.uri = serverURL;
    _socket.connect();
  }

  void sendMessage(String message) {
    final ChatItem item = ChatItem(-1, userName, ChatHandler().getCurrentChannel(), 't', message);
    _sendChatMessage('chatMessage', item);
  }

  Future<Uint8List> _getImage(File image) async {
    return await image.readAsBytes();
  }

  void sendImageFile(String path) async {
    final File file = File(path);
    final Uint8List bytes = await _getImage(file);
    sendImageBytes(bytes);
  }

  void sendImageBytes(Uint8List bytes) async {
    final ChatItem item = ChatItem(-1, userName, ChatHandler().getCurrentChannel(), 'i', bytes);
    _sendImageMessage(item.toJson().toString());
  }

  void requestMore() {
    if (_currentlyRequesting) {
      return;
    }
    _currentlyRequesting = true;
    final ChatHandler chatHandler = ChatHandler();
    final ChatItem item = ChatItem(chatHandler.getOldestItemIndex(chatHandler.getCurrentChannel()), userName,
        chatHandler.getCurrentChannel(), 'r', null);
    _sendChatMessage('messageRequest', item);
  }

  void resetRequesting() {
    _currentlyRequesting = false;
  }

  void sendTypingPing() {
    _sendChatMessage('userTyping', ChatItem(-1, userName, ChatHandler().getCurrentChannel(), 't', 't'));
  }
}
