import 'dart:collection';

import 'package:flutter_webrtc/flutter_webrtc.dart';

class RemoteConnection {
  final Function _rebuildParent;
  final int _peerID;
  final MediaStream _localStream;
  late final RTCPeerConnection? _peerConnection;
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final Function _onIceCandidate;
  final Function _disposeAlert;

  RemoteConnection(this._peerID, this._localStream, this._rebuildParent, this._onIceCandidate, this._disposeAlert);

  Future<void> init(List<Map<int, RTCIceCandidate>> iceCandidates) async {
    await _remoteRenderer.initialize();
    _peerConnection = await _createPeerConnecion(iceCandidates);
  }

  int get id => _peerID;
  RTCPeerConnection get peerConnection => _peerConnection!;
  RTCVideoRenderer get remoteRenderer => _remoteRenderer;

  Future<RTCPeerConnection> _createPeerConnecion(List<Map<int, RTCIceCandidate>> iceCandidates) async {
    Map<String, dynamic> configuration = {
      'iceServers': [
        {'url': 'stun:stun.l.google.com:19302'},
        // {"url": 'turn:turn.anyfirewall.com:443?transport=tcp', "credential": 'webrtc', "username": 'webrtc'}
        {"url": "stun:stun1.l.google.com:19302"},
        {"url": "stun:stun2.l.google.com:19302"},
        {"url": "stun:stun3.l.google.com:19302"},
        {"url": "stun:stun4.l.google.com:19302"},
        // {'url': 'turn:numb.viagenie.ca', 'credential': 'muazkh', 'username': 'webrtc@live.com'},
        // {
        //   'url': 'turn:192.158.29.39:3478?transport=udp',
        //   'credential': 'JZEOEt2V3Qb0y27GRntt2u2PAYA=',
        //   'username': '28224511:1379330808'
        // },
        // {
        //   'url': 'turn:192.158.29.39:3478?transport=tcp',
        //   'credential': 'JZEOEt2V3Qb0y27GRntt2u2PAYA=',
        //   'username': '28224511:1379330808'
        // },
        // {'url': 'turn:turn.bistri.com:80', 'credential': 'homeo', 'username': 'homeo'},
        // {'url': 'turn:turn.anyfirewall.com:443?transport=tcp', 'credential': 'webrtc', 'username': 'webrtc'}
      ]
    };

    // RTCPeerConnection pc = await createPeerConnection(configuration, offerSdpConstraints);
    RTCPeerConnection pc = await createPeerConnection(configuration);

    // pc.addStream(_localStream);
    _localStream.getTracks().forEach(
      (track) {
        pc.addTrack(track, _localStream);
        // setState(() {});
        _rebuildParent.call();
      },
    );

    pc.onIceCandidate = (RTCIceCandidate iceCandidate) async {
      if (iceCandidate.candidate != null) {
        _onIceCandidate(iceCandidate, _peerID);
        // _send({
        //   'type': 'candidate',
        //   'id': _peerID,
        //   'fromID': ,
        //   'candidate': json.encode({
        //     'candidate': iceCandidate.candidate.toString(),
        //     'sdpMid': iceCandidate.sdpMid.toString(),
        //     'sdpMlineIndex': iceCandidate.sdpMLineIndex,
        //   }),
        // });
        await _peerConnection!.addCandidate(iceCandidate);
        print('candidate');
      }
    };

    pc.onIceConnectionState = (connectionState) {
      // _iceState = e;
      print(connectionState);
      // print(_peerConnection!.iceGatheringState);
    };

    // _peerConnection!.onRenegotiationNeeded = () {
    // print('major L!');
    // };

    pc.onConnectionState = (connectionState) {
      print(connectionState);
    };

    pc.onAddStream = (stream) {
      print('addStream: ${stream.id}');
      _remoteRenderer.srcObject = stream;
      // setState(() {});
      _rebuildParent.call();
    };

    pc.onConnectionState = ((RTCPeerConnectionState connectionState) {
      if (connectionState == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          connectionState == RTCPeerConnectionState.RTCPeerConnectionStateClosed ||
          connectionState == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _dispose();
      }
    });

    // pc.onAddTrack = (stream, track) {
    //   print('Add track: ${track.id}');
    //   // pc.addTrack(track);
    //   // _remoteVideoRenderer.srcObject = stream;
    //   // setState(() {});
    // };

    if (iceCandidates.isNotEmpty) {
      for (int i = 0; i < iceCandidates.length; i++) {
        if (iceCandidates[i].keys.first == _peerID) {
          pc.addCandidate(iceCandidates[i].values.first);
          iceCandidates.removeAt(i);
          i--;
        }
      }
    }

    return pc;
  }

  void addIceCandidate(RTCIceCandidate iceCandidate) {
    _peerConnection!.addCandidate(iceCandidate);
  }

  Future<void> setRemoteDescription(RTCSessionDescription remoteDescription) async {
    await _peerConnection!.setRemoteDescription(remoteDescription);
  }

  Future<RTCSessionDescription> createOffer() async {
    final Map<String, dynamic> offerSdpConstraints = {
      "mandatory": {
        "OfferToReceiveAudio": true,
        "OfferToReceiveVideo": true,
      },
      "optional": [],
    };

    RTCSessionDescription offer = await _peerConnection!.createOffer(offerSdpConstraints);
    // print(offer.sdp);
    await _peerConnection!.setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription> createAnswer() async {
    RTCSessionDescription answer = await _peerConnection!.createAnswer({});
    await _peerConnection!.setLocalDescription(answer);
    return answer;
  }

  void _dispose() async {
    await _peerConnection!.dispose();
    _remoteRenderer.dispose();
    _disposeAlert.call(this);
    _rebuildParent.call();
  }
}
