// Copyright Terry Hancock 2023
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NeptuneBar extends StatelessWidget {
  const NeptuneBar({super.key});

  @override
  Widget build(BuildContext context) {
    return FlexibleSpaceBar(
      background: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: Platform.isAndroid ? .5 : .2,
            alignment: Alignment.centerLeft,
            child: MaterialButton(
              height: MediaQuery.of(context).size.height,
              color: const Color.fromARGB(255, 68, 99, 179),
              hoverColor: Theme.of(context).cardColor,
              onPressed: () {
                Provider.of<List<Function>>(context, listen: false)[0].call();
              },
              child: const Icon(
                Icons.list,
                size: 40,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: .2,
              child: MaterialButton(
                height: MediaQuery.of(context).size.height,
                color: const Color.fromARGB(255, 68, 99, 179),
                hoverColor: Theme.of(context).cardColor,
                onPressed: () {
                  Provider.of<List<Function>>(context, listen: false)[1].call();
                },
                child: const Icon(
                  Icons.people,
                  size: 40,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              width: 60,
              child: const ColoredBox(
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
