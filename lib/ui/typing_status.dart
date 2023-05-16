// Copyright Terry Hancock 2023
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:neptune_fob/data/chat_handler.dart';
import 'package:neptune_fob/data/socket_handler.dart';
import 'package:neptune_fob/data/text_style_handler.dart';
import 'package:neptune_fob/data/chat_item.dart';
import 'package:provider/provider.dart';

class TypingHandler with ChangeNotifier {
  static final TypingHandler _instance = TypingHandler._constructor();
  factory TypingHandler() {
    return _instance;
  }
  TypingHandler._constructor();

  final List<String> _typingList = [];

  int get userListLength => _typingList.length;
  List<String> get typingList => _typingList;

  void userIsTyping(ChatItem item) {
    if (item.userName != SocketHandler().userName &&
        !_typingList.contains(item.userName) &&
        ChatHandler().getCurrentChannel() == item.channel) {
      _typingList.add(item.userName);
      notifyListeners();
    }
    Timer(const Duration(seconds: 3), () {
      userNoLongerTyping(item.userName);
    });
  }

  void userNoLongerTyping(String userName) {
    _typingList.remove(userName);
    notifyListeners();
  }
}

class TypingStatus extends StatelessWidget {
  const TypingStatus(this.width, {super.key});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Consumer<TextStyleHandler>(
      builder: (context, textStyleHandler, child) {
        return SizedBox(
          height: textStyleHandler.fontSize * 0.36,
          width: width,
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
        child: Consumer<TypingHandler>(
          builder: (context, typingStatus, child) {
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: typingStatus.userListLength,
              itemBuilder: ((context, index) {
                return Consumer<TextStyleHandler>(
                  builder: (context, textStyleHandler, child) {
                    return Text(
                      '${typingStatus.typingList[index]} is typing...',
                      style: TextStyle(
                        height: .45,
                        fontFamily: textStyleHandler.font,
                        fontSize: textStyleHandler.fontSize * 0.55,
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  },
                );
              }),
              separatorBuilder: (context, index) => Consumer<TextStyleHandler>(
                builder: (context, textStyleHandler, child) {
                  return Text(
                    ' l ',
                    style: TextStyle(
                      height: .45,
                      fontFamily: textStyleHandler.font,
                      fontSize: textStyleHandler.fontSize * 0.55,
                      fontWeight: FontWeight.w900,
                      color: const Color.fromARGB(255, 30, 55, 118),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
