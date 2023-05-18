// Copyright Terry Hancock 2023

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:neptune_fob/data/socket_handler.dart';
import 'package:neptune_fob/rtc/remote_connection.dart';
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
    List<RemoteConnection> remoteHandlers = _rtcHandler.remoteConnections.values.toList();
    List<Widget> list = [];
    remoteHandlers.forEach((remoteHandler) {
      list.add(Stack(
        children: [
          Center(child: Text(remoteHandler.id.toString())),
          SizedBox(
            height: 0,
            width: 0,
            child: RTCVideoView(
              remoteHandler.remoteRenderer,
              placeholderBuilder: (context) => const SizedBox(),
            ),
          ),
        ],
      ));
    });
    if (_rtcHandler.inCall) {
      list.add(Text(SocketHandler().userName));
    }

    return Column(
      children: [
        MaterialButton(
          onPressed: _rtcHandler.inCall ? null : enterCall,
          disabledColor: const Color(0x00000000),
          color: const Color.fromARGB(255, 68, 99, 179),
          child: const Text('Join Call'),
        ),
        SizedBox(
          height: 0,
          width: 0,
          child: RTCVideoView(
            _rtcHandler.localVideoRenderer,
            placeholderBuilder: (context) => const SizedBox(),
          ),
        ),
        SizedBox(
          height: (remoteHandlers.length + (_rtcHandler.inCall ? 1 : 0)) * 20,
          child: Column(
            children: list,
          ),
        ),
        // SizedBox(
        //   height: (remoteHandlers.length + (_rtcHandler.inCall ? 1 : 0)) * 15,
        //   child: ListView.builder(
        //     itemCount: remoteHandlers.length + (_rtcHandler.inCall ? 1 : 0),
        //     itemBuilder: (BuildContext context, int index) {
        //       return index == remoteHandlers.length
        //           ? Center(child: Text(SocketHandler().userName))
        //           : SizedBox(
        //               height: 15,
        //               width: 30,
        //               child: Stack(
        //                 children: [
        //                   Center(child: Text(remoteHandlers[index].id.toString())),
        //                   RTCVideoView(
        //                     remoteHandlers[index].remoteRenderer,
        //                     placeholderBuilder: (context) => const SizedBox(),
        //                   ),
        //                 ],
        //               ),
        //             );
        //     },
        //   ),
        // ),
        MaterialButton(
          disabledColor: const Color(0x00000000),
          color: const Color.fromARGB(255, 68, 99, 179),
          onPressed: _rtcHandler.inCall ? leaveCall : null,
          child: const Text('Leave Call'),
        ),
      ],
    );
  }
}
