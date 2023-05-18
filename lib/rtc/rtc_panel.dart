// Copyright Terry Hancock 2023

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:neptune_fob/rtc/rtc_handler.dart';

class RTCPanel extends StatefulWidget {
  const RTCPanel({super.key});

  @override
  State<RTCPanel> createState() => _RTCPanelState();
}

class _RTCPanelState extends State<RTCPanel> {
  late final RTCHandler _rtcHandler = RTCHandler(_rebuild);
  // RTCIceConnectionState _iceState = RTCIceConnectionState.RTCIceConnectionStateNew;
  // late IOWebSocketChannel _webSocketChannel;

  void enterCall() {
    if (_rtcHandler.inCall) {
      return;
    }
    _rtcHandler.inCall = true;
    _rtcHandler.enterCall();
    setState(() {});
  }

  void leaveCall() {
    if (!_rtcHandler.inCall) {
      return;
    }
    _rtcHandler.leaveCall();
    _rtcHandler.inCall = false;
    setState(() {});
  }

  void _rebuild() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MaterialButton(
          onPressed: enterCall,
          color: _rtcHandler.inCall ? const Color(0x00000000) : const Color.fromARGB(255, 68, 99, 179),
          child: const Text('Join Call'),
        ),
        Flexible(
          child: RTCVideoView(
            _rtcHandler.localVideoRenderer,
            placeholderBuilder: (context) => const SizedBox(),
          ),
        ),
        SizedBox(
          height: 0,
          width: 0,
          child: ListView.builder(
            itemCount: _rtcHandler.remoteConnections.values.toList().length,
            itemBuilder: (BuildContext context, int index) {
              return RTCVideoView(
                _rtcHandler.remoteConnections.values.toList()[index].remoteRenderer,
                placeholderBuilder: (context) => const SizedBox(),
              );
            },
          ),
        ),
        MaterialButton(
          color: _rtcHandler.inCall ? const Color.fromARGB(255, 68, 99, 179) : const Color(0x00000000),
          onPressed: leaveCall,
          child: const Text('Leave Call'),
        ),
      ],
    );
  }
}
