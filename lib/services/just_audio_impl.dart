import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:rxdart/rxdart.dart';
import 'audio_player_interface.dart';
import 'package:audio_session/audio_session.dart';

class JustAudioImpl implements AudioPlayerInterface {
  final just_audio.AudioPlayer _player = just_audio.AudioPlayer();
  
  JustAudioImpl() {
    _init();
  }
  
  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());
  }
  
  AudioPlayerState _convertPlayerState(just_audio.PlayerState state) {
    if (state.playing) {
      return AudioPlayerState.playing;
    }
    
    return switch (state.processingState) {
      just_audio.ProcessingState.idle => AudioPlayerState.stopped,
      just_audio.ProcessingState.loading => AudioPlayerState.loading,
      just_audio.ProcessingState.buffering => AudioPlayerState.loading,
      just_audio.ProcessingState.ready => AudioPlayerState.paused,
      just_audio.ProcessingState.completed => AudioPlayerState.completed,
    };
  }

  @override 
  Stream<AudioPlayerState> get playerStateStream => 
    _player.playerStateStream
        .map(_convertPlayerState)
        .startWith(AudioPlayerState.stopped);

  @override
  Stream<Duration> get positionStream => _player.positionStream;
  
  @override
  Stream<Duration?> get durationStream => _player.durationStream;
  
  @override
  Stream<void> get onPlayerComplete => 
      _player.processingStateStream
          .where((state) => state == just_audio.ProcessingState.completed)
          .map((_) => null);

  @override
  Future<void> play([AudioSource? source]) async {
    if (source != null) {
      await setSource(source);
    }
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  @override
  Future<void> setSource(AudioSource source) async {
    try {
      final justAudioSource = switch (source.type) {
        AudioSourceType.url => 
            just_audio.AudioSource.uri(Uri.parse(source.path)),
        AudioSourceType.file => 
            just_audio.AudioSource.uri(Uri.file(source.path)),
        AudioSourceType.asset => 
            just_audio.AudioSource.uri(Uri.parse('asset:///${source.path}')),
      };
      await _player.setAudioSource(justAudioSource);
    } catch (e) {
      print('Error setting audio source: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _player.dispose();
  }
}
