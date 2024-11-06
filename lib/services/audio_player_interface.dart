import 'package:flutter/foundation.dart';

enum AudioPlayerState {
  none,
  loading,
  playing,
  paused,
  stopped,
  completed,
  error
}

// 定义音频源类型
enum AudioSourceType {
  url,
  file,
  asset
}

// 音频源抽象类
abstract class AudioSource {
  final AudioSourceType type;
  final String path;
  
  const AudioSource({
    required this.type,
    required this.path,
  });
}

// 具体音频源实现
class UrlAudioSource extends AudioSource {
  const UrlAudioSource(String url) : super(type: AudioSourceType.url, path: url);
}

class FileAudioSource extends AudioSource {
  const FileAudioSource(String filePath) : super(type: AudioSourceType.file, path: filePath);
}

class AssetAudioSource extends AudioSource {
  const AssetAudioSource(String assetPath) : super(type: AudioSourceType.asset, path: assetPath);
}

abstract class AudioPlayerInterface {
  // 基本控制
  Future<void> play([AudioSource? source]);
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setSpeed(double speed);
  Future<void> setSource(AudioSource source);
  
  // 状态流
  Stream<AudioPlayerState> get playerStateStream;
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<void> get onPlayerComplete;
  
  // 资源释放
  void dispose();
} 