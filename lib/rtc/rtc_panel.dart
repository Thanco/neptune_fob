import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:neptune_fob/data/socket_handler.dart';
import 'package:neptune_fob/rtc/remote_connection.dart';
import 'package:socket_io_client/socket_io_client.dart';

class RTCPanel extends StatelessWidget {
  const RTCPanel({super.key});

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
      home: const OneTwoThree(),
    );
  }
}

class OneTwoThree extends StatefulWidget {
  const OneTwoThree({super.key});

  @override
  State<OneTwoThree> createState() => _OneTwoThreeState();
}

class _OneTwoThreeState extends State<OneTwoThree> {
  // RTCIceConnectionState _iceState = RTCIceConnectionState.RTCIceConnectionStateNew;
  // late IOWebSocketChannel _webSocketChannel;
  late Socket _socket;

  final _localVideoRenderer = RTCVideoRenderer();
  // final _remoteVideoRenderer = RTCVideoRenderer();
  // final List<RTCVideoRenderer> _remoteVideoRenderes = [];

  // RTCPeerConnection? _peerConnection;
  final List<Map<int, RTCIceCandidate>> iceCandidates = [];
  final Map<int, RemoteConnection> _remoteConnections = {};
  MediaStream? _localStream;

  int _id = -1;

  void _connectToSignalingServer(String serverUri) {
    _socket = io(
        serverUri,
        OptionBuilder()
            .setTransports(['websocket'])
            // .setExtraHeaders({
            //   "maxHttpBufferSize": 50000000,
            //   "pingTimeout": 600000,
            // })
            .disableAutoConnect()
            .build());
    // _webSocketChannel = IOWebSocketChannel.connect(serverUri);
    _setSocketListeners();
    // _webSocketChannel.stream.listen((message) async {
    //   await _handleSignalingMessage(json.decode(message));
    // });
    _socket.connect();
  }

  void _setSocketListeners() {
    _socket.onConnect((data) => print('Socket Connected'));
    _socket.onError((data) => print(data));
    _socket.on('serverResponse', (responseJson) async {
      Map<String, dynamic> response = jsonDecode(responseJson);
      print('Client connected');
      await _getUserMedia();
      _id = response['id'];
      print('This client\'s id = $_id');
      List<int> peerIDs = response['ids'].cast<int>();
      if (peerIDs.isEmpty) {
        print('Client is alone');
        return;
      }
      for (int i = 0; i < peerIDs.length; i++) {
        RemoteConnection rc = RemoteConnection(peerIDs[i], _localStream!, rebuild, _onIceCandidate, _disposeConnection);
        await rc.init(iceCandidates);
        _remoteConnections.putIfAbsent(peerIDs[i], () => rc);
        await _sendOffer(peerIDs[i]);
      }
    });
    _socket.on('offer', (offerJson) async {
      Map<String, dynamic> offerMap = jsonDecode(offerJson);
      RTCSessionDescription offer = RTCSessionDescription(
        offerMap['sdp'],
        'offer',
      );

      final RemoteConnection rc =
          RemoteConnection(offerMap['fromID'], _localStream!, rebuild, _onIceCandidate, _disposeConnection);
      await rc.init(iceCandidates);

      print('before');
      _remoteConnections.putIfAbsent(rc.id, () => rc);
      print('after');

      // await _peerConnection?.setRemoteDescription(offer);
      await rc.setRemoteDescription(offer);

      // RTCSessionDescription answer = await _peerConnection!.createAnswer({});
      // await _peerConnection?.setLocalDescription(answer);
      RTCSessionDescription answer = await rc.createAnswer();

      _socket.emit(
          'answer',
          json.encode({
            'id': rc.id,
            'fromID': _id,
            'sdp': answer.sdp,
          }));
      // _sendSignalingMessage({
      //   'type': 'answer',
      //   'id': rc.id,
      //   'fromID': _id,
      //   'sdp': answer.sdp,
      // });
      print('Offer recived from ${offerMap['fromID']}');
    });
    _socket.on('answer', (answerJson) async {
      Map<String, dynamic> answerMap = jsonDecode(answerJson);
      // if (_iceState == RTCIceConnectionState.RTCIceConnectionStateCompleted ||
      //     _iceState == RTCIceConnectionState.RTCIceConnectionStateConnected) {
      //   break;
      // }

      RTCSessionDescription answer = RTCSessionDescription(
        answerMap['sdp'],
        'answer',
      );

      // await _peerConnection?.setRemoteDescription(answer);
      await _remoteConnections[answerMap['fromID']]!.setRemoteDescription(answer);

      print('Answer recived from ${answerMap['fromID']}');
    });
    _socket.on('candidate', (candidateJson) {
      Map<String, dynamic> candidateMap = jsonDecode(candidateJson);
      RTCIceCandidate candidate = RTCIceCandidate(
        candidateMap['candidate']['candidate'].toString(),
        candidateMap['candidate']['sdpMid'],
        candidateMap['candidate']['sdpMlineIndex'],
      );
      int id = candidateMap['fromID'];
      RemoteConnection? rc = _remoteConnections[id];
      if (rc == null) {
        iceCandidates.add({id: candidate});
        return;
      }
      rc.addIceCandidate(candidate);

      // await _peerConnection.addCandidate(candidate);
    });
  }

