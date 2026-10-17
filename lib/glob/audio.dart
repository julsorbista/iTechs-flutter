import 'package:audioplayers/audioplayers.dart';

import 'user.dart';

class AppAudio {
  static AudioPlayer music = AudioPlayer();
  static AudioPlayer sound = AudioPlayer();

  static Future<void> startMusic() async {
    music.positionUpdater = null;
    await music.setReleaseMode(ReleaseMode.loop);
    await music.play(
      AssetSource('audio/menu-music.mp3'),
      volume: AllUsers.musicVolume / 100,
    );
  }

  static void updateMusicVolume() {
    music.setVolume(AllUsers.musicVolume / 100);
  }

  static Future<void> click() async {
    if (AllUsers.sfxVolume == 0) return;
    sound.positionUpdater = null;
    await sound.stop();
    await sound
        .play(
          AssetSource('audio/student-click.mp3'),
          volume: 0.45 * AllUsers.sfxVolume / 100,
        )
        .catchError((Object _) {});
  }

  static void stop() {
    music.stop();
    sound.stop();
  }
}
