// Copyright Terry Hancock 2023

import 'package:flutter/material.dart';
import 'package:neptune_fob/data/chat_handler.dart';
import 'package:neptune_fob/data/new_client_calls.dart';
import 'package:neptune_fob/data/settings_handler.dart';
import 'package:neptune_fob/data/text_style_handler.dart';
import 'package:neptune_fob/data/user_handler.dart';

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
  // final NeptuneBar _neptuneBar = const NeptuneBar();
  // final NeptuneDrawer _drawer = const NeptuneDrawer();

  bool _hideMainChat(BuildContext context) {
    return MediaQuery.of(context).size.width < MediaQuery.of(context).size.height &&
        (_displayPanels[0] || _displayPanels[1]);
  }

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
    final NewClientCalls caller = NewClientCalls();
    if (caller.newClient) {
      SettingsHandler();
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        caller.newClientCalls(context);
      });
    }

    _flips.add(_toggleServers);
    _flips.add(_toggleUsers);

    super.initState();
  }

  final Flexible _userPanel = const Flexible(
    flex: 4,
    child: UserPanel(),
  );
  final Flexible _serverPanel = const Flexible(
    flex: 4,
    child: ServerPanel(),
  );

  @override
  Widget build(BuildContext context) {
    // _userDisconnect(_userName);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TextStyleHandler()),
        Provider<List<Function>>(create: (context) => _flips),
        ChangeNotifierProvider(create: (context) => UserHandler()),
        ChangeNotifierProvider<ChatHandler>(create: (context) => ChatHandler()),
        ChangeNotifierProvider<TypingHandler>(create: (context) => TypingHandler())
      ],
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            flexibleSpace: const NeptuneBar(),
          ),
          drawer: const NeptuneDrawer(),
          body: child,
          resizeToAvoidBottomInset: true,
          onDrawerChanged: (open) => open ? {} : SettingsHandler().saveSettings(),
        );
      },
      child: Row(
        children: [
          _displayPanels[0] ? _serverPanel : const SizedBox(),
          _hideMainChat(context)
              ? const SizedBox()
              : Flexible(
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
    );
  }
}
