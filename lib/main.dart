// Copyright Terry Hancock 2023
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:biometric_storage/biometric_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:url_launcher/url_launcher.dart';

import 'input_prompt.dart';
import 'chat_item.dart';
import 'image_view.dart';

void main() {
  runApp(const NeptuneFOB());
}

class NeptuneFOB extends StatelessWidget {
  const NeptuneFOB({super.key});

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
  final List<Widget> _editBtns = [];
  final Map<String, List<ChatItem>> _messageLists = {'Default': []};
  final Map<String, bool> _messageListNews = {'Default': false};
  String _currentChannel = 'Default';
  final List<String> _userList = [];
  final List<String> _serverList = [];
  List<DropdownMenuItem<String>> _serverItemList = [];
  final TextEditingController _controller = TextEditingController();

  final ScrollController _scroller = ScrollController();

  final List<String> _typingList = [];
  final Stopwatch _sentTypingPing = Stopwatch();

  late String _font = '';
  late double _fontSize = 22;

  bool _newClient = true;
  late Socket socket;
  String _userName = '';

  bool _showServerPanel = false;
  bool _showUserPanel = false;

  late Uint8List? _imageBytes;
  bool _imagePaste = false;

  final Color _neptuneColor = const Color.fromARGB(255, 68, 99, 179);

  int _editIndex = -1;
  final TextEditingController _editingController = TextEditingController();

  @override
  void initState() {
    socket = io(
      '',
      OptionBuilder()
          .setTransports(['websocket'])
          // .setExtraHeaders({
          //   "maxHttpBufferSize": 50000000,
          //   "pingTimeout": 600000,
          // })
          .disableAutoConnect()
          .build(),
    );

    _initSettings();

    socket.onConnect((data) {
      _currentChannel = 'Default';
      if (_userName != '') {
        socket.emit('usernameSet', _userName);
        _messageLists.clear();
        _userList.clear();
      }
    });
    socket.onConnectError(
        (error) => _messageLists['Default']!.add(ChatItem(-1, 'System', 'Default', 't', 'Error! $error')));
    socket.onConnectTimeout((data) => _messageLists['Default']!
        .add(ChatItem(-1, 'System', 'Default', 't', 'Im going to stop trying now :) (timeout)')));
    socket.on(
      'chatMessage',
      (message) {
        ChatItem newMessage = ChatItem.fromJson(message);
        _addNewChat(newMessage);
        _userNoLongerTyping(newMessage.userName);
      },
    );
    socket.on('backlogFill', (itemJson) {
      ChatItem backlogMessage = ChatItem.fromJson(itemJson);
      _addChatItem(backlogMessage);
    });
    socket.on('image', (imageMessage) {
      ChatItem newImage = ChatItem.fromJson(imageMessage.first);
      _addNewChat(newImage);

      // ack response
      imageMessage.last(null);
    });
    socket.on('backlogImage', (imageMessage) {
      ChatItem newImage = ChatItem.fromJson(imageMessage.first);
      _addChatItem(newImage);

      // ack response
      imageMessage.last(null);
    });
    socket.on('usernameSend', (userName) {
      _userName = userName;
      _addServer();
    });
    socket.on('userListSend', (userList) => _userList.addAll(userList.cast<String>()));
    socket.on('userJoin', (userName) => _userConnect(userName));
    socket.on('userLeave', (userName) => _userDisconnect(userName));
    socket.on('userTyping', (itemJson) {
      ChatItem item = ChatItem.fromJson(itemJson);
      _userIsTyping(item);
    });
    socket.on('edit', (itemJson) {
      ChatItem editItem = ChatItem.fromJson(itemJson);
      _editItem(editItem);
    });
    socket.on('delete', (itemJson) {
      ChatItem deleteItem = ChatItem.fromJson(itemJson);
      _deleteItem(deleteItem);
    });

    _sentTypingPing.start();

    _scroller.addListener(() => _scrollActions());

    super.initState();
  }

