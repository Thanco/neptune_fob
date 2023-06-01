// Copyright Terry Hancock 2023
import 'package:flutter/material.dart';
import 'package:neptune_fob/data/chat_handler.dart';
import 'package:neptune_fob/data/socket_handler.dart';
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
    showDialog(
        context: context,
        builder: (context) {
          final TextEditingController controller = TextEditingController();
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
        });
    // Navigator.of(context).push(
    //   DialogRoute<void>(
    //     context: context,
    //     builder: (BuildContext context) {
    //       final TextEditingController controller = TextEditingController();
    //       return InputPrompt(
    //         controller: controller,
    //         formTitle: 'New Channel',
    //         onSubmit: () {
    //           if (controller.text.isEmpty || controller.text.length > 16) {
    //             return;
    //           }
    //           _messages.initNewChannel(controller.text);
    //           Navigator.of(context).pop();
    //         },
    //       );
    //     },
    //   ),
    // );
  }

  void _removeChannel(String channel) {
    if (channel == 'Default') {
      return;
    }
    TextEditingController controller = TextEditingController();
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, setState) {
              return Center(
                child: SizedBox(
                  height: 384,
                  width: 256,
                  child: Material(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                'Are you sure you want to delete $channel?\nALL MESSAGES FROM THIS CHANNEL WILL BE UNRECOVERABLE!\n\nproceed with caution...'),
                            const Spacer(),
                            const Text('Type the channel name in the box below to confirm the deletion...'),
                            TextField(
                              controller: controller,
                              decoration: const InputDecoration(
                                hintText: 'Type here...',
                              ),
                              textAlign: TextAlign.center,
                              onChanged: (text) {
                                if (controller.text == channel) {
                                  setState.call(() {});
                                }
                              },
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                MaterialButton(
                                  color: Colors.amber,
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                const Spacer(),
                                MaterialButton(
                                  onPressed: controller.text != channel
                                      ? null
                                      : () {
                                          if (controller.text != channel) {
                                            return;
                                          }
                                          SocketHandler().removeChannel(channel);
                                          Navigator.of(context).pop();
                                        },
                                  child: const Text('Submit'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        });
  }

  bool _textMatches(String verification, String channel) {
    return verification == channel;
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
          void Function() changeChannel = () => _addChannel();
          void Function() removeChannel = () {};
          if (index < _messages.getChannels().length) {
            channel = _messages.getChannels()[index];
            changeChannel = () {
              _messages.changeChannel(_messages.getChannels()[index]);
              setState(() {});
            };
            removeChannel = () => _removeChannel(channel);
          }
          final bool newMessage = index < _messages.getChannels().length && _messages.hasNewMessage(channel);
          return MaterialButton(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
            color: _messages.getCurrentChannel() == channel
                ? const Color.fromARGB(255, 68, 99, 179)
                : const Color(0x00000000),
            onPressed: changeChannel,
            onLongPress: removeChannel,
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
