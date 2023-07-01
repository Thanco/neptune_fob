// Copyright Terry Hancock 2023
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:neptune_fob/data/chat_handler.dart';
import 'package:neptune_fob/data/text_style_handler.dart';
import 'package:neptune_fob/data/chat_item.dart';
import 'package:neptune_fob/ui/image_view.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatItemTest extends StatelessWidget {
  const ChatItemTest(this.item, {super.key});
  final ChatItem item;

  // bool _displayUsername() {
  //   final list = ChatHandler().getMessages(item.channel);
  //   int index = list.indexOf(item);
  //   int previousIndex = index - 1;
  //   return previousIndex > 2 && list.elementAt(index - 1).userName != item.userName;
  // }

  void _pushImage(Image image, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => ImageView(
        image: image,
      ),
    );
  }

  bool _isURL(String text) {
    return text.startsWith("http");
  }

  bool _isImageFile(String text) {
    return text.endsWith(".jpg") || text.endsWith(".jpeg") || text.endsWith(".png");
  }

  TextSpan _italicise(String text, String fontFamily, double fontSize) {
    List<String> split = text.split('*');
    if (split.length < 3) {
      return TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSize,
        ),
      );
    }
    TextSpan textSpan = TextSpan(
      children: [
        TextSpan(
          text: split.first,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: fontSize,
          ),
        ),
      ],
    );
    for (var i = 1; i < split.length; i++) {
      if (i % 2 == 1) {
        textSpan.children?.add(
          TextSpan(
            text: split[i],
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: fontSize,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      } else {
        textSpan.children?.add(
          TextSpan(
            text: split[i],
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: fontSize,
            ),
          ),
        );
      }
    }
    return textSpan;
  }

  @override
  Widget build(BuildContext context) {
    Row newRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Consumer<TextStyleHandler>(
          builder: (context, textStyleHandler, child) => Text(
            // _displayUsername() ? '${item.userName}: ' : '   ',
            '${item.userName}: ',
            style: TextStyle(
              fontFamily: textStyleHandler.font,
              fontSize: textStyleHandler.fontSize,
            ),
          ),
        ),
      ],
    );
    switch (item.type) {
      case 't':
        if (_isURL(item.content) && _isImageFile(item.content)) {
          newRow.children.add(
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.5,
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Image.network(
                item.content,
                fit: BoxFit.scaleDown,
              ),
            ),
          );
          break;
        }
        if (item.content.contains('http')) {
          final List<Widget> newWidgets = [];
          final List<String> split = item.content.split(' ');
          String plainText = '';
          for (int i = 0; i < split.length; i++) {
            if (split[i].contains('http')) {
              if (plainText != '') {
                newWidgets.add(
                  Consumer<TextStyleHandler>(
                    builder: (context, textStyleHandler, child) => SelectableText.rich(
                      _italicise(plainText, textStyleHandler.font, textStyleHandler.fontSize),
                    ),
                  ),
                );
                plainText = '';
              }
              newWidgets.add(
                Flexible(
                  child: InkWell(
                    child: Consumer<TextStyleHandler>(
                      builder: (context, textStyleHandler, child) => Text(
                        split[i],
                        style: TextStyle(
                          fontFamily: textStyleHandler.font,
                          fontSize: textStyleHandler.fontSize,
                          color: const Color.fromARGB(255, 53, 98, 203),
                        ),
                      ),
                    ),
                    onTap: () {
                      try {
                        launchUrl(Uri.tryParse(item.content)!);
                      } catch (e) {
                        return;
                      }
                    },
                  ),
                ),
              );
            } else {
              plainText += '${split[i]} ';
            }
          }
          if (plainText != '') {
            newWidgets.add(
              Consumer<TextStyleHandler>(
                builder: (context, textStyleHandler, child) => SelectableText.rich(
                  _italicise(plainText, textStyleHandler.font, textStyleHandler.fontSize),
                ),
              ),
            );
            plainText = '';
          }
          newRow.children.add(
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: newWidgets,
              ),
            ),
          );
          break;
        }
        newRow.children.add(
          Consumer<TextStyleHandler>(
            builder: (context, textStyleHandler, child) => Flexible(
              child: SelectableText.rich(_italicise(item.content, textStyleHandler.font, textStyleHandler.fontSize)),
            ),
          ),
        );
        break;
      case 'i':
        Color none = const Color.fromARGB(0, 0, 0, 0);
        final Uint8List bytes = item.content;
        newRow.children.add(
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: MaterialButton(
                splashColor: none,
                color: none,
                hoverColor: none,
                onPressed: () => _pushImage(
                  Image.memory(bytes),
                  context,
                ),
                child: Image.memory(bytes),
              ),
            ),
          ),
        );
        break;
      default:
        break;
    }
    return newRow;
  }
}
