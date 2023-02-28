// Copyright Terry Hancock 2023
import 'package:flutter/material.dart';

class InputPrompt extends StatelessWidget {
  final TextEditingController controller;
  final String formTitle;
  final void Function()? onSubmit;

  const InputPrompt({super.key, required this.controller, required this.formTitle, required this.onSubmit});

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
                    Text('Enter $formTitle:'),
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'Type here...',
                      ),
                      textAlign: TextAlign.center,
                      onSubmitted: (value) => {},
                    ),
                    const Spacer(),
                    MaterialButton(
                      onPressed: onSubmit,
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
