// Copyright Terry Hancock 2023

import 'package:flutter/material.dart';
import 'package:neptune_fob/data/socket_handler.dart';
import 'package:neptune_fob/data/chat_item.dart';
import 'package:neptune_fob/ui/sound_handler.dart';

class ChatHandler with ChangeNotifier {
  static final ChatHandler _instance = ChatHandler._constructor();
  final Map<String, List<ChatItem>> _messageLists = {'Default': []};
  final Map<String, bool> _messageListNews = {'Default': false};
  String _currentChannel = 'Default';
  final ScrollController controller = ScrollController();
  int _editIndex = -27;

  ChatHandler._constructor();

  // void _scrollToEnd() {
  //   WidgetsBinding.instance.addPostFrameCallback(
  //     (timeStamp) => controller.animateTo(controller.position.maxScrollExtent,
  //         duration: const Duration(milliseconds: 50), curve: Curves.linear),
  //   );
  // }

  factory ChatHandler() {
    return _instance;
  }

  int get editIndex => _editIndex;

  void changeEditIndex(int newIndex) {
    _editIndex = newIndex;
    notifyListeners();
  }

  void clearLists() {
    _messageLists.clear();
    _messageListNews.clear();
    notifyListeners();
  }

  void addChatItem(ChatItem item) {
    _messageLists.putIfAbsent(item.channel, () => []);
    _messageListNews.putIfAbsent(item.channel, () => false);
    _messageLists[item.channel]!.add(item);
    _verifyMessageOrder(item.channel);
    notifyListeners();
  }

  void addChatItems(List<ChatItem> items) {
    Map<String, List<ChatItem>> channels = {};
    for (var i = 0; i < items.length; i++) {
      final ChatItem item = items[i];
      channels.putIfAbsent(item.channel, () => []);
      channels[item.channel]!.add(item);
    }
    for (var i = 0; i < channels.length; i++) {
      final String channel = channels.keys.elementAt(i);
      _messageLists.putIfAbsent(channel, () => []);
      _messageListNews.putIfAbsent(channel, () => false);
      _messageLists[channel]!.addAll(channels[channel]!);
      _verifyMessageOrder(channel);
    }
    notifyListeners();
  }

  void addNewChatItem(ChatItem item) {
    if (item.userName != SocketHandler().userName) {
      SoundHandler.play();
    }
    _newMessage(item.channel);
    addChatItem(item);
  }

  void _verifyMessageOrder(String channel) {
    if (_messageLists[channel] != null) {
      _messageLists[channel]!.sort();
    }
    final List<ChatItem> items = _messageLists[channel]!;
    for (var i = 1; i < items.length; i++) {
      if (items[i - 1].itemIndex == items[i].itemIndex) {
        items.remove(items[i - 1]);
      }
    }
  }

  void _newMessage(String channel) {
    if (channel == _currentChannel) {
      // if (controller.position.pixels > controller.position.maxScrollExtent - 500) {
      //   _scrollToEnd();
      // }
      return;
    }
    _messageListNews[channel] = true;
  }

  void initNewChannel(String newChannel) {
    _messageLists.putIfAbsent(newChannel, () => []);
    _messageListNews.putIfAbsent(newChannel, () => false);
    _messageListNews[newChannel] = false;
    _currentChannel = newChannel;
    notifyListeners();
  }

  int getOldestItemIndex(String channel) {
    return _messageLists[channel]!.first.itemIndex;
  }

  ChatItem? getItem(String channel, int itemIndex) {
    for (ChatItem item in _messageLists[channel]!) {
      if (item.itemIndex == itemIndex) {
        return item;
      }
    }
    return null;
  }

  void editItem(ChatItem editItem) {
    _messageLists[editItem.channel]!.removeWhere((element) => element.itemIndex == editItem.itemIndex);
    _messageLists[editItem.channel]!.add(editItem);
    _verifyMessageOrder(editItem.channel);
    notifyListeners();
  }

  void deleteItem(ChatItem deleteItem) {
    _messageLists[deleteItem.channel]!.removeWhere((element) => element.itemIndex == deleteItem.itemIndex);
    notifyListeners();
  }

  List<ChatItem> getMessages(String channel) {
    if (channel == '') {
      return _messageLists[_currentChannel]!;
    }
    if (_messageLists.isNotEmpty && _messageLists[channel] != null) {
      return _messageLists[channel]!;
    }
    return [];
  }

  List<String> getChannels() {
    return _messageLists.keys.toList();
  }

  void _removeNewMessage(String channel) {
    _messageListNews[channel] = false;
    notifyListeners();
  }

  bool hasNewMessage(String channel) {
    return _messageListNews[channel]!;
  }

  String getCurrentChannel() {
    return _currentChannel;
  }

  void changeChannel(String newChannel) {
    SocketHandler().resetRequesting();
    if (newChannel == _currentChannel) {
      return;
    }
    _removeNewMessage(newChannel);
    _currentChannel = newChannel;
    notifyListeners();
    // _scrollToEnd();
  }

  void removeChannel(String channel) {
    changeChannel('Default');
    _messageLists.remove(channel);
    _messageListNews.remove(channel);
    notifyListeners();
  }
}
