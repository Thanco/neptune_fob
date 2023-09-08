// Copyright Terry Hancock 2023

import 'package:audioplayers/audioplayers.dart';
import 'package:neptune_fob/data/chat_handler.dart';

class SoundHandler {
  static final AudioPlayer audio = AudioPlayer();

  static void play() {
    audio.play(
      ChatHandler().notificationSound ?? AssetSource('message.mp3'),
      volume: .25,
      mode: PlayerMode.lowLatency,
    );
  }
}