  //////
  // Future<void> _handleSignalingMessage(dynamic message) async {
  //   String type = message['type'];
  //
  //   switch (type) {
  //     case 'serverResponse':
  //       print('Client connected');
  //       await _getUserMedia();
  //       _id = message['id'];
  //       print('This client\'s id = $_id');
  //       List<int> peerIDs = message['ids'].cast<int>();
  //       if (peerIDs.isEmpty) {
  //         print('Client is alone');
  //         break;
  //       }
  //       for (int i = 0; i < peerIDs.length; i++) {
  //         RemoteConnection rc = RemoteConnection(peerIDs[i], _localStream!, rebuild, _onIceCandidate);
  //         await rc.init();
  //         _remoteConnections.putIfAbsent(peerIDs[i], () => rc);
  //         await _sendOffer(peerIDs[i]);
  //       }
  //       break;
  //     case 'offer':
  //       print('Offer recived from ${message['fromID']}');
  //       RTCSessionDescription offer = RTCSessionDescription(
  //         message['sdp'],
  //         'offer',
  //       );
  //
  //       final RemoteConnection rc = RemoteConnection(message['fromID'], _localStream!, rebuild, _onIceCandidate);
  //       await rc.init();
  //
  //       _remoteConnections.putIfAbsent(rc.id, () => rc);
  //
  //       // await _peerConnection?.setRemoteDescription(offer);
  //       await rc.setRemoteDescription(offer);
  //
  //       // RTCSessionDescription answer = await _peerConnection!.createAnswer({});
  //       // await _peerConnection?.setLocalDescription(answer);
  //       RTCSessionDescription answer = await rc.createAnswer();
  //
  //       _socket.emit('answer', {
  //         'id': rc.id,
  //         'fromID': _id,
  //         'sdp': answer.sdp,
  //       });
  //       // _sendSignalingMessage({
  //       //   'type': 'answer',
  //       //   'id': rc.id,
  //       //   'fromID': _id,
  //       //   'sdp': answer.sdp,
  //       // });
  //       break;
  //
  //     case 'answer':
  //       print('Answer recived from ${message['fromID']}');
  //       // if (_iceState == RTCIceConnectionState.RTCIceConnectionStateCompleted ||
  //       //     _iceState == RTCIceConnectionState.RTCIceConnectionStateConnected) {
  //       //   break;
  //       // }
  //
  //       RTCSessionDescription answer = RTCSessionDescription(
  //         message['sdp'],
  //         'answer',
  //       );
  //
  //       // await _peerConnection?.setRemoteDescription(answer);
  //       await _remoteConnections[message['fromID']]!.setRemoteDescription(answer);
  //       break;
  //     case 'candidate':
  //       Map<String, dynamic> candidateMap = jsonDecode(message['candidate']);
  //       RTCIceCandidate candidate = RTCIceCandidate(
  //         candidateMap['candidate'],
  //         candidateMap['sdpMid'],
  //         candidateMap['sdpMLineIndex'],
  //       );
  //       _remoteConnections.values.forEach((element) async {
  //         await element.peerConnection.addCandidate(candidate);
  //       });
  //       // await _peerConnection.addCandidate(candidate);
  //       break;
  //     default:
  //       print(message);
  //       break;
  //   }
  // }
  /////

