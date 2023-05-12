import 'package:flutter/material.dart';
import 'package:neptune_fob/data/chat_handler.dart';
import 'package:neptune_fob/data/socket_handler.dart';
import 'package:neptune_fob/data/text_style_handler.dart';
import 'package:neptune_fob/ui/chat_item.dart';
import 'package:provider/provider.dart';

class DisplayChat extends StatefulWidget {
  const DisplayChat(this.item, {super.key});

  final ChatItem item;

  @override
  State<DisplayChat> createState() => _DisplayChatState();
}

class _DisplayChatState extends State<DisplayChat> {
  final List<ChatItem> currentChat = ChatHandler().getMessages('');

  void _editMessage() {
    // ChatItem editItem = _messageLists[_currentChannel]!.firstWhere((element) => element.itemIndex == index);
    if (widget.item.userName != SocketHandler().userName) {
      return;
    }
    setState(() {
      // _editingController.text = '';
      ChatHandler().changeEditIndex(widget.item.itemIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        if (widget.item.type != 't' || widget.item.userName != SocketHandler().userName) {
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
      },
      onExit: (event) {
        widget.item.editBtn = const SizedBox();
        setState(() {});
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(child: widget.item.itemWidget),
          widget.item.editBtn,
          const SizedBox(
            width: 15,
          )
        ],
      ),
    );
  }
}
