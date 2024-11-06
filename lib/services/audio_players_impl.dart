import 'package:audioplayers/audioplayers.dart';
import 'audio_player_interface.dart';

class AudioPlayersImpl implements AudioPlayerInterface {
  final AudioPlayer _player = AudioPlayer();
  
  @override
  Stream<AudioPlayerState> get playerStateStream => 
      _player.onPlayerStateChanged.map(_convertPlayerState);
      
  @override
  Stream<Duration> get positionStream => _player.onPositionChanged;
  
  @override
  Stream<Duration?> get durationStream => _player.onDurationChanged;
  
  @override
  Stream<void> get onPlayerComplete => _player.onPlayerComplete;

  @override
  Future<void> play([AudioSource? source]) async {
    if (source != null) {
      await setSource(source);
    }
    await _player.resume();
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
    await _player.setPlaybackRate(speed);
  }

  @override
  Future<void> setSource(AudioSource source) async {
    // 1. 先停止当前播放
    await _player.stop();
    
    // 2. 设置新的音频源
    final playerSource = switch (source.type) {
      AudioSourceType.url => UrlSource(source.path),
      AudioSourceType.file => DeviceFileSource(source.path),
      AudioSourceType.asset => AssetSource(source.path),
    };
    
    // 3. 设置新源
    await _player.setSource(playerSource);
  }

  @override
  void dispose() {
    _player.dispose();
  }

  AudioPlayerState _convertPlayerState(PlayerState state) {
    switch (state) {
      case PlayerState.playing:
        return AudioPlayerState.playing;
      case PlayerState.paused:
        return AudioPlayerState.paused;
      case PlayerState.stopped:
        return AudioPlayerState.stopped;
      case PlayerState.completed:
        return AudioPlayerState.completed;
      default:
        return AudioPlayerState.none;
    }
  }
}
