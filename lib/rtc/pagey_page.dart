import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/io.dart';

enum CallStatus { calling, accepted, ringing }

class PageyPage extends StatelessWidget {
  const PageyPage({super.key});

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
  late RTCIceConnectionState _iceState = RTCIceConnectionState.RTCIceConnectionStateNew;
  late IOWebSocketChannel _webSocketChannel;
  void _connectToSignalingServer(String serverUri) {
    _webSocketChannel = IOWebSocketChannel.connect(serverUri);
    _webSocketChannel.stream.listen((message) async {
      await _handleSignalingMessage(json.decode(message));
    });
  }

  Future<void> _handleSignalingMessage(dynamic message) async {
    String type = message['type'];

    switch (type) {
      case 'offer':
        RTCSessionDescription offer = RTCSessionDescription(
          message['sdp'],
          'offer',
        );
        await _peerConnection?.setRemoteDescription(offer);

        RTCSessionDescription answer = await _peerConnection!.createAnswer({});
        await _peerConnection?.setLocalDescription(answer);

        _sendSignalingMessage({
          'type': 'answer',
          'sdp': answer.sdp,
        });
        break;

      case 'answer':
        if (_iceState == RTCIceConnectionState.RTCIceConnectionStateCompleted ||
            _iceState == RTCIceConnectionState.RTCIceConnectionStateConnected) {
          break;
        }

        RTCSessionDescription answer = RTCSessionDescription(
          message['sdp'],
          'answer',
        );

        await _peerConnection?.setRemoteDescription(answer);
        break;
    }
  }

  void _sendSignalingMessage(dynamic message) {
    _webSocketChannel.sink.add(json.encode(message));
  }

  Future<void> _createOffer() async {
    RTCSessionDescription offer = await _peerConnection!.createOffer({});
    await _peerConnection!.setLocalDescription(offer);
    _sendSignalingMessage({
      'type': 'offer',
      'sdp': offer.sdp,
    });
  }

  final _localVideoRenderer = RTCVideoRenderer();
  final _remoteVideoRenderer = RTCVideoRenderer();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  initRenderer() async {
    await _localVideoRenderer.initialize();
    await _remoteVideoRenderer.initialize();
  }

  _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': false,
    };

    MediaStream stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    _localVideoRenderer.srcObject = stream;
    return stream;
  }

  Future<RTCPeerConnection> _createPeerConnecion() async {
    Map<String, dynamic> configuration = {
      "iceServers": [
        {"url": "stun:stun.l.google.com:19302"},
      ]
    };

    final Map<String, dynamic> offerSdpConstraints = {
      "mandatory": {
        "OfferToReceiveAudio": true,
        "OfferToReceiveVideo": true,
      },
      "optional": [],
    };

    _localStream = await _getUserMedia();

    RTCPeerConnection pc = await createPeerConnection(configuration, offerSdpConstraints);

    // pc.addStream(_localStream!);
    _localStream!.getTracks().forEach(
      (track) {
        pc.addTrack(track, _localStream!);
        setState(() {});
      },
    );

    pc.onIceCandidate = (e) {
      if (e.candidate != null) {
        print(json.encode({
          'candidate': e.candidate.toString(),
          'sdpMid': e.sdpMid.toString(),
          'sdpMlineIndex': e.sdpMLineIndex,
        }));
      }
    };

    pc.onIceConnectionState = (e) {
      _iceState = e;
      print(e);
    };

    pc.onAddStream = (stream) {
      print('addStream: ' + stream.id);
      _remoteVideoRenderer.srcObject = stream;
      setState(() {});
    };

    // pc.onAddTrack = (stream, track) {
    //   print('Add track: ${track.id}');
    //   // pc.addTrack(track);
    //   // _remoteVideoRenderer.srcObject = stream;
    //   // setState(() {});
    // };

    return pc;
  }

  // void _createOffer() async {
  //   RTCSessionDescription description = await _peerConnection!.createOffer({});

  //   print('offer created');
  //   _offer = true;

  //   _peerConnection!.setLocalDescription(description);
  // }

  // void _createAnswer() async {
  //   RTCSessionDescription description = await _peerConnection!.createAnswer({});

  //   print('answer created');

  //   _peerConnection!.setLocalDescription(description);
  // }

  // void _setRemoteDescription() async {
  //   String jsonString = sdpController.text;
  //   dynamic session = await jsonDecode(jsonString);

  //   // String sdp = write(session, null);

  //   RTCSessionDescription description = RTCSessionDescription(session['sdp'], _offer ? 'answer' : 'offer');
  //   print(description.toMap());

  //   await _peerConnection!.setRemoteDescription(description);
  // }

  // void _addCandidate() async {
  //   String jsonString = sdpController.text;
  //   dynamic session = await jsonDecode(jsonString);
  //   print(session['candidate']);
  //   dynamic candidate = RTCIceCandidate(session['candidate'], session['sdpMid'], session['sdpMlineIndex']);
  //   await _peerConnection!.addCandidate(candidate);
  // }

  @override
  void initState() {
    _connectToSignalingServer('ws://10.144.43.61:27415/');
    initRenderer();
    _createPeerConnecion().then((pc) {
      _peerConnection = pc;
    });
    // _getUserMedia();
    super.initState();
  }

  @override
  void dispose() async {
    await _localVideoRenderer.dispose();
    super.dispose();
  }

  SizedBox videoRenderers() => SizedBox(
        height: 210,
        child: Row(children: [
          Flexible(
            child: Container(
              key: const Key('local'),
              margin: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
              decoration: const BoxDecoration(color: Colors.black),
              child: RTCVideoView(_localVideoRenderer),
            ),
          ),
          Flexible(
            child: Container(
              key: const Key('remote'),
              margin: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
              decoration: const BoxDecoration(color: Colors.black),
              child: RTCVideoView(_remoteVideoRenderer),
            ),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Hopes and Dreams'),
        ),
        body: Column(
          children: [
            videoRenderers(),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _createOffer,
                      child: const Text("Offer"),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
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
                  ],
                )
              ],
            ),
          ],
        ));
  }
}
