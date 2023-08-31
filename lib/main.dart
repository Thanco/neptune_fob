// Copyright Terry Hancock 2023

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:neptune_fob/data/chat_handler.dart';
import 'package:neptune_fob/data/settings_handler.dart';
import 'package:neptune_fob/data/text_style_handler.dart';
import 'package:neptune_fob/data/user_handler.dart';
import 'package:neptune_fob/rtc/rtc_panel.dart';

import 'package:neptune_fob/ui/chat_list.dart';
import 'package:neptune_fob/ui/input_field.dart';
import 'package:neptune_fob/ui/neptune_bar.dart';
import 'package:neptune_fob/ui/neptune_drawer.dart';
import 'package:neptune_fob/ui/server_panel.dart';
import 'package:neptune_fob/ui/typing_status.dart';
import 'package:neptune_fob/ui/user_panel.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const NeptuneFOB());
}

class NeptuneFOB extends StatelessWidget {
  const NeptuneFOB({super.key});

  static const Color color = Color.fromARGB(255, 68, 99, 179);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Neptune FOB',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 68, 99, 179),
          brightness: Brightness.dark,
        ),
        fontFamily: 'CenturyGothic',
      ),
      home: const _MainChat(),
    );
  }
}

class _MainChat extends StatefulWidget {
  const _MainChat();

  @override
  State<_MainChat> createState() => _MainChatState();
}

class _MainChatState extends State<_MainChat> {
  final List<bool> _displayPanels = [false, false];
  final List<Function> _flips = [];
  final FocusNode _inputPanelFocusNode = FocusNode();
  final FocusNode _editFocusNode = FocusNode();

  void _toggleServers() {
    _displayPanels[0] = !_displayPanels[0];
    setState(() {});
  }

  void _toggleUsers() {
    _displayPanels[1] = !_displayPanels[1];
    setState(() {});
  }

  @override
  void initState() {
    SettingsHandler.init(context);

    _flips.add(_toggleServers);
    _flips.add(_toggleUsers);

    super.initState();
  }

  final Flexible _userPanel = const Flexible(
    flex: 4,
    child: UserPanel(),
  );
  late final Flexible _serverPanel = const Flexible(
    flex: 4,
    child: ServerPanel(RTCPanel()),
  );

  @override
  Widget build(BuildContext context) {
    // _userDisconnect(_userName);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TextStyleHandler()),
        Provider<List<Function>>(create: (context) => _flips),
        Provider<List<FocusNode>>(create: (context) => [_inputPanelFocusNode, _editFocusNode]),
        ChangeNotifierProvider(create: (context) => UserHandler()),
        ChangeNotifierProvider<ChatHandler>(create: (context) => ChatHandler()),
        ChangeNotifierProvider<TypingHandler>(create: (context) => TypingHandler())
      ],
      builder: (context, child) {
        return FocusScope(
          onKeyEvent: (node, event) {
            if (!_editFocusNode.hasFocus) {
              _inputPanelFocusNode.children.first.requestFocus();
            }
            return KeyEventResult.ignored;
          },
          child: Scaffold(
            appBar: AppBar(
              flexibleSpace: const NeptuneBar(),
            ),
            drawer: const NeptuneDrawer(),
            body: child,
            resizeToAvoidBottomInset: true,
            onDrawerChanged: (open) => open ? {} : SettingsHandler().saveSettings(),
          ),
        );
      },
      child: Slidable(
        enabled: !kIsWeb && Platform.isAndroid,
        dragStartBehavior: DragStartBehavior.start,
        startActionPane: ActionPane(
          extentRatio: .8,
          motion: const BehindMotion(),
          children: [_serverPanel],
        ),
        endActionPane: ActionPane(
          extentRatio: .8,
          motion: const BehindMotion(),
          children: [_userPanel],
        ),
        child: Row(
          children: [
            _displayPanels[0] ? _serverPanel : const SizedBox(),
            Flexible(
              flex: 16,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ChatList(),
                  const InputField(),
                ],
              ),
            ),
            _displayPanels[1] ? _userPanel : const SizedBox(),
          ],
        ),
      ),
    );
  }
}
