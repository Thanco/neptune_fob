// Copyright Terry Hancock 2023
import 'package:flutter/material.dart';
import 'package:neptune_fob/rtc/rtc_panel.dart';
import 'package:neptune_fob/ui/server_list.dart';
import 'package:neptune_fob/data/text_style_handler.dart';
import 'package:provider/provider.dart';

class ServerPanel extends StatelessWidget {
  const ServerPanel(this._rtcPanel, {super.key});
  final RTCPanel _rtcPanel;

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const RoundedRectangleBorder(
        side: BorderSide(
          color: Color.fromARGB(255, 68, 99, 179),
          width: 5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Consumer<TextStyleHandler>(
              builder: (context, textStyleHandler, child) {
                return Text(
                  'Server Name? IDK',
                  style: TextStyle(
                    fontFamily: textStyleHandler.font,
                    fontSize: textStyleHandler.fontSize * 0.73,
                    decoration: TextDecoration.underline,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
            const Flexible(
              flex: 6,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: ServerList(),
              ),
            ),
            Flexible(
              flex: 1,
              child: Center(
                child: _rtcPanel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
