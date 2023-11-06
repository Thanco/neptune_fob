// Copyright Terry Hancock 2023
import 'package:flutter/material.dart';
import 'package:neptune_fob/data/settings_handler.dart';
import 'package:neptune_fob/data/socket_handler.dart';
import 'package:neptune_fob/ui/input_prompt.dart';

class NewClientCalls {
  bool _newClient = true;
  bool get newClient => _newClient;

  void newClientCalls(BuildContext context) {
    final SocketHandler socket = SocketHandler();
    if (_newClient) {
      if (socket.userName.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          changeUserName(context);
        });
      }
      if (socket.uri.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          changeServerAddress(context);
        });
      }
      _newClient = false;
    }
  }

  void changeUserName(BuildContext context) {
    _pushScreen(context, 'Username');
  }

  void changeServerAddress(BuildContext context) {
    _pushScreen(context, 'Server Address');
  }

  void _pushScreen(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController controller = TextEditingController();
        return InputPrompt(
          controller: controller,
          formTitle: title,
          onSubmit: () {
            switch (title) {
              case 'Username':
                if (controller.text.isEmpty || controller.text.length > 16) {
                  return;
                }
                SocketHandler().setUsername(controller.text);
                Navigator.of(context).pop();
                SettingsHandler().saveSettings();
                break;
              case 'Server Address':
                if (!controller.text.startsWith('http:')) {
                  controller.text = 'http://${controller.text}/';
                }
                final SocketHandler socket = SocketHandler();
                if (socket.connected) {
                  socket.disconnect();
                }
                socket.uri = controller.text;
                socket.connect();
                Navigator.of(context).pop();
                break;
              default:
                return;
            }
          },
        );
      },
    );
  }
}
