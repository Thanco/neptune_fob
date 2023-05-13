import 'package:flutter/material.dart';
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          TextEditingController controller = TextEditingController();
          return InputPrompt(
            controller: controller,
            formTitle: 'Username',
            onSubmit: () {
              if (controller.text.isEmpty || controller.text.length > 16) {
                return;
              }
              SocketHandler().setUsername(controller.text);
              Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }

  void changeServerAddress(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          TextEditingController controller = TextEditingController();
          return InputPrompt(
            controller: controller,
            formTitle: 'Server Address',
            onSubmit: () {
              if (!controller.text.startsWith('http://')) {
                controller.text = 'http://${controller.text}/';
              }
              final SocketHandler socket = SocketHandler();
              if (socket.connected) {
                socket.disconnect();
              }
              socket.uri = controller.text;
              Navigator.of(context).pop();
              socket.connect();
            },
          );
        },
      ),
    );
  }
}
