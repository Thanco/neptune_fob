import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart';

class AddressPrompt extends StatefulWidget {
  final TextEditingController controller;
  final Socket socket;

  const AddressPrompt(
      {super.key, required this.controller, required this.socket});

  @override
  State<AddressPrompt> createState() => _AddressPromptState();
}

class _AddressPromptState extends State<AddressPrompt> {
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
                  const Text('Enter Server Address:'),
                  TextField(
                    controller: widget.controller,
                    decoration: const InputDecoration(
                      hintText: 'address',
                    ),
                    textAlign: TextAlign.center,
                    onSubmitted: (value) => {},
                  ),
                  const Spacer(),
                  MaterialButton(
                    onPressed: () {
                      if (!widget.controller.text.startsWith('http://')) {
                        widget.controller.text =
                            'http://${widget.controller.text}/';
                      }
                      if (widget.socket.connected) {
                        widget.socket.disconnect();
                      }
                      widget.socket.io.uri = widget.controller.text;
                      Navigator.of(context).pop();
                      widget.socket.connect();
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
