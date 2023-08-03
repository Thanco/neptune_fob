// Copyright Terry Hancock 2023

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:neptune_fob/data/chat_handler.dart';
import 'package:neptune_fob/data/settings_handler.dart';
import 'package:neptune_fob/data/socket_handler.dart';
import 'package:neptune_fob/data/text_style_handler.dart';
import 'package:neptune_fob/data/chat_item.dart';
import 'package:provider/provider.dart';

class DisplayChat extends StatefulWidget {
  const DisplayChat(this.item, {super.key});

  final ChatItem item;

  @override
  State<DisplayChat> createState() => _DisplayChatState();
}

class _DisplayChatState extends State<DisplayChat> {
  void _editMessage() {
    if (widget.item.userName != SocketHandler().userName) {
      return;
    }
    ChatHandler().changeEditIndex(widget.item.itemIndex);
  }

  void _showEditButton() {
    if (widget.item.type == 'i' && widget.item.userName != SocketHandler().userName) {
      _showSaveButton();
      return;
    } else if (widget.item.userName != SocketHandler().userName) {
      return;
    }
    widget.item.editBtn = TextButton(
      style: const ButtonStyle(
        minimumSize: MaterialStatePropertyAll(Size(0, 0)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () => _editMessage(),
      child: Consumer<TextStyleHandler>(
        builder: (context, textStyleHandler, child) => Text(
          'Edit',
          style: TextStyle(
            fontSize: textStyleHandler.fontSize,
            fontFamily: textStyleHandler.font,
          ),
        ),
      ),
    );
    setState(() {});
  }

  void _showSaveButton() {
    widget.item.editBtn = TextButton(
      style: const ButtonStyle(
        minimumSize: MaterialStatePropertyAll(Size(0, 0)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () {
        SettingsHandler().saveImage(context, widget.item);
      },
      child: Consumer<TextStyleHandler>(
        builder: (context, textStyleHandler, child) => Text(
          'Save',
          style: TextStyle(
            fontSize: textStyleHandler.fontSize,
            fontFamily: textStyleHandler.font,
          ),
        ),
      ),
    );
    setState(() {});
  }

  void _hideEditButton() {
    widget.item.editBtn = const SizedBox();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Row child = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(child: widget.item.itemWidget),
        widget.item.editBtn,
        const SizedBox(
          width: 15,
        ),
      ],
    );
    if (!kIsWeb && Platform.isWindows) {
      return MouseRegion(
        onHover: (event) => _showEditButton(),
        onExit: (event) => _hideEditButton(),
        child: child,
      );
    }
    return GestureDetector(
      onDoubleTap: () => _editMessage(),
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}
