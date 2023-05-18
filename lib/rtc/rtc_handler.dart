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

  late Socket socket;

  bool inCall = false;

  RTCVideoRenderer get localVideoRenderer => _localVideoRenderer;
  List<Map<int, RTCIceCandidate>> get iceCandidates => _iceCandidates;
  Map<int, RemoteConnection> get remoteConnections => _remoteConnections;

  final _localVideoRenderer = RTCVideoRenderer();

  final List<Map<int, RTCIceCandidate>> _iceCandidates = [];
  final Map<int, RemoteConnection> _remoteConnections = {};
  MediaStream? localStream;

  int id = -1;

  void enterCall() {
    // _connectToSignalingServer('ws://10.144.44.138:27415/');
    // _connectToSignalingServer('ws://10.144.43.61:27415/');
    // _connectToSignalingServer('ws://localhost:27415/');
    // _connectToSignalingServer('ws://173.93.225.199:27415/');
    _connectToSignalingServer('ws://${SocketHandler().uri.split(':')[1].replaceAll('/', '')}:27415/');
  }

  void _connectToSignalingServer(String serverUri) async {
    await localVideoRenderer.initialize();

    socket = io(
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

    socket.connect();
  }

  void _setSocketListeners() {
    socket.onConnect((data) => print('Socket Connected'));
    socket.onError((data) => print(data));
    socket.on('serverResponse', (responseJson) async {
      Map<String, dynamic> response = json.decode(responseJson);
      print('Client connected');
      await _getUserMedia();
      id = response['id'];
      print('This client\'s id = $id');
      List<int> peerIDs = response['ids'].cast<int>();
      if (peerIDs.isEmpty) {
        print('Client is alone');
        return;
      }
      for (int i = 0; i < peerIDs.length; i++) {
        RemoteConnection rc =
            RemoteConnection(peerIDs[i], localStream!, _buildParent, _onIceCandidate, _disposeConnection);
        await rc.init(iceCandidates);
        remoteConnections.putIfAbsent(peerIDs[i], () => rc);
        await _sendOffer(peerIDs[i]);
      }
    });
    socket.on('offer', (offerJson) async {
      Map<String, dynamic> offerMap = jsonDecode(offerJson);
      RTCSessionDescription offer = RTCSessionDescription(
        offerMap['sdp'],
        'offer',
      );

      final RemoteConnection rc =
          RemoteConnection(offerMap['fromID'], localStream!, _buildParent, _onIceCandidate, _disposeConnection);
      await rc.init(iceCandidates);

      print('before');
      remoteConnections.putIfAbsent(rc.id, () => rc);
      print('after');

      // await _peerConnection?.setRemoteDescription(offer);
      await rc.setRemoteDescription(offer);

      // RTCSessionDescription answer = await _peerConnection!.createAnswer({});
      // await _peerConnection?.setLocalDescription(answer);
      RTCSessionDescription answer = await rc.createAnswer();

      socket.emit(
          'answer',
          json.encode({
            'id': rc.id,
            'fromID': id,
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
    socket.on('answer', (answerJson) async {
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
      await remoteConnections[answerMap['fromID']]!.setRemoteDescription(answer);

      print('Answer recived from ${answerMap['fromID']}');
    });
    socket.on('candidate', (candidateJson) {
      Map<String, dynamic> candidateMap = jsonDecode(candidateJson);
      RTCIceCandidate candidate = RTCIceCandidate(
        candidateMap['candidate']['candidate'].toString(),
        candidateMap['candidate']['sdpMid'],
        candidateMap['candidate']['sdpMlineIndex'],
      );
      int id = candidateMap['fromID'];
      RemoteConnection? rc = remoteConnections[id];
      if (rc == null) {
        iceCandidates.add({id: candidate});
        return;
      }
      rc.addIceCandidate(candidate);

      // await _peerConnection.addCandidate(candidate);
    });
  }

  void _onIceCandidate(RTCIceCandidate iceCandidate, int peerID) {
    socket.emit(
        'candidate',
        json.encode({
          'id': peerID,
          'fromID': id,
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
    RTCSessionDescription offer = await remoteConnections[id]!.createOffer();
    // _socket.emit('offer', '''{
    //   "id": $id,
    //   "fromID": $_id,
    //   "sdp": "${offer.sdp}",
    // }''');
    socket.emit(
        'offer',
        json.encode({
          'id': id,
          'fromID': id,
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

    localVideoRenderer.srcObject = stream;
    localStream = stream;
    _buildParent.call();
    // setState(() {});
  }

  void _disposeConnection(RemoteConnection connection) {
    remoteConnections.removeWhere((key, value) => value == connection);
  }

  void leaveCall() {
    if (socket.connected) {
      socket.dispose();
    }
    remoteConnections.forEach((id, remoteConnection) {
      remoteConnection.dispose();
    });
    localVideoRenderer.srcObject = null;
  }
}