  void _onIceCandidate(RTCIceCandidate iceCandidate, int peerID) {
    _socket.emit(
        'candidate',
        json.encode({
          'id': peerID,
          'fromID': _id,
          'candidate': ({
            'candidate': iceCandidate.candidate.toString(),
            'sdpMid': iceCandidate.sdpMid.toString(),
            'sdpMlineIndex': iceCandidate.sdpMLineIndex,
          })
        }));
    // _sendSignalingMessage({
    //   'type': 'candidate',
    //   'id': peerID,
    //   'fromID': _id,
    //   'candidate': json.encode({
    //     'candidate': iceCandidate.candidate.toString(),
    //     'sdpMid': iceCandidate.sdpMid.toString(),
    //     'sdpMlineIndex': iceCandidate.sdpMLineIndex,
    //   }),
    // });
  }

  // void _sendSignalingMessage(dynamic message) {
  //   _webSocketChannel.sink.add(json.encode(message));
  // }

  Future<void> _sendOffer(int id) async {
    print('Sending offer to id $id');
    // var connection = _remoteConnections[index].peerConnection;
    // RTCSessionDescription offer = await connection.createOffer({});
    // await connection.setLocalDescription(offer);
    RTCSessionDescription offer = await _remoteConnections[id]!.createOffer();
    // _socket.emit('offer', '''{
    //   "id": $id,
    //   "fromID": $_id,
    //   "sdp": "${offer.sdp}",
    // }''');
    _socket.emit(
        'offer',
        json.encode({
          'id': id,
          'fromID': _id,
          'sdp': offer.sdp,
        }));
    // _sendSignalingMessage({
    //   'type': 'offer',
    //   'id': id,
    //   'fromID': _id,
    //   'sdp': offer.sdp,
    // });
  }

  Future<void> _init() async {
    await _localVideoRenderer.initialize();
  }

  Future<void> _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      // 'video': false,
      'video': {
        // 'mandatory': {
        //   'minWidth': '640',
        //   'minHeight': '480',
        //   'minFrameRate': '30',
        // },
        'facingMode': 'user',
        'optional': [],
      }
    };

    MediaStream stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    _localVideoRenderer.srcObject = stream;
    _localStream = stream;
    setState(() {});
  }

  void _disposeConnection(RemoteConnection connection) {
    _remoteConnections.removeWhere((key, value) => value == connection);
  }

  void rebuild() {
    setState(() {});
  }

  @override
  void initState() {
    _init().then((value) {});
    // _connectToSignalingServer('ws://10.144.44.138:27415/');
    _connectToSignalingServer('ws://10.144.43.61:27415/');
    // _connectToSignalingServer('ws://localhost:27415/');
    // _connectToSignalingServer('ws://173.93.225.199:27415/');
    // _connectToSignalingServer('ws:${SocketHandler().uri.split(':')[1]}:27415');
    super.initState();
  }

  @override
  void dispose() async {
    await _localVideoRenderer.dispose();
    super.dispose();
  }

  SizedBox videoRenderers() => SizedBox(
        height: 400,
        child: Row(children: [
          Flexible(
            child: Container(
              // key: const Key('local'),
              margin: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
              decoration: const BoxDecoration(color: Colors.black),
              child: RTCVideoView(_localVideoRenderer),
            ),
          ),
          Flexible(
            child: Container(
              // key: const Key('remote'),
              margin: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
              decoration: const BoxDecoration(color: Colors.black),
              child: Builder(builder: (context) {
                List<RemoteConnection> connections = _remoteConnections.values.toList();
                return ListView.builder(
                  itemCount: connections.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      // key: const Key('local'),
                      margin: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
                      decoration: const BoxDecoration(color: Colors.black),
                      child: SizedBox(
                        height: 210,
                        child: RTCVideoView(connections[index].remoteRenderer),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Hopes and Dreams'),
        ),
        body: Column(
          children: [
            videoRenderers(),
            // Row(
            //   children: [
            //     Column(
            //       crossAxisAlignment: CrossAxisAlignment.center,
            //       children: [
            //         ElevatedButton(
            //           onPressed: _createOffer,
            //           child: const Text("Offer"),
            //         ),
            //         const SizedBox(
            //           height: 10,
            //         ),
            // ElevatedButton(
            //   onPressed: _createAnswer,
            //   child: const Text("Answer"),
            // ),
            // const SizedBox(
            //   height: 10,
            // ),
            // ElevatedButton(
            //   onPressed: _setRemoteDescription,
            //   child: const Text("Set Remote Description"),
            // ),
            // const SizedBox(
            //   height: 10,
            // ),
            // ElevatedButton(
            //   onPressed: _addCandidate,
            //   child: const Text("Set Candidate"),
            // ),
            // ],
            // )
            // ],
            // ),
          ],
        ));
  }
}
