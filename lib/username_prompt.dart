import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart';

class UserNamePrompt extends StatefulWidget {
  final TextEditingController controller;
  final Socket socket;

  const UserNamePrompt(
      {super.key, required this.controller, required this.socket});

  @override
  State<UserNamePrompt> createState() => _UserNamePromptState();
}

class _UserNamePromptState extends State<UserNamePrompt> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 256,
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
                  const Text('Enter Username:'),
                  TextField(
                    controller: widget.controller,
                    decoration: const InputDecoration(
                      hintText: 'Username',
                    ),
                    textAlign: TextAlign.center,
                    onSubmitted: (value) => {},
                  ),
                  const Spacer(),
                  MaterialButton(
                    onPressed: () {
                      if (widget.controller.text.length > 16) {
                        return;
                      }
                      widget.socket.emit('usernameSet', widget.controller.text);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
