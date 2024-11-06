import 'audio_player_interface.dart';
import 'just_audio_impl.dart';

class AudioService {
  final AudioPlayerInterface _player;
  
  AudioService() : _player = JustAudioImpl();
  
  Stream<AudioPlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<void> get onPlayerComplete => _player.onPlayerComplete;
  
  Stream<Duration> get onPositionChanged => _player.positionStream;
  Stream<Duration?> get onDurationChanged => _player.durationStream;
  Stream<AudioPlayerState> get onPlayerStateChanged => _player.playerStateStream;
  
  Future<void> play([AudioSource? source]) => _player.play(source);
  Future<void> pause() => _player.pause();
  Future<void> stop() => _player.stop();
  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);
  Future<void> setSource(dynamic source) => _player.setSource(source);
  
  void dispose() => _player.dispose();
}
