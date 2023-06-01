// Copyright Terry Hancock 2023
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:neptune_fob/rtc/remote_connection.dart';
import 'package:neptune_fob/data/socket_handler.dart';
import 'package:socket_io_client/socket_io_client.dart';

class RTCHandler {
  static final RTCHandler _instance = RTCHandler._constructor();

  factory RTCHandler(Function buildParent) {
    return _instance._setBuildParent(buildParent);
  }

  RTCHandler._constructor();

  late Function _buildParent;
  RTCHandler _setBuildParent(Function buildParent) {
    _buildParent = buildParent;
    return _instance;
  }

  late Socket _socket;

  bool inCall = false;

  RTCVideoRenderer get localVideoRenderer => _localVideoRenderer;
  List<Map<int, RTCIceCandidate>> get iceCandidates => _iceCandidates;
  Map<int, RemoteConnection> get remoteConnections => _remoteConnections;

  final _localVideoRenderer = RTCVideoRenderer();

  final List<Map<int, RTCIceCandidate>> _iceCandidates = [];
  final Map<int, RemoteConnection> _remoteConnections = {};
  MediaStream? _localStream;

  int _id = -1;

  void enterCall() {
    _connectToSignalingServer(SocketHandler().uri);
  }

  void _connectToSignalingServer(String serverUri) async {
    await _localVideoRenderer.initialize();

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
    _socket.onConnect((data) {
      _socket.emit('vcClient');
      print('Socket Connected');
    });
    _socket.onError((data) => print(data));
    _socket.on('serverResponse', (responseJson) async {
      Map<String, dynamic> response = json.decode(responseJson);
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
        RemoteConnection rc =
            RemoteConnection(peerIDs[i], _localStream!, _buildParent, _onIceCandidate, _disposeConnection);
        await rc.init(_iceCandidates);
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
          RemoteConnection(offerMap['fromID'], _localStream!, _buildParent, _onIceCandidate, _disposeConnection);
      await rc.init(_iceCandidates);

      _remoteConnections.putIfAbsent(rc.id, () => rc);

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
        _iceCandidates.add({id: candidate});
        return;
      }
      rc.addIceCandidate(candidate);

      // await _peerConnection.addCandidate(candidate);
    });
  }

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

  Future<void> _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      // {
      //   'mandatory': {
      //     'OfferToReceiveAudio': true,
      //   },
      //   'optional': [
      //     {'autoGainControl': false},
      //     {'channelCount': 2},
      //     {'echoCancellation': false},
      //     {'latency': 0},
      //     {'noiseSuppression': false},
      //     {'sampleRate': 48000},
      //     {'sampleSize': 16},
      //     {'volume': 1.0}
      //     // {'audioCodec': 'iSAC'},
      //   ],
      // },
      'video': false,
      // 'video': {
      //   // 'mandatory': {
      //   //   'minWidth': '640',
      //   //   'minHeight': '480',
      //   //   'minFrameRate': '30',
      //   // },
      //   'facingMode': 'user',
      //   'optional': [],
      // }
    };

    MediaStream stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    _localVideoRenderer.srcObject = stream;
    _localStream = stream;
    _buildParent.call();
    // setState(() {});
  }

  void _disposeConnection(RemoteConnection connection) {
    _remoteConnections.removeWhere((key, value) => value == connection);
  }

  void leaveCall() {
    if (_socket.connected) {
      _socket.dispose();
    }
    _remoteConnections.forEach((id, remoteConnection) {
      remoteConnection.dispose();
    });
    _localVideoRenderer.srcObject = null;
  }
}
