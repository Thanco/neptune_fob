// Copyright Terry Hancock 2023
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:neptune_fob/data/chat_handler.dart';
import 'package:neptune_fob/data/profile.dart';
import 'package:neptune_fob/data/profile_handler.dart';
import 'package:neptune_fob/data/text_style_handler.dart';
import 'package:neptune_fob/data/chat_item.dart';
import 'package:neptune_fob/main.dart';
import 'package:neptune_fob/ui/image_view.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatItemTest extends StatelessWidget {
  const ChatItemTest(this.item, {super.key});
  final ChatItem item;

  bool _displayUsername() {
    final list = ChatHandler().getMessages(item.channel);
    int index = list.indexOf(item);
    int previousIndex = index - 1;
    return previousIndex > 2 && list.elementAt(index - 1).userName != item.userName;
  }

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
    bool repeat = _displayUsername();
    // final profile = ChatHandler().profiles[item.userName] ?? Profile.blank(item.userName);
    final newColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        repeat
            ? Consumer2<ProfileHandler, TextStyleHandler>(
                builder: (context, profileHandler, textStyleHandler, child) => Text(
                  item.userName,
                  style: TextStyle(
                    fontFamily: textStyleHandler.font,
                    fontSize: textStyleHandler.fontSize,
                    fontWeight: FontWeight.bold,
                    color: profileHandler.profiles[item.userName]?.color ?? NeptuneFOB.color,
                  ),
                ),
              )
            : const SizedBox(),
      ],
    );
    Row newRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        repeat
            ? Material(
                shape: const CircleBorder(side: BorderSide(color: Colors.transparent)),
                clipBehavior: Clip.hardEdge,
                child: Consumer2<ProfileHandler, TextStyleHandler>(
                  builder: (context, profileHandler, textStyleHandler, child) => Image.memory(
                    profileHandler.profiles[item.userName]?.imageBytes ?? Uint8List(0),
                    height: textStyleHandler.fontSize * 2,
                    width: textStyleHandler.fontSize * 2,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person,
                        size: textStyleHandler.fontSize * 2,
                      );
                    },
                  ),
                ),
              )
            : Consumer<TextStyleHandler>(
                builder: (context, textStyleHandler, child) => SizedBox(
                      width: textStyleHandler.fontSize * 2,
                    )),
        const SizedBox(width: 15),
        Flexible(child: newColumn)
      ],
    );
    switch (item.type) {
      case 't':
        if (_isURL(item.content) && _isImageFile(item.content)) {
          newColumn.children.add(
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
          newColumn.children.add(
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
        newColumn.children.add(
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
        newColumn.children.add(
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

    return repeat
        ? Padding(
            padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
            child: ChangeNotifierProvider<ProfileHandler>(
              create: (context) => ProfileHandler(),
              child: newRow,
            ),
          )
        : newRow;
  }
}
