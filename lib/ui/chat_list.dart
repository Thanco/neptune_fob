// Copyright Terry Hancock 2023

import 'package:flutter/material.dart';
import 'package:neptune_fob/data/chat_handler.dart';
import 'package:neptune_fob/data/socket_handler.dart';
import 'package:neptune_fob/data/chat_item.dart';
import 'package:neptune_fob/ui/display_chat_item.dart';
import 'package:neptune_fob/ui/editing_chat.dart';
import 'package:provider/provider.dart';

class ChatList extends StatelessWidget {
  final ScrollController controller = ChatHandler().controller;
  final List<DisplayChat> displayList = [];

  void _scrollActions() {
    if (controller.position.pixels == controller.position.maxScrollExtent) {
      SocketHandler().requestMore();
      // WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      //   controller.position
      //       .animateTo(controller.position.pixels + 1, duration: const Duration(microseconds: 1), curve: Curves.linear);
      // });
    }
  }

  ChatList({super.key}) {
    controller.addListener(() => _scrollActions());
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Consumer<ChatHandler>(
          builder: (context, chatHandler, child) {
            final List<ChatItem> currentList = chatHandler.getMessages('');

            final List<Widget> list = [];
            for (ChatItem item in currentList) {
              // list.add(const Divider());
              if (item.itemIndex == ChatHandler().editIndex) {
                list.add(EditingChat(item));
                continue;
              }
              list.add(DisplayChat(item));
            }

            return SingleChildScrollView(
              controller: controller,
              reverse: true,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: list,
              ),
            );
          },
        ),
      ),
    );
  }
}
