import 'package:flutter/material.dart';
import 'package:touhourad/views/musicplayer/music_player_mobile.dart';

class MusicPlayer extends StatelessWidget {
  const MusicPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth <= 600) {
          return MusicPlayerMobile();
        } else if (constraints.maxWidth <= 1200) {
          return MusicPlayerMobile();
        } else {
          return MusicPlayerMobile();
        }
      },
    );
  }
}