  void _scrollActions() {
    if (_scroller.position.pixels == _scroller.position.maxScrollExtent) {
      _requestMore();
    }
  }

  void _initSettings() async {
    bool loadCheck = await _loadSettings();
    if (loadCheck) {
      setState(() {});
      return;
    }
    setState(() {
      _newClientCalls();
    });
  }

  Future<bool> _loadSettings() async {
    if ((await BiometricStorage().canAuthenticate()) != CanAuthenticateResponse.success) {
      // TODO bro idk tbh
    }
    try {
      BiometricStorageFile settingsStore = await BiometricStorage().getStorage('settings');
      String? settingsJson = await settingsStore.read();
      Map settings = jsonDecode(settingsJson!);
      socket.io.uri = settings['currentServer'];
      if (socket.disconnected && socket.io.uri.isNotEmpty) {
        socket.connect();
      }
      _userName = settings['username'];
      _font = settings['font'];
      _fontSize = settings['fontSize'];
      String serverListJson = settings['serverList'];
      serverListJson = serverListJson.substring(1, (serverListJson.length - 1));
      List<String> servers = serverListJson.split(", ");
      for (int i = 0; i < servers.length; i++) {
        if (!_serverList.contains(servers[i]) && !(servers[i] == '')) {
          _serverList.add(servers[i]);
        }
      }
      _setServerItems();
      return !(_serverList.isEmpty || _userName.isEmpty);
    } catch (e) {
      return false;
    }
  }

  void _saveSettings() async {
    Map settings = {
      '"currentServer"': '"${socket.io.uri}"',
      '"username"': '"$_userName"',
      '"font"': '"$_font"',
      '"fontSize"': _fontSize,
      '"serverList"': '"${_serverList.toString()}"',
    };
    BiometricStorageFile settingsStore = await BiometricStorage().getStorage(
      'settings',
      options: StorageFileInitOptions(
        authenticationRequired: false,
      ),
    );
    settingsStore.write(settings.toString());
  }

  void removeChatItem(int itemIndex) {
    _messageLists[_currentChannel]!
        .remove(_messageLists[_currentChannel]!.firstWhere((item) => item.itemIndex == itemIndex));
  }

  void _addServer() async {
    _serverList.removeWhere((element) => element == '');
    if (socket.io.uri.isEmpty) {
      return;
    }
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
    ChatItem item = ChatItem(-1, _userName, _currentChannel, 't', message);
    socket.emit('chatMessage', item.toJson().toString());
  }

  void _addChatItem(ChatItem item) {
    setState(() {
      _messageLists.putIfAbsent(item.channel, () => []);
      _messageListNews.putIfAbsent(item.channel, () => false);
      _messageLists[item.channel]!.add(item);
      _verifyMessageOrder(item.channel);
      if (_editIndex >= 0) {
        _editIndex++;
      }
      setState(() {});
    });
  }

  void _addNewChat(ChatItem item) {
    _addChatItem(item);
    if (item.channel != _currentChannel) {
      _messageListNews[item.channel] = true;
    }
    if (item.userName != _userName) {
      AudioPlayer().play(
        AssetSource('message.mp3'),
        volume: .25,
        mode: PlayerMode.lowLatency,
      );
    }
  }

  Future<Uint8List> _getImage(File image) async {
    return await image.readAsBytes();
  }

  void _sendImageFile(String path) async {
    File file = File(path);
    Uint8List bytes = await _getImage(file);
    _sendImageBytes(bytes);
  }

  void _sendImageBytes(Uint8List bytes) async {
    ChatItem item = ChatItem(-1, _userName, _currentChannel, 'i', bytes);
    socket.emitWithBinary('image', item.toJson().toString());
  }

  void _testMessage() {
    if (_imagePaste) {
      _sendImageBytes(_imageBytes!);
      _imagePaste = false;
    }
    String message = _controller.text;
    _controller.text = '';
    if (!_isURL(message) && _isImageFile(message)) {
      _sendImageFile(message);
    } else if (!(message == '')) {
      _sendMessage(message);
    }
  }

