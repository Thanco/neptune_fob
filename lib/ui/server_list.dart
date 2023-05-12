// Copyright Terry Hancock 2023
import 'package:flutter/material.dart';
import 'package:neptune_fob/data/chat_handler.dart';
import 'package:neptune_fob/data/text_style_handler.dart';
import 'package:neptune_fob/ui/input_prompt.dart';
import 'package:provider/provider.dart';

class ServerList extends StatefulWidget {
  const ServerList({super.key});

  @override
  State<ServerList> createState() => _ServerListState();
}

class _ServerListState extends State<ServerList> {
  final ChatHandler _messages = ChatHandler();

  void _addChannel() {
    Navigator.of(context).push(
      DialogRoute<void>(
        context: context,
        builder: (BuildContext context) {
          TextEditingController controller = TextEditingController();
          return InputPrompt(
            controller: controller,
            formTitle: 'New Channel',
            onSubmit: () {
              if (controller.text.isEmpty || controller.text.length > 16) {
                return;
              }
              _messages.initNewChannel(controller.text);
              Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatHandler>(
      builder: (context, value, child) => ListView.separated(
        separatorBuilder: (context, index) => const SizedBox(
          height: 5,
        ),
        itemCount: _messages.getChannels().length + 1,
        itemBuilder: (context, index) {
          String channel = '+ New Channel';
          void Function()? changeChannel = () => _addChannel();
          if (index < _messages.getChannels().length) {
            channel = _messages.getChannels()[index];
            changeChannel = () {
              _messages.changeChannel(_messages.getChannels()[index]);
              setState(() {});
            };
          }
          bool newMessage = index < _messages.getChannels().length && _messages.hasNewMessage(channel);
          return MaterialButton(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
            color: _messages.getCurrentChannel() == channel
                ? const Color.fromARGB(255, 68, 99, 179)
                : const Color(0x00000000),
            onPressed: changeChannel,
            child: Row(
              children: [
                const Icon(Icons.tag),
                const SizedBox(
                  width: 5,
                ),
                Flexible(
                  child: Consumer<TextStyleHandler>(
                    builder: (context, textStyleHandler, child) {
                      return Text(
                        '$channel ${newMessage ? ' •' : ''}',
                        style: TextStyle(
                          fontSize: textStyleHandler.fontSize * 0.64,
                          fontFamily: textStyleHandler.font,
                          fontWeight: newMessage ? FontWeight.w900 : FontWeight.normal,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
