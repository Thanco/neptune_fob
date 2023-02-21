import 'package:flutter/material.dart';

class InputPrompt extends StatefulWidget {
  final TextEditingController controller;
  final String formTitle;
  final void Function()? onSubmit;

  const InputPrompt(
      {super.key,
      required this.controller,
      required this.formTitle,
      required this.onSubmit});

  @override
  State<InputPrompt> createState() => _InputPromptState();
}

class _InputPromptState extends State<InputPrompt> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(0, 0, 0, 0),
      appBar: AppBar(),
      body: Center(
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
                    Text('Enter ${widget.formTitle}:'),
                    TextField(
                      controller: widget.controller,
                      decoration: const InputDecoration(
                        hintText: 'Type here...',
                      ),
                      textAlign: TextAlign.center,
                      onSubmitted: (value) => {},
                    ),
                    const Spacer(),
                    MaterialButton(
                      onPressed: widget.onSubmit,
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
