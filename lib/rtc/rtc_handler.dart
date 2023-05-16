// import 'dart:convert';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:web_socket_channel/io.dart';

// class RTCHandler {
//   static final _instance = RTCHandler._constructior();
//   factory RTCHandler() {
//     return _instance;
//   }
//   RTCHandler._constructior();

//   late MediaStream _localStream;
//   late MediaStream _remoteStream;
//   late RTCPeerConnection _peerConnection;
//   late IOWebSocketChannel _webSocketChannel;
//   // late RTCVideoRenderer _player;
//   late Function _buildParent;

//   void start(Function buildParent) async {
//     _buildParent = buildParent;

//     _connectToSignalingServer('ws://localhost:27415/');
//     await _createConnection();
//   }

//   Future<void> _createConnection() async {
//     Map<String, dynamic> configuration = {
//       'iceServers': [
//         {'url': 'stun:stun.l.google.com:19302'},
//       ]
//     };

//     _peerConnection = await createPeerConnection(configuration, {});

//     _localStream = await navigator.mediaDevices.getUserMedia({
//       'audio': true,
//       'video': false,
//     });
//     addLocalStream(_localStream);

//     _peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
//       // Send the ICE candidate to the other peer through a signaling server
//     };

//     // _peerConnection.onAddStream = (MediaStream stream) {
//     //   // Handle the remote stream here
//     //   stream.getTracks().forEach((audioTrack) {
//     //     _peerConnection.addTrack(audioTrack, stream);
//     //   });
//     // };

//     _peerConnection.onAddStream = (MediaStream stream) {
//       print("Add remote stream");
//       _buildParent.call(stream);
//       _remoteStream = stream;
//     };

//     _peerConnection.onTrack = (RTCTrackEvent event) {
//       print('Got remote track: ${event.streams[0]}');

//       event.streams[0].getTracks().forEach((track) {
//         print('Add a track to the remoteStream $track');
//         _remoteStream.addTrack(track);
//       });
//     };

//     //   _peerConnection.onTrack = (RTCTrackEvent event) async {
//     //     _remoteStream = await navigator.mediaDevices.getUserMedia({
//     //       'audio': true,
//     //       'video': false,
//     //     });
//     //     await _player.initialize();
//     //     event.streams[0].getTracks().forEach((element) {
//     //       _remoteStream.addTrack(element);
//     //     });
//     //     _player.srcObject = _remoteStream;
//     //     _buildParent.call();
//     //   };
//   }

//   Future<void> createOffer() async {
//     RTCSessionDescription description = await _peerConnection.createOffer({});
//     await _peerConnection.setLocalDescription(description);
//     _sendSignalingMessage({
//       'type': 'offer',
//       'sdp': description.sdp,
//     });
//   }

//   // Future<void> _setRemoteDescription(RTCSessionDescription description) async {
//   //   await _peerConnection.setRemoteDescription(description);
//   // }

//   void _connectToSignalingServer(String serverUri) {
//     _webSocketChannel = IOWebSocketChannel.connect(serverUri);
//     _webSocketChannel.stream.listen((message) {
//       _handleSignalingMessage(json.decode(message));
//     });
//   }

//   void addLocalStream(MediaStream stream) {
//     // Add the audio tracks from the stream to the peer connection
//     stream.getTracks().forEach((audioTrack) {
//       _peerConnection.addTrack(audioTrack, stream);
//     });
//   }

//   // Future<void> _addIceCandidate(RTCIceCandidate candidate) async {
//   //   await _peerConnection.addCandidate(candidate);
//   // }

//   void _sendSignalingMessage(dynamic message) {
//     _webSocketChannel.sink.add(json.encode(message));
//   }

//   // void _startAudio() async {
//   //   List<RTCRtpSender> senders = await _peerConnection.getSenders();
//   //   RTCRtpSender? audioSender = senders.firstWhere(
//   //     (sender) => sender.track != null && sender.track!.kind == 'audio',
//   //   );

//   //   // Replace the null track with the audio track
//   //   audioSender.replaceTrack(_localStream.getTracks()[0]);
//   // }

//   void _handleSignalingMessage(dynamic message) async {
//     String type = message['type'];

//     switch (type) {
//       case 'offer':
//         RTCSessionDescription offer = RTCSessionDescription(
//           message['sdp'],
//           'offer',
//         );
//         await _peerConnection.setRemoteDescription(offer);

//         RTCSessionDescription answer = await _peerConnection.createAnswer({});
//         await _peerConnection.setLocalDescription(answer);

//         _sendSignalingMessage({
//           'type': 'answer',
//           'sdp': answer.sdp,
//         });
//         break;

//       case 'answer':
//         RTCSessionDescription answer = RTCSessionDescription(
//           message['sdp'],
//           'answer',
//         );
//         await _peerConnection.setRemoteDescription(answer);
//         break;
//     }
//   }

//   void dispose() {
//     _localStream.dispose();
//     _peerConnection.dispose();
//     _webSocketChannel.sink.close();
//   }
// }
