// Copyright Terry Hancock 2023

import 'package:flutter/material.dart';
import 'package:neptune_fob/data/chat_handler.dart';
import 'package:neptune_fob/data/new_client_calls.dart';
import 'package:neptune_fob/data/settings_handler.dart';
import 'package:neptune_fob/data/socket_handler.dart';
import 'package:neptune_fob/ui/display_chat_item.dart';
import 'package:neptune_fob/ui/editing_chat.dart';
import 'package:provider/provider.dart';

class ChatList extends StatefulWidget {
  const ChatList({super.key});

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  final ScrollController controller = ChatHandler().controller;
  List<DisplayChat> displayList = [];

  @override
  void initState() {
    controller.addListener(() => _scrollActions());

    super.initState();
  }

  void _scrollActions() {
    if (controller.position.pixels == controller.position.minScrollExtent) {
      SocketHandler().requestMore();
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        controller.position
            .animateTo(controller.position.pixels + 1, duration: const Duration(microseconds: 1), curve: Curves.linear);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (NewClientCalls.newClient) {
      SettingsHandler();
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        NewClientCalls.newClientCalls(context);
      });
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Consumer<ChatHandler>(
          builder: (context, chatHandler, child) => SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: ListView.separated(
              clipBehavior: Clip.none,
              controller: ChatHandler().controller,
              padding: const EdgeInsets.symmetric(),
              shrinkWrap: true,
              itemCount: chatHandler.getMessages('').length,
              itemBuilder: ((context, index) {
                if (chatHandler.getMessages('')[index].itemIndex == ChatHandler().editIndex) {
                  return EditingChat(chatHandler.getMessages('')[index]);
                }
                return DisplayChat(chatHandler.getMessages('')[index]);
              }),
              separatorBuilder: (context, index) => const Divider(),
            ),
          ),
        ),
      ),
    );
  }
}
