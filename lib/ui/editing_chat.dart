// Copyright Terry Hancock 2023
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neptune_fob/data/chat_handler.dart';
import 'package:neptune_fob/data/settings_handler.dart';
import 'package:neptune_fob/data/socket_handler.dart';
import 'package:neptune_fob/data/text_style_handler.dart';
import 'package:neptune_fob/data/chat_item.dart';
import 'package:provider/provider.dart';

class EditingChat extends StatelessWidget {
  EditingChat(this.editItem, {super.key});

  final ChatItem editItem;
  final TextEditingController _editingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isImage = editItem.type == 'i';
    if (!isImage && _editingController.text == '') {
      _editingController.text = editItem.content;
    }
    List<Widget> buttons = [
      const SizedBox(width: 20),
      IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () {
          SocketHandler().requestDelete(ChatHandler().editIndex);
          _editingController.text = '';
          ChatHandler().changeEditIndex(-27);
        },
      ),
      const SizedBox(width: 20),
      IconButton(
        icon: const Icon(Icons.cancel_outlined),
        onPressed: () {
          _editingController.text = '';
          editItem.editBtn = const SizedBox();
          ChatHandler().changeEditIndex(-27);
        },
      ),
      const SizedBox(width: 20),
      IconButton(
        icon: Icon(isImage ? Icons.download : Icons.check),
        onPressed: isImage ? () => SettingsHandler().saveImage(context, editItem) : _submitEdit,
      ),
      const SizedBox(width: 20),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Consumer<TextStyleHandler>(
          builder: (context, textStyleHandler, child) => Text(
            '${editItem.userName}: ',
            style: TextStyle(
              fontFamily: textStyleHandler.font,
              fontSize: textStyleHandler.fontSize,
            ),
          ),
        ),
        isImage
            ? ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: Image.memory(editItem.content),
              )
            : Flexible(
                child: RawKeyboardListener(
                  focusNode: FocusNode(),
                  onKey: (event) {
                    if ((event.isKeyPressed(LogicalKeyboardKey.enter) ||
                            event.isKeyPressed(LogicalKeyboardKey.numpadEnter)) &&
                        !event.isShiftPressed) {
                      _submitEdit();
                    }
                  },
                  child: Consumer<TextStyleHandler>(
                    builder: (context, textStyleHandler, child) => TextField(
                      controller: _editingController,
                      minLines: 1,
                      maxLines: 10,
                      style: TextStyle(
                        fontSize: textStyleHandler.fontSize,
                        fontFamily: textStyleHandler.font,
                      ),
                    ),
                  ),
                ),
              ),
        const Spacer(),
        isAndroid() ? Column(children: buttons) : Row(children: buttons),
      ],
    );
  }

  void _submitEdit() {
    SocketHandler().submitEdit(ChatHandler().editIndex, _editingController.text);
    _editingController.text = '';
    ChatHandler().changeEditIndex(-27);
  }

  bool isAndroid() {
    return !kIsWeb && Platform.isAndroid;
  }
}
