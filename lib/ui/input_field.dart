// Copyright Terry Hancock 2023
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neptune_fob/data/chat_handler.dart';
import 'package:neptune_fob/data/client_typing_handler.dart';
import 'package:neptune_fob/data/socket_handler.dart';
import 'package:neptune_fob/data/text_style_handler.dart';
import 'package:neptune_fob/main.dart';
import 'package:neptune_fob/ui/typing_status.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class InputField extends StatefulWidget {
  const InputField({super.key});

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  final TextEditingController _controller = TextEditingController();

  late Uint8List? _imageBytes;
  bool _imagePaste = false;

  bool _isStaticImage(String filePath) {
    if (filePath.endsWith('.png') || filePath.endsWith('.jpg') || filePath.endsWith('.jpeg')) {
      return true;
    }
    return false;
  }

  bool _isURL(String text) {
    return text.startsWith("http");
  }

  bool _isImageFile(String text) {
    return text.endsWith(".jpg") || text.endsWith(".jpeg") || text.endsWith(".png");
  }

  void _testMessage() {
    if (_imagePaste) {
      SocketHandler().sendImageBytes(_imageBytes!);
      _imagePaste = false;
    }
    String message = _controller.text;
    _controller.text = '';
    if (!_isURL(message) && _isImageFile(message)) {
      SocketHandler().sendImageFile(message);
    } else if (!(message == '')) {
      SocketHandler().sendMessage(message);
    }
  }

  void _pasteImage() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null) {
      _controller.text = _controller.text + data.text!;
      return;
    }
    _imageBytes = await Pasteboard.image;
    if (_imageBytes == null) {
      List<String> files = await Pasteboard.files();
      File file = File(files.single);
      if (!_isStaticImage(file.path)) {
        return;
      }
      _imageBytes = await file.readAsBytes();
    }
    _imagePaste = true;

    setState(() {});
  }

  void _selectImage() async {
    XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
    _imageBytes = await image!.readAsBytes();
    _imagePaste = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NeptuneFOB.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Consumer<ChatHandler>(
        builder: (context, value, child) => LayoutBuilder(
          builder: (buildContext, constraints) {
            final List<Widget> inputColumn = [
              SizedBox(
                width: constraints.maxWidth - 130,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 0, 10),
                  child: RawKeyboardListener(
                    focusNode: FocusNode(),
                    onKey: (RawKeyEvent event) {
                      // print(event.isKeyPressed(LogicalKeyboardKey.enter));
                      if (!Platform.isAndroid &&
                          (event.isKeyPressed(LogicalKeyboardKey.enter) ||
                              event.isKeyPressed(LogicalKeyboardKey.numpadEnter)) &&
                          !event.isShiftPressed) {
                        if (_controller.text == '\n\r') {
                          return;
                        }
                        _testMessage();
                      }
                    },
                    child: Consumer<TextStyleHandler>(
                      builder: (context, textStyleHandler, child) => TextField(
                        style: TextStyle(
                          fontFamily: textStyleHandler.font,
                          fontSize: textStyleHandler.fontSize,
                        ),
                        controller: _controller,
                        onSubmitted: (message) {
                          _testMessage();
                        },
                        onChanged: (message) {
                          ClientTypingHandler().thisClientTyping();
                          if (_controller.text == '\n') {
                            _controller.text = '';
                          }
                        },
                        onEditingComplete: () => _testMessage(),
                        minLines: 1,
                        maxLines: 20,
                        autofocus: true,
                        textInputAction: TextInputAction.newline,
                      ),
                    ),
                  ),
                ),
              ),
              Consumer<TextStyleHandler>(
                builder: (context, textStyleHandler, child) => SizedBox(
                  height: textStyleHandler.fontSize * 0.36,
                  width: constraints.maxWidth - 130,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
                    child: TypingStatus(constraints.maxWidth - 130),
                  ),
                ),
              ),
            ];
            if (_imagePaste) {
              inputColumn.insert(
                0,
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth - 130,
                    maxHeight: MediaQuery.of(context).size.height * 0.3,
                  ),
                  child: IntrinsicWidth(
                    child: Stack(
                      children: [
                        Image.memory(_imageBytes!),
                        Align(
                          alignment: Alignment.topRight,
                          child: MaterialButton(
                            height: 40,
                            minWidth: 40,
                            shape: const CircleBorder(),
                            onPressed: () => {
                              _imagePaste = false,
                              setState(() {}),
                            },
                            child: const Icon(
                              Icons.cancel_rounded,
                              size: 40,
                              color: Color.fromARGB(255, 219, 14, 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: MaterialButton(
                    onPressed: _pasteImage,
                    onLongPress: _selectImage,
                    shape: const CircleBorder(),
                    color: ColorScheme.fromSeed(seedColor: NeptuneFOB.color).secondary,
                    height: 50,
                    minWidth: 50,
                    hoverColor: Colors.blue,
                    child: const Icon(Icons.add_sharp),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: inputColumn,
                ),
                const SizedBox(
                  width: 10,
                ),
                MaterialButton(
                  onPressed: _testMessage,
                  splashColor: Colors.lightBlue,
                  hoverColor: Colors.blue,
                  shape: const CircleBorder(),
                  color: ColorScheme.fromSeed(seedColor: NeptuneFOB.color).secondary,
                  height: 50,
                  minWidth: 50,
                  child: const Icon(Icons.send),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
