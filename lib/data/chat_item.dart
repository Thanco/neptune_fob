// Copyright Terry Hancock 2023

import 'package:flutter/material.dart';
import 'package:neptune_fob/ui/chat_item_test.dart';

class ChatItem with Comparable<ChatItem> {
  final int itemIndex;
  final String userName;
  final String channel;
  final String type;
  final dynamic content;
  late final ChatItemTest itemWidget = ChatItemTest(this);
  Widget editBtn = const SizedBox();

  ChatItem(this.itemIndex, this.userName, this.channel, this.type, this.content);

  ChatItem.fromJson(Map<String, dynamic> json)
      : itemIndex = json['itemIndex'],
        userName = json['userName'],
        channel = json['channel'],
        content = json['content'],
        type = json['type'];

  Map<String, dynamic> toJson() => {
        'itemIndex': itemIndex,
        'userName': '"$userName"',
        'channel': '"$channel"',
        'content': contentToJson(),
        'type': type,
      };

  dynamic contentToJson() {
    switch (type) {
      case 't':
        return '"${content.toString().replaceAll("\"", "\\\"")}"';
      default:
        return content;
    }
  }

  @override
  int compareTo(ChatItem other) {
    // return other.itemIndex - itemIndex;
    return itemIndex - other.itemIndex;
  }
}
