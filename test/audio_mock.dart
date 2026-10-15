import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:itechs/glob/audio.dart';

final audioCalls = <MethodCall>[];

class TestAudioPlatform extends AudioplayersPlatformInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  final streams = <String, StreamController<AudioEvent>>{};
  @override
  Future<void> create(String playerId) async {
    streams[playerId] = StreamController<AudioEvent>.broadcast();
  }

  @override
  Stream<AudioEvent> getEventStream(String playerId) =>
      streams[playerId]!.stream;
  @override
  Future<void> setVolume(String playerId, double volume) async {
    audioCalls.add(
      MethodCall('setVolume', {'playerId': playerId, 'volume': volume}),
    );
  }

  @override
  Future<void> setReleaseMode(String playerId, ReleaseMode mode) async {}
  @override
  Future<void> setSourceUrl(
    String playerId,
    String url, {
    bool? isLocal,
    String? mimeType,
  }) async {
    audioCalls.add(MethodCall('setSourceUrl', {'url': url}));
    streams[playerId]!.add(
      const AudioEvent(eventType: AudioEventType.prepared, isPrepared: true),
    );
  }

  @override
  Future<void> resume(String playerId) async {}
  @override
  Future<void> stop(String playerId) async {}
  @override
  Future<int?> getDuration(String playerId) async => 0;
  @override
  Future<int?> getCurrentPosition(String playerId) async => 0;
}

class TestGlobalAudio extends GlobalAudioplayersPlatformInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<void> init() async {}
  @override
  Stream<GlobalAudioEvent> getGlobalEventStream() => const Stream.empty();
}

void mockAudio() {
  AudioplayersPlatformInterface.instance = TestAudioPlatform();
  GlobalAudioplayersPlatformInterface.instance = TestGlobalAudio();
  AppAudio.music = AudioPlayer();
  AppAudio.sound = AudioPlayer();
  for (final file in ['menu-music.mp3', 'student-click.mp3']) {
    AudioCache.instance.loadedFiles['audio/$file'] = File('assets/audio/$file')
        .absolute
        .uri;
  }
}
