// Copyright Terry Hancock 2023
import 'package:flutter/material.dart';
import 'package:neptune_fob/data/chat_handler.dart';
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
    if (_editingController.text == '') {
      _editingController.text = editItem.content;
    }
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
        Flexible(
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
          icon: const Icon(Icons.check),
          onPressed: () {
            SocketHandler().submitEdit(ChatHandler().editIndex, _editingController.text);
            _editingController.text = '';
            ChatHandler().changeEditIndex(-27);
          },
        ),
        const SizedBox(width: 20),
      ],
    );
  }
}