  bool _isImageFile(String text) {
    return text.endsWith(".jpg") || text.endsWith(".jpeg") || text.endsWith(".png") || text.endsWith(".gif");
  }

  bool _isURL(String text) {
    return text.startsWith("http");
  }

  void _newClientCalls() {
    if (_newClient) {
      if (_userName.isEmpty) {
        _changeUserName();
      }
      if (socket.io.uri.isEmpty) {
        _changeServerAddress();
      }
      _newClient = false;
    }
  }

  void _changeUserName() {
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
              socket.emit('usernameSet', controller.text);
              Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }

  void _changeServerAddress() {
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
              if (socket.connected) {
                socket.disconnect();
              }
              socket.io.uri = controller.text;
              Navigator.of(context).pop();
              socket.connect();
            },
          );
        },
      ),
    );
  }

  void _toggleServerPanel() {
    setState(() {
      _showServerPanel = !_showServerPanel;
    });
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

  void _userIsTyping(ChatItem item) {
    setState(() {
      if (item.userName != _userName && !_typingList.contains(item.userName) && _currentChannel == item.channel) {
        _typingList.add(item.userName);
      }
    });
    Timer(const Duration(seconds: 3), () {
      _userNoLongerTyping(item.userName);
    });
  }

  void _userNoLongerTyping(String userName) {
    setState(() {
      _typingList.remove(userName);
    });
  }

  void _thisClientTyping() {
    if (_sentTypingPing.elapsedMilliseconds > 1000) {
      socket.emit('userTyping', ChatItem(-1, _userName, _currentChannel, 't', 't').toJson().toString());
      _sentTypingPing.reset();
    }
  }

  void _increaseFontSize() {
    setState(() {
      _fontSize++;
    });
  }

  void _decreaseFontSize() {
    setState(() {
      _fontSize--;
    });
  }

  void _changeFont(String font) {
    setState(() {
      _font = font;
    });
  }

  void _verifyMessageOrder(String channel) async {
    setState(() {
      if (_messageLists[channel] != null) {
        _messageLists[channel]!.sort();
      }
    });
    List<ChatItem> items = _messageLists[channel]!;
    for (var i = 1; i < items.length; i++) {
      if (items[i - 1].itemIndex == items[i].itemIndex) {
        items.remove(items[i - 1]);
      }
    }
  }

  void _pushImage(Image image) {
    Navigator.of(context).push(
      DialogRoute<void>(
        context: context,
        builder: (BuildContext context) => ImageView(
          image: image,
        ),
      ),
    );
  }

  void _requestMore() async {
    ChatItem item = ChatItem(_messageLists[_currentChannel]!.last.itemIndex, _userName, _currentChannel, 'r', null);
    socket.emit('messageRequest', item.toJson().toString());
  }

  void _pasteImage() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null) {
      _controller.text = _controller.text + data.text!;
      return;
    }
    _imageBytes = await Pasteboard.image;
    _imagePaste = true;
    setState(() {});
  }

  void _selectImage() async {
    XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
    _imageBytes = await image!.readAsBytes();
    _imagePaste = true;
    setState(() {});
  }

  void _addChannel() {
    Navigator.of(context).push(
      DialogRoute<void>(
        context: context,
        builder: (BuildContext context) {
          TextEditingController controller = TextEditingController();
          return InputPrompt(
            controller: controller,
            formTitle: 'New Channel',
            onSubmit: () {
              if (controller.text.isEmpty || controller.text.length > 16) {
                return;
              }
              _changeChannel(controller.text);
              Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }

  void _changeChannel(String newChannel) {
    setState(() {
      _editIndex = -1;
      _messageLists.putIfAbsent(newChannel, () => []);
      _messageListNews.putIfAbsent(newChannel, () => false);
      _messageListNews[newChannel] = false;
      _currentChannel = newChannel;
    });
  }

  bool _hideMainChat(BuildContext context) {
    return MediaQuery.of(context).size.width < MediaQuery.of(context).size.height &&
        (_showServerPanel || _showUserPanel);
  }

  void _editMessage(int index) {
    setState(() {
      _editingController.text = '';
      _editIndex = index;
    });
  }

  void _submitEdit() {
    ChatItem initialItem = _messageLists[_currentChannel]![_editIndex];
    ChatItem editItem = ChatItem(
        initialItem.itemIndex, initialItem.userName, initialItem.channel, initialItem.type, _editingController.text);
    socket.emit('edit', editItem.toJson().toString());
  }

  void _editItem(ChatItem editedItem) {
    setState(() {
      _messageLists[editedItem.channel]!.removeWhere((element) => element.itemIndex == editedItem.itemIndex);
      _messageLists[editedItem.channel]!.add(editedItem);
      _verifyMessageOrder(editedItem.channel);
    });
  }

  void _requestDelete() {
    ChatItem deleteItem = _messageLists[_currentChannel]![_editIndex];
    socket.emit('delete', deleteItem.toJson().toString());
  }

  void _deleteItem(ChatItem deleteItem) {
    _messageLists[deleteItem.channel]!.removeWhere((element) => element.itemIndex == deleteItem.itemIndex);
  }

  @override
  Widget build(BuildContext context) {
    _userDisconnect(_userName);

    RoundedRectangleBorder panelShape = RoundedRectangleBorder(
      side: BorderSide(
        color: _neptuneColor,
        width: 5,
      ),
    );

    Widget serverPanel = const SizedBox();
    if (_showServerPanel) {
      serverPanel = Flexible(
        flex: 4,
        child: Material(
          shape: panelShape,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  'Server Name? IDK',
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: _fontSize * 0.73,
                    decoration: TextDecoration.underline,
                  ),
                  textAlign: TextAlign.center,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListView.separated(
                      separatorBuilder: (context, index) => const SizedBox(
                        height: 5,
                      ),
                      itemCount: _messageLists.entries.length + 1,
                      itemBuilder: (context, index) {
                        String text = '+ New Channel';
                        void Function()? changeChannel = () => _addChannel();
                        if (index < _messageLists.entries.length) {
                          text = _messageLists.keys.toList()[index];
                          changeChannel = () => _changeChannel(_messageLists.keys.toList()[index]);
                        }
                        bool newMessage = index != _messageLists.entries.length && _messageListNews[text]!;
                        return MaterialButton(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8.0)),
                          ),
                          color: _currentChannel == text ? _neptuneColor : const Color(0x00000000),
                          onPressed: changeChannel,
                          child: Row(
                            children: [
                              const Icon(Icons.tag),
                              const SizedBox(
                                width: 5,
                              ),
                              Flexible(
                                child: Text(
                                  '$text ${newMessage ? ' •' : ''}',
                                  style: TextStyle(
                                    fontSize: _fontSize * 0.64,
                                    fontFamily: _font,
                                    fontWeight: newMessage ? FontWeight.w900 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
    }

    Widget userPanel = const SizedBox();
    if (_showUserPanel) {
      userPanel = Flexible(
        flex: 4,
        child: Material(
          shape: panelShape,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
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
    }

    List<ChatItem> currentChat = [];
    if (_messageLists.isNotEmpty) {
      currentChat = _messageLists[_currentChannel]!;
    }

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: FlexibleSpaceBar(
          background: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: .2,
                alignment: Alignment.centerLeft,
                child: MaterialButton(
                  height: MediaQuery.of(context).size.height,
                  color: _neptuneColor,
                  hoverColor: Theme.of(context).cardColor,
                  onPressed: _toggleServerPanel,
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
                      onChanged: (serverURL) => _changeServer(serverURL!),
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
          serverPanel,
          (_hideMainChat(context))
              ? const SizedBox()
              : Flexible(
                  flex: 16,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          child: ListView.separated(
                            clipBehavior: Clip.none,
                            controller: _scroller,
                            reverse: true,
                            padding: const EdgeInsets.symmetric(),
                            shrinkWrap: true,
                            itemCount: currentChat.length,
                            itemBuilder: ((context, index) {
                              if (index == _editIndex) {
                                if (_editingController.text == '') {
                                  _editingController.text = currentChat[index].content;
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${currentChat[index].userName}: ',
                                      style: TextStyle(
                                        fontFamily: _font,
                                        fontSize: _fontSize,
                                      ),
                                    ),
                                    Flexible(
                                      child: TextField(
                                        controller: _editingController,
                                        minLines: 1,
                                        maxLines: 10,
                                        style: TextStyle(
                                          fontSize: _fontSize,
                                          fontFamily: _font,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () {
                                        _requestDelete();
                                        _editingController.text = '';
                                        setState(() {
                                          _editIndex = -1;
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 20),
                                    IconButton(
                                      icon: const Icon(Icons.cancel_outlined),
                                      onPressed: () {
                                        _editingController.text = '';
                                        setState(() {
                                          _editIndex = -1;
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 20),
                                    IconButton(
                                      icon: const Icon(Icons.check),
                                      onPressed: () {
                                        _submitEdit();
                                        _editingController.text = '';
                                        setState(() {
                                          _editIndex = -1;
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 20),
                                  ],
                                );
                              }
                              Row newRow = Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${currentChat[index].userName}: ',
                                    style: TextStyle(
                                      fontFamily: _font,
                                      fontSize: _fontSize,
                                    ),
                                  ),
                                ],
                              );
                              switch (currentChat[index].type) {
                                case 't':
                                  if (_isURL(currentChat[index].content) && _isImageFile(currentChat[index].content)) {
                                    newRow.children.add(
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context).size.width * 0.5,
                                          maxHeight: MediaQuery.of(context).size.height * 0.6,
                                        ),
                                        child: Image.network(
                                          currentChat[index].content,
                                          fit: BoxFit.scaleDown,
                                        ),
                                      ),
                                    );
                                    break;
                                  }
                                  if (currentChat[index].content.contains('http')) {
                                    List<Widget> newWidgets = [];
                                    List<String> split = currentChat[index].content.split(' ');
                                    String plainText = '';
                                    for (int i = 0; i < split.length; i++) {
                                      if (split[i].contains('http')) {
                                        if (plainText != '') {
                                          newWidgets.add(SelectableText.rich(_italicise(plainText)));
                                          plainText = '';
                                        }
                                        newWidgets.add(
                                          Flexible(
                                            child: InkWell(
                                              child: Text(
                                                split[i],
                                                style: TextStyle(
                                                  fontFamily: _font,
                                                  fontSize: _fontSize,
                                                  color: const Color.fromARGB(255, 53, 98, 203),
                                                ),
                                              ),
                                              onTap: () {
                                                try {
                                                  launchUrl(Uri.tryParse(currentChat[index].content)!);
                                                } catch (e) {
                                                  return;
                                                }
                                              },
                                            ),
                                          ),
                                        );
                                      } else {
                                        plainText += '${split[i]} ';
                                      }
                                    }
                                    if (plainText != '') {
                                      newWidgets.add(SelectableText.rich(_italicise(plainText)));
                                      plainText = '';
                                    }
                                    newRow.children.add(
                                      Flexible(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: newWidgets,
                                        ),
                                      ),
                                    );
                                    break;
                                  }
                                  newRow.children.add(
                                    Flexible(
                                      child: SelectableText.rich(_italicise(currentChat[index].content)),
                                    ),
                                  );
                                  break;
                                case 'i':
                                  Uint8List bytes = currentChat[index].content;
                                  newRow.children.add(
                                    Flexible(
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context).size.width * 0.8,
                                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                                        ),
                                        child: MaterialButton(
                                          onPressed: () => _pushImage(
                                            Image.memory(bytes),
                                          ),
                                          child: Image.memory(bytes),
                                        ),
                                      ),
                                    ),
                                  );
                                  break;
                                default:
                                  break;
                              }
                              _editBtns.add(const SizedBox());
                              return MouseRegion(
                                onEnter: (event) {
                                  setState(() {
                                    if (currentChat[index].type != 't' || currentChat[index].userName != _userName) {
                                      return;
                                    }
                                    _editBtns[index] = TextButton(
                                      style: const ButtonStyle(
                                        minimumSize: MaterialStatePropertyAll(Size(0, 0)),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () => _editMessage(index),
                                      child: Text(
                                        'Edit',
                                        style: TextStyle(
                                          fontSize: _fontSize,
                                          fontFamily: _font,
                                        ),
                                      ),
                                    );
                                  });
                                },
                                onExit: (event) {
                                  setState(() {
                                    _editBtns[index] = const SizedBox();
                                  });
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Flexible(child: newRow),
                                    _editBtns[index],
                                    const SizedBox(
                                      width: 15,
                                    )
                                  ],
                                ),
                              );
                            }),
                            separatorBuilder: (context, index) => const Divider(),
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
                            List<Widget> inputColumn = [];
                            inputColumn = [
                              SizedBox(
                                width: constraints.maxWidth - 130,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(10, 0, 0, 10),
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
                                                  .contains(const LogicalKeyboardKey(0x200000102)) ||
                                              RawKeyboard.instance.keysPressed
                                                  .contains(const LogicalKeyboardKey(0x200000103)))) {
                                        _controller.text = _controller.text.substring(0, _controller.text.length - 1);
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
                                width: constraints.maxWidth - 130,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
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
                                        color: const Color.fromARGB(255, 30, 55, 118),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ];
                            if (_imagePaste) {
                              inputColumn.insert(
                                0,
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: constraints.maxWidth - 130,
                                    maxHeight: MediaQuery.of(context).size.height * 0.3,
                                  ),
                                  child: IntrinsicWidth(
                                    child: Stack(
                                      children: [
                                        Image.memory(_imageBytes!),
                                        Align(
                                          alignment: Alignment.topRight,
                                          child: MaterialButton(
                                            height: 40,
                                            minWidth: 40,
                                            shape: const CircleBorder(),
                                            onPressed: () => {
                                              _imagePaste = false,
                                              setState(() {}),
                                            },
                                            child: const Icon(
                                              Icons.cancel_rounded,
                                              size: 40,
                                              color: Color.fromARGB(255, 219, 14, 14),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: MaterialButton(
                                    onPressed: _pasteImage,
                                    onLongPress: _selectImage,
                                    shape: const CircleBorder(),
                                    color: ColorScheme.fromSeed(seedColor: _neptuneColor).secondary,
                                    height: 50,
                                    minWidth: 50,
                                    hoverColor: Colors.blue,
                                    child: const Icon(Icons.add_sharp),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: inputColumn,
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                MaterialButton(
                                  onPressed: _testMessage,
                                  splashColor: Colors.lightBlue,
                                  hoverColor: Colors.blue,
                                  shape: const CircleBorder(),
                                  color: ColorScheme.fromSeed(seedColor: _neptuneColor).secondary,
                                  height: 50,
                                  minWidth: 50,
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
          userPanel,
        ],
      ),
      resizeToAvoidBottomInset: true,
      onDrawerChanged: (open) => open ? {} : _saveSettings(),
    );
  }

  TextSpan _italicise(String text) {
    List<String> split = text.split('*');
    if (split.length < 3) {
      return TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: _font,
          fontSize: _fontSize,
        ),
      );
    }
    TextSpan textSpan = TextSpan(
      children: [
        TextSpan(
          text: split.first,
          style: TextStyle(
            fontFamily: _font,
            fontSize: _fontSize,
          ),
        ),
      ],
    );
    for (var i = 1; i < split.length; i++) {
      if (i % 2 == 1) {
        textSpan.children?.add(
          TextSpan(
            text: split[i],
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
            text: split[i],
            style: TextStyle(
              fontFamily: _font,
              fontSize: _fontSize,
            ),
          ),
        );
      }
    }
    return textSpan;
  }
}
