import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  // 播放状态监听
  Stream<PlayerState> get playerStateStream => _player.onPlayerStateChanged;
  Stream<Duration> get positionStream => _player.onPositionChanged;
  Stream<Duration?> get durationStream => _player.onDurationChanged;
  
  // 使用 Stream 替代回调函数
  Stream<Duration> get onPositionChanged => _player.onPositionChanged;
  Stream<Duration?> get onDurationChanged => _player.onDurationChanged;
  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;
  Stream<void> get onPlayerComplete => _player.onPlayerComplete;

  AudioPlayerService() {
    // 移除 _setupListeners，因为我们直接使用 Stream
  }

  Future<void> setSource(Source source) async {
    await _player.setSource(source);
  }

  Future<void> setUrl(String url) async {
    await _player.setSource(UrlSource(url));
  }

  Future<void> play([String? url]) async {
    if (url != null) {
      await setUrl(url);
    }
    await _player.resume();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setSpeed(double speed) async {
    await _player.setPlaybackRate(speed);
  }

  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}
