import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:socket_io_client/socket_io_client.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:url_launcher/url_launcher.dart';

import 'address_prompt.dart';
import 'username_prompt.dart';
import 'chat_item.dart';
import 'image_view.dart';
import 'adjustable_scroll_controller.dart';
// import 'chat_message.dart';
// import 'image_message.dart';

void main() {
  runApp(const NeptuneFOB());
}

class NeptuneFOB extends StatelessWidget {
  const NeptuneFOB({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Neptune FOB',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        // primarySwatch: const MaterialColor(0x4463B3, {0x4463B3: Colors.blue}),
        // primaryColor: const Color.fromARGB(255, 68, 99, 179),
        // primaryColorDark: Colors.blueGrey,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 68, 99, 179),
          // primary: const Color.fromARGB(255, 68, 99, 179),
          // onPrimary: const Color.fromARGB(255, 68, 99, 179),
          brightness: Brightness.dark,
        ),
        fontFamily: 'CenturyGothic',
      ),
      home: const _MainChat(title: 'Project Neptune FOB'),
    );
  }
}

class _MainChat extends StatefulWidget {
  const _MainChat({required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<_MainChat> createState() => _MainChatState();
}

class _MainChatState extends State<_MainChat> {
  final Future<SharedPreferences> _settings = SharedPreferences.getInstance();

  final List<ChatItem> _messageList = [];
  final List<String> _userList = [];
  List<String> _serverList = [];
  List<DropdownMenuItem> _serverItemList = [];
  final TextEditingController _controller = TextEditingController();

  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final ScrollController _scroller = AdjustableScrollController(20);

  final List<String> _typingList = [];
  final Stopwatch _sentTypingPing = Stopwatch();

  late String _font = '';
  late double _fontSize = 22;

  bool _newClient = true;
  late Socket socket;
  String _userName = '';

  bool _showUserPanel = false;

  late Widget _userPanel;
  final Widget _closedUserPanel = const SizedBox();

  final Color _neptuneColor = const Color.fromARGB(255, 68, 99, 179);

  @override
  void initState() {
    _initSettings();

    socket = io(
      '',
      OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({
            "maxHttpBufferSize": 50000000,
            "pingTimeout": 600000,
          })
          .disableAutoConnect()
          .build(),
    );

    socket.onConnect((data) {
      if (_userName != '') {
        socket.emit('usernameSet', _userName);
        _messageList.clear();
        _userList.clear();
      }
    });

    socket.onConnectError((error) =>
        _messageList.add(ChatItem(-1, 'System', 't', 'Error! $error')));
    socket.onConnectTimeout((data) => _messageList.add(ChatItem(
        -1, 'System', 't', 'Im going to stop trying now :) (timeout)')));
    socket.on(
      'chatMessage',
      (message) {
        ChatItem newMessage = ChatItem.fromJson(message);
        _addChatItem(newMessage);
        _userNoLongerTyping(newMessage.userName);
      },
    );
    socket.on('image', (imageMessage) {
      ChatItem newImage = ChatItem.fromJson(imageMessage.first);
      _addChatItem(newImage);

      // ack response
      imageMessage.last(null);
    });
    socket.on('usernameSend', (userName) {
      _userName = userName;
      _addServer();
      _saveUsername();
    });
    socket.on('userListSend',
        (userList) => _userList.addAll(userList.cast<String>()));
    socket.on('userJoin', (userName) => _userConnect(userName));
    socket.on('userLeave', (userName) => _userDisconnect(userName));
    socket.on('userTyping', (userName) => _userIsTyping(userName));

    _sentTypingPing.start();

    _scroller.addListener(() => _scrollActions());

    super.initState();
  }

  void _scrollActions() {
    if (_scroller.position.pixels == _scroller.position.minScrollExtent) {
      WidgetsBinding.instance.addPostFrameCallback((data) => _scrollToEnd());
    } else if (_scroller.position.pixels ==
        _scroller.position.maxScrollExtent) {
      _requestMore();
    }
  }

  void _initSettings() async {
    final SharedPreferences settings = await _settings;
    setState(() {
      _addressController.text = settings.getString('address') ?? '';
      if (_addressController.text.isNotEmpty) {
        socket.io.uri = _addressController.text;
      }
      if (socket.disconnected && socket.io.uri.isNotEmpty) {
        socket.connect();
      }
      _serverList = settings.getStringList('serverList') ?? [];
      _setServerItems();
      _userName = settings.getString('userName') ?? '';
      _font = settings.getString('font') ?? 'CenturyGothic';
      _fontSize = settings.getDouble('fontSize') ?? 22;
    });
  }

  void removeChatItem(int itemIndex) {
    _messageList
        .remove(_messageList.firstWhere((item) => item.itemIndex == itemIndex));
  }

  void _saveAddress() async {
    final SharedPreferences settings = await _settings;
    settings.setString('address', socket.io.uri);
  }

  void _saveUsername() async {
    final SharedPreferences settings = await _settings;
    settings.setString('userName', _userName);
  }

  void _saveFont() async {
    final SharedPreferences settings = await _settings;
    settings.setString('font', _font);
  }

  void _saveFontSize() async {
    final SharedPreferences settings = await _settings;
    settings.setDouble('fontSize', _fontSize);
  }

  void _saveServerList() async {
    final SharedPreferences settings = await _settings;
    settings.setStringList('serverList', _serverList);
  }

  void _addServer() async {
    if (!_serverList.contains(socket.io.uri)) {
      _serverList.add(socket.io.uri);
      if (_serverList.length > 5) {
        _serverList.remove(_serverList.first);
      }
    } else {
      _serverList.remove(socket.io.uri);
      _serverList.add(socket.io.uri);
    }
    _setServerItems();
    _saveServerList();
    _saveAddress();
    setState(() {});
  }

  void _setServerItems() {
    _serverItemList = [];
    for (var i = _serverList.length - 1; i >= 0; i--) {
      _serverItemList.add(
        DropdownMenuItem(
          value: _serverList[i],
          child: Text(_serverList[i]),
        ),
      );
    }
  }

  void _changeServer(String serverURL) async {
    if (socket.connected) {
      socket.disconnect();
    }
    socket.io.uri = serverURL;
    socket.connect();
  }

  void _sendMessage(String message) {
    socket.emit('chatMessage', message.toString());
  }

  void _addChatItem(ChatItem item) {
    setState(() {
      _messageList.add(item);
      _verifyMessageOrder();
    });
    if (item.userName != _userName) {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  void _sendImage(File image) async {
    Uint8List bytes = await image.readAsBytes();
    socket.emitWithBinary('image', bytes);
  }

  void _testMessage() {
    String message = _controller.text;
    _controller.text = '';
    if (!_isURL(message) && _isImageFile(message)) {
      _sendImage(
        File(message),
      );
    } else if (!(message == '')) {
      _sendMessage(message);
    }
  }

  bool _isImageFile(String text) {
    return text.endsWith(".jpg") ||
        text.endsWith(".jpeg") ||
        text.endsWith(".png") ||
        text.endsWith(".gif");
  }

  bool _isURL(String text) {
    return text.startsWith("http");
  }

  void _scrollToEnd() async {
    await _scroller.animateTo(_scroller.position.minScrollExtent,
        duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
  }

  void _newClientCalls() {
    if (_newClient) {
      if (_userName.isEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) =>
                UserNamePrompt(controller: _userNameController, socket: socket),
          ),
        );
      }
      if (socket.io.uri.isEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) =>
                AddressPrompt(controller: _addressController, socket: socket),
          ),
        );
      }
      _newClient = false;
    }
  }

  void _changeUserName() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            UserNamePrompt(controller: _userNameController, socket: socket),
      ),
    );
  }

  void _changeServerAddress() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            AddressPrompt(controller: _addressController, socket: socket),
      ),
    );
  }

  void _toggleUserPanel() {
    setState(() {
      _showUserPanel = !_showUserPanel;
    });
  }

  void _userConnect(String userName) {
    setState(() {
      if (!_userList.contains(userName)) {
        _userList.add(userName);
      }
    });
  }

  void _userDisconnect(String userName) {
    setState(() {
      _userList.remove(userName);
    });
  }

  void _userIsTyping(String userName) {
    setState(() {
      if (userName != _userName && !_typingList.contains(userName)) {
        _typingList.add(userName);
      }
    });
    Timer(const Duration(seconds: 3), () {
      _userNoLongerTyping(userName);
    });
  }

  void _userNoLongerTyping(String userName) {
    setState(() {
      _typingList.remove(userName);
    });
  }

  void _thisClientTyping() {
    if (_sentTypingPing.elapsedMilliseconds > 1000) {
      socket.emit('userTyping', '');
      _sentTypingPing.reset();
    }
  }

  void _increaseFontSize() {
    setState(() {
      _fontSize++;
    });
    _saveFontSize();
  }

  void _decreaseFontSize() {
    setState(() {
      _fontSize--;
    });
    _saveFontSize();
  }

  void _changeFont(String font) {
    setState(() {
      _font = font;
    });
    _saveFont();
  }

  void _verifyMessageOrder() async {
    _messageList.sort();
    for (var i = 1; i < _messageList.length; i++) {
      if (_messageList[i - 1].itemIndex == _messageList[i].itemIndex) {
        _messageList.remove(_messageList[i - 1]);
      }
    }
  }

  void _pushImage(Image image) async {
    await Navigator.of(context).push(
      DialogRoute<void>(
        context: context,
        builder: (BuildContext context) => ImageView(
          image: image,
        ),
      ),
    );
  }

  void _requestMore() async {
    socket.emit('messageRequest', _messageList.last.itemIndex);
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    _userDisconnect(_userName);

    if (_newClient) {
      WidgetsBinding.instance.addPostFrameCallback((data) => _newClientCalls());
    }

    _userPanel = SizedBox(
      // width: max(MediaQuery.of(context).size.width * 0.2, 100), TODO
      width: MediaQuery.of(context).size.width * 0.2,
      child: Material(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: _neptuneColor,
            width: 5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(
                height: 15,
              ),
              Text(
                'Connected Users',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: _fontSize * 0.73,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 15,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView.separated(
                    itemCount: _userList.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (BuildContext context, int index) {
                      return Text(
                        _userList[index],
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: _fontSize * 0.64,
                        ),
                        overflow: TextOverflow.clip,
                        textAlign: TextAlign.center,
                        softWrap: false,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        flexibleSpace: FlexibleSpaceBar(
          background: FractionallySizedBox(
            widthFactor: .2,
            alignment: Alignment.topRight,
            child: MaterialButton(
              color: _neptuneColor,
              hoverColor: Theme.of(context).cardColor,
              onPressed: _toggleUserPanel,
              child: const Icon(
                Icons.people,
                size: 40,
              ),
            ),
          ),
        ),
      ),
      drawer: IntrinsicWidth(
        child: Material(
          type: MaterialType.card,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  textScaleFactor: 1.75,
                  style: TextStyle(
                    fontFamily: _font,
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Font Size: ',
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 22,
                      ),
                    ),
                    Text(
                      '${_fontSize.floor()}   ',
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 22,
                      ),
                    ),
                    const Spacer(),
                    MaterialButton(
                      onPressed: _decreaseFontSize,
                      minWidth: 25,
                      color: _neptuneColor,
                      hoverColor: Colors.amber,
                      child: const Icon(Icons.text_decrease),
                    ),
                    const SizedBox(width: 10),
                    MaterialButton(
                      onPressed: _increaseFontSize,
                      minWidth: 25,
                      color: _neptuneColor,
                      hoverColor: Colors.amber,
                      child: const Icon(Icons.text_increase),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 15,
                ),
                Row(
                  children: [
                    Text(
                      'Font:',
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 22,
                      ),
                    ),
                    const Spacer(),
                    DropdownButton(
                        value: _font,
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 22,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: '',
                            child: Text('Roboto'),
                          ),
                          DropdownMenuItem(
                            value: 'CenturyGothic',
                            child: Text('CenturyGothic'),
                          ),
                          DropdownMenuItem(
                            value: 'Helvetica',
                            child: Text('Helvetica'),
                          ),
                          DropdownMenuItem(
                            value: 'ComicSans',
                            child: Text('ComicSans'),
                          ),
                          DropdownMenuItem(
                            value: 'Impact',
                            child: Text('Impact'),
                          ),
                        ],
                        onChanged: (newFont) {
                          try {
                            _changeFont(newFont!);
                          } catch (e) {
                            _changeFont('Roboto');
                          }
                        }),
                  ],
                ),
                const SizedBox(
                  height: 15,
                ),
                Row(
                  children: [
                    Text(
                      'Username: $_userName  ',
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 22,
                      ),
                    ),
                    const Spacer(),
                    MaterialButton(
                      onPressed: _changeUserName,
                      minWidth: 25,
                      color: _neptuneColor,
                      hoverColor: Colors.amber,
                      child: Text(
                        'Change',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 25,
                ),
                Row(
                  children: [
                    Text(
                      'Servers:',
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 22,
                      ),
                    ),
                    const Spacer(),
                    DropdownButton(
                      value: socket.io.uri,
                      items: _serverItemList,
                      onChanged: (serverURL) => _changeServer(serverURL),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 25,
                ),
                Center(
                  child: MaterialButton(
                    onPressed: _changeServerAddress,
                    minWidth: 25,
                    color: _neptuneColor,
                    hoverColor: Colors.amber,
                    child: Text(
                      'Change Server Address',
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            // curve: Curves.bounceOut,
            curve: Curves.ease,
            width: MediaQuery.of(context).size.width -
                ((_showUserPanel ? 1 : 0) *
                    MediaQuery.of(context).size.width *
                    0.2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: ListView.separated(
                        clipBehavior: Clip.none,
                        controller: _scroller,
                        reverse: true,
                        // physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(),
                        shrinkWrap: true,
                        itemCount: _messageList.length,
                        itemBuilder: ((context, index) {
                          Row newRow = Row(
                            children: [
                              Text(
                                '${_messageList[index].userName}: ',
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: _fontSize,
                                ),
                              ),
                            ],
                          );
                          switch (_messageList[index].type) {
                            case 't':
                              if (_isURL(_messageList[index].content) &&
                                  _isImageFile(_messageList[index].content)) {
                                newRow.children.add(
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.5,
                                      maxHeight:
                                          MediaQuery.of(context).size.height *
                                              0.6,
                                    ),
                                    child: Image.network(
                                      _messageList[index].content,
                                      fit: BoxFit.scaleDown,
                                    ),
                                  ),
                                );
                                break;
                              }
                              if (_messageList[index].content.contains('*')) {
                                TextSpan textSpan = TextSpan(
                                  children: [
                                    TextSpan(
                                      text: _messageList[index]
                                          .content
                                          .split('*')
                                          .first,
                                      style: TextStyle(
                                        fontFamily: _font,
                                        fontSize: _fontSize,
                                      ),
                                    ),
                                  ],
                                );
                                for (var i = 1;
                                    i <
                                        _messageList[index]
                                            .content
                                            .split('*')
                                            .length;
                                    i++) {
                                  if (i % 2 == 1) {
                                    textSpan.children?.add(
                                      TextSpan(
                                        text: _messageList[index]
                                            .content
                                            .split('*')[i],
                                        style: TextStyle(
                                          fontFamily: _font,
                                          fontSize: _fontSize,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    );
                                  } else {
                                    textSpan.children?.add(
                                      TextSpan(
                                        text: _messageList[index]
                                            .content
                                            .split('*')[i],
                                        style: TextStyle(
                                          fontFamily: _font,
                                          fontSize: _fontSize,
                                        ),
                                      ),
                                    );
                                  }
                                }
                                newRow.children
                                    .add(Flexible(child: Text.rich(textSpan)));
                                break;
                              }
                              if (_isURL(_messageList[index].content)) {
                                newRow.children.add(
                                  Flexible(
                                    child: InkWell(
                                      child: Text(
                                        _messageList[index].content,
                                        style: TextStyle(
                                          fontFamily: _font,
                                          fontSize: _fontSize,
                                          color: const Color.fromARGB(
                                              255, 53, 98, 203),
                                        ),
                                      ),
                                      onTap: () {
                                        try {
                                          launchUrl(Uri.tryParse(
                                              _messageList[index].content)!);
                                        } catch (e) {
                                          return;
                                        }
                                      },
                                    ),
                                  ),
                                );
                                break;
                              }
                              newRow.children.add(
                                Flexible(
                                  child: SelectableText(
                                    _messageList[index].content,
                                    style: TextStyle(
                                      fontFamily: _font,
                                      fontSize: _fontSize,
                                    ),
                                  ),
                                ),
                              );
                              break;
                            case 'i':
                              newRow.children.add(
                                Flexible(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.8,
                                      maxHeight:
                                          MediaQuery.of(context).size.height *
                                              0.4,
                                    ),
                                    child: MaterialButton(
                                      onPressed: () => _pushImage(
                                        Image.memory(
                                            _messageList[index].content),
                                      ),
                                      child: Image.memory(
                                        _messageList[index].content,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                              break;
                            case 'b':
                              newRow.children.add(
                                MaterialButton(
                                  onPressed: () => _requestMore(),
                                ),
                              );
                              break;
                            default:
                              break;
                          }
                          return newRow;
                        }),
                        separatorBuilder: (context, index) => const Divider(),
                      ),
                    ),
                  ),
                ),
                Material(
                  color: _neptuneColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (buildContext, constraints) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: constraints.maxWidth - 75,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 0, 0, 10),
                                  child: TextFormField(
                                    style: TextStyle(
                                      fontFamily: _font,
                                      fontSize: _fontSize,
                                    ),
                                    controller: _controller,
                                    onFieldSubmitted: (message) {
                                      _testMessage();
                                    },
                                    onChanged: (message) {
                                      _thisClientTyping();
                                      if (message.characters.isNotEmpty &&
                                          message.characters.last == '\n' &&
                                          !(RawKeyboard.instance.keysPressed
                                                  .contains(
                                                      const LogicalKeyboardKey(
                                                          0x200000102)) ||
                                              RawKeyboard.instance.keysPressed
                                                  .contains(
                                                      const LogicalKeyboardKey(
                                                          0x200000103)))) {
                                        _controller.text = _controller.text
                                            .substring(
                                                0, _controller.text.length - 1);
                                        _testMessage();
                                      }
                                    },
                                    onEditingComplete: () => _testMessage(),
                                    minLines: 1,
                                    maxLines: 20,
                                    autofocus: true,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: _fontSize * 0.36,
                                width: constraints.maxWidth - 75,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(15, 0, 0, 0),
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _typingList.length,
                                    itemBuilder: ((context, index) {
                                      return Text(
                                        '${_typingList[index]} is typing...',
                                        style: TextStyle(
                                          height: .45,
                                          fontFamily: _font,
                                          fontSize: _fontSize * 0.55,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      );
                                    }),
                                    separatorBuilder: (context, index) => Text(
                                      ' l ',
                                      style: TextStyle(
                                        height: .45,
                                        fontFamily: _font,
                                        fontSize: _fontSize * 0.55,
                                        fontWeight: FontWeight.w900,
                                        color: const Color.fromARGB(
                                            255, 30, 55, 118),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            width: 15,
                          ),
                          FloatingActionButton(
                            onPressed: _testMessage,
                            tooltip: 'Send',
                            splashColor: Colors.lightBlue,
                            hoverColor: Colors.blue,
                            mini: true,
                            child: const Icon(Icons.send),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              if (_showUserPanel) {
                return _userPanel;
              } else {
                return _closedUserPanel;
              }
            },
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
    );
  }
}
