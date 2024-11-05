import 'package:flutter/material.dart';
import '../models/podcast.dart';
import '../services/audio_service.dart';
import '../services/api_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'dart:math';
import 'dart:async';
import '../providers/settings_provider.dart';

enum AudioPlayerState { none, loading, playing, paused, error }
enum SubtitleMode { both, chinese, english }
enum PlayMode {
  sequence,    // 顺序播放
  loop,        // 循环播放
  single,      // 单曲循环
  random       // 随机播放
}

// 添加字幕时间轴类型
class SubtitleEntry {
  final Duration start;
  final Duration end;
  final String chinese;
  final String english;

  SubtitleEntry({
    required this.start,
    required this.end,
    required this.chinese,
    required this.english,
  });
}

// 自定义音频缓存管理器
class AudioCacheManager {
  static const key = 'audioCache';
  static CacheManager instance = CacheManager(
    Config(
      key
    ),
  );
}

// 字幕缓存管理器
class SubtitleCacheManager {
  static const key = 'subtitleCache';
  static CacheManager instance = CacheManager(
    Config(
      key
    ),
  );
}

class AudioProvider with ChangeNotifier {
  final AudioPlayerService _audioService;
  final ApiService _apiService;
  final SettingsProvider _settingsProvider;
  final _audioCacheManager = AudioCacheManager.instance;
  final _subtitleCacheManager = SubtitleCacheManager.instance;
  List<Podcast> _podcastList = [];
  int _currentIndex = -1;
  AudioPlayerState _playerState = AudioPlayerState.none;
  String _currentLanguage = 'cn';
  SubtitleMode _subtitleMode = SubtitleMode.both;
  double _playbackSpeed = 1.0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _miniPlayerVisible = false;
  String? _currentTaskId;
  Podcast? _currentPodcast;
  bool _isPlaying = false;
  double _progress = 0.0;
  String _currentChineseSubtitle = '';
  String _currentEnglishSubtitle = '';
  List<SubtitleEntry> _subtitleEntries = [];
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<double> progressNotifier = ValueNotifier(0.0);
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);
  final ValueNotifier<Duration> durationNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<String> chineseSubtitleNotifier = ValueNotifier('');
  final ValueNotifier<String> englishSubtitleNotifier = ValueNotifier('');
  final ValueNotifier<double> playbackSpeedNotifier = ValueNotifier(1.0);
  final ValueNotifier<bool> miniPlayerVisibleNotifier = ValueNotifier(false);

  List<Podcast> _filteredPodcastList = [];
  List<Podcast> get filteredPodcastList => _filteredPodcastList.isEmpty ? _podcastList : _filteredPodcastList;

  PlayMode _playMode = PlayMode.sequence;
  PlayMode get playMode => _playMode;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AudioProvider(
    this._audioService, 
    this._apiService,
    this._settingsProvider,
  ) {
    // 使用 addPostFrameCallback 确保在构建完成后进行初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAudioServiceListeners();
      _loadPodcastList();
      
      // 监听服务器地址变化
      _settingsProvider.setOnBaseUrlChanged(() {
        stopPlayback();
        _podcastList = [];
        _filteredPodcastList = [];
        notifyListeners();
        _loadPodcastList();
      });
    });
  }

  // Getters
  List<Podcast> get podcastList => _podcastList;
  int get currentIndex => _currentIndex;
  AudioPlayerState get playerState => _playerState;
  String get currentLanguage => _currentLanguage;
  SubtitleMode get subtitleMode => _subtitleMode;
  double get playbackSpeed => _playbackSpeed;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get miniPlayerVisible => _miniPlayerVisible;
  Podcast? get currentPodcast => _currentPodcast;
  String? get currentTaskId => _currentTaskId;
  double get progress => _progress;
  bool get isPlaying => _isPlaying;
  String get currentChineseSubtitle => _currentChineseSubtitle;
  String get currentEnglishSubtitle => _currentEnglishSubtitle;

  void _setupAudioServiceListeners() {
    // 位置更新监听
    _audioService.onPositionChanged.listen((position) {
      try {
        _position = position;
        positionNotifier.value = position;
        
        _updateSubtitlesAtPosition(position);
        
        if (_duration.inMilliseconds > 0) {
          // 添加更严格的进度值检查和保护
          double progress = position.inMilliseconds / _duration.inMilliseconds;
          if (progress.isNaN || progress.isInfinite) {
            progress = 0.0;
          }
          progress = progress.clamp(0.0, 1.0);
          progressNotifier.value = progress;
          
          // 添加日志以便调试
          if (progress > 1.0) {
            print('异常进度值: $progress, position: $position, duration: $_duration');
          }
        }
      } catch (e, stack) {
        print('进度更新错误: $e');
        print('错误堆栈: $stack');
      }
    });

    // 时长更新监听
    _audioService.onDurationChanged.listen((duration) {
      if (duration != null) {
        _duration = duration;
        durationNotifier.value = duration;
      }
    });

    // 播放状态监听
    _audioService.onPlayerStateChanged.listen((state) {
      switch (state) {
        case PlayerState.playing:
          _isPlaying = true;
          _playerState = AudioPlayerState.playing;
          isPlayingNotifier.value = true;
          break;
        case PlayerState.paused:
          _isPlaying = false;
          _playerState = AudioPlayerState.paused;
          isPlayingNotifier.value = false;
          break;
        case PlayerState.stopped:
          _isPlaying = false;
          _playerState = AudioPlayerState.none;
          break;
        case PlayerState.completed:
          _isPlaying = false;
          _playerState = AudioPlayerState.none;
          break;
        default:
          _isPlaying = false;
          _playerState = AudioPlayerState.error;
      }
    });

    // 只在这里处理播放完成事件
    _audioService.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _playerState = AudioPlayerState.none;
      isPlayingNotifier.value = false;
      _onPlayComplete();
      precacheNextEpisode();
    });
  }

  void _updateSubtitlesAtPosition(Duration position) {
    final positionMs = position.inMilliseconds;
    
    for (var entry in _subtitleEntries) {
      final startMs = entry.start.inMilliseconds;
      final endMs = entry.end.inMilliseconds;
      
      if (positionMs >= startMs && positionMs <= endMs) {
        if (_currentChineseSubtitle != entry.chinese || 
            _currentEnglishSubtitle != entry.english) {
          _currentChineseSubtitle = entry.chinese;
          _currentEnglishSubtitle = entry.english;
          chineseSubtitleNotifier.value = entry.chinese;
          englishSubtitleNotifier.value = entry.english;
          print('字幕已更新');
        }
        return;
      }
    }
    
    if (_currentChineseSubtitle.isNotEmpty || _currentEnglishSubtitle.isNotEmpty) {
      _currentChineseSubtitle = '';
      _currentEnglishSubtitle = '';
      chineseSubtitleNotifier.value = '';
      englishSubtitleNotifier.value = '';
      print('字幕已清空');
    }
  }

  List<SubtitleEntry> _parseSrtWithTimecode(String srtContent) {
    try {
      final entries = <SubtitleEntry>[];
      
      // 统一换行符
      final normalizedContent = srtContent.replaceAll('\r\n', '\n');
      final blocks = normalizedContent.split('\n\n');
      print('解析字幕块数量: ${blocks.length}');
      
      for (var block in blocks) {
        if (block.trim().isEmpty) continue;
        
        final lines = block.split('\n');
        if (lines.length < 4) continue;  // 至少需要4：号、时间码中文、英文
        
        // 解析时间码
        final timeMatch = RegExp(r'(\d{2}:\d{2}:\d{2},\d{3}) --> (\d{2}:\d{2}:\d{2},\d{3})')
            .firstMatch(lines[1]);
        
        if (timeMatch != null) {
          final startTime = _parseTimeCode(timeMatch.group(1)!);
          final endTime = _parseTimeCode(timeMatch.group(2)!);
          
          // 第三行是中文，第四行是英文
          final chinese = lines[2].trim();
          final english = lines[3].trim();
          
          entries.add(SubtitleEntry(
            start: startTime,
            end: endTime,
            chinese: chinese,
            english: english,
          ));
        }
      }
      
      print('成功解析字幕条目数: ${entries.length}');
      return entries;
    } catch (e, stackTrace) {
      print('解析字幕时间轴失败: $e');
      print('错误堆栈: $stackTrace');
      return [];
    }
  }

  Duration _parseTimeCode(String timeCode) {
    final parts = timeCode.split(':');
    final seconds = parts[2].split(',');
    return Duration(
      hours: int.parse(parts[0]),
      minutes: int.parse(parts[1]),
      seconds: int.parse(seconds[0]),
      milliseconds: int.parse(seconds[1]),
    );
  }

  Future<void> playPodcast(int index) async {
    try {
      // 1. 先清空当前字幕
      _subtitleEntries = [];
      _currentChineseSubtitle = '';
      _currentEnglishSubtitle = '';
      chineseSubtitleNotifier.value = '';
      englishSubtitleNotifier.value = '';
      
      _currentIndex = index;
      _currentPodcast = _podcastList[index];
      final podcast = _podcastList[index];
      
      // 2. 确保字幕完全加载后再播放音频
      final subtitleUrl = _currentLanguage == 'en' ? podcast.subtitleUrlEn : podcast.subtitleUrlCn;
      if (subtitleUrl != null) {
        try {
          final subtitleFile = await _subtitleCacheManager.getSingleFile(subtitleUrl);
          final bytes = await subtitleFile.readAsBytes();
          final subtitleContent = utf8.decode(bytes);
          _subtitleEntries = _parseSrtWithTimecode(subtitleContent);
          print('字幕加载成功，共 ${_subtitleEntries.length} 条字幕');
        } catch (e) {
          print('加载字幕失败: $e');
          // 字幕加载失败时清空字幕数据
          _subtitleEntries = [];
        }
      }
      
      // 3. 加载音频
      final url = _currentLanguage == 'en' ? podcast.audioUrlEn : podcast.audioUrlCn;
      if (url != null) {
        try {
          // 4. 先停止当前播放
          await _audioService.stop();
          
          if (kIsWeb) {
            await _audioService.setSource(UrlSource(url));
          } else {
            final audioFile = await _audioCacheManager.getSingleFile(url);
            await _audioService.setSource(DeviceFileSource(audioFile.path));
          }
          
          await Future.delayed(Duration(milliseconds: 300));
          await _audioService.play();
          _miniPlayerVisible = true;
          notifyListeners();
        } catch (e, stack) {
          print('音频加载失败: $e');
          print('错误堆栈: $stack');
          rethrow;
        }
      }
    } catch (e) {
      print('播放出错: $e');
      _playerState = AudioPlayerState.error;
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (_currentIndex < 0) return;
    
    try {
      if (_isPlaying) {
        await _audioService.pause();
      } else {
        await _audioService.play();  // 不传 URL，直接继续播放
      }
    } catch (e) {
      print('播放控制出错: $e');
    }
  }

  void updatePodcastList(List<Podcast> podcasts) {
    _podcastList = podcasts;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    try {
      final clampedPosition = Duration(
        milliseconds: position.inMilliseconds.clamp(0, _duration.inMilliseconds)
      );
      await _audioService.seek(clampedPosition);
    } catch (e) {
      print('Seek failed: $e');
    }
  }

  Future<void> setSpeed(double speed) async {
    _playbackSpeed = speed;
    playbackSpeedNotifier.value = speed;
    await _audioService.setSpeed(speed);
    notifyListeners();
  }

  void toggleLanguage() {
    _currentLanguage = _currentLanguage == 'en' ? 'cn' : 'en';
    if (_currentIndex >= 0) {
      playPodcast(_currentIndex);
    }
    notifyListeners();
  }

  void toggleSubtitleMode() {
    switch (_subtitleMode) {
      case SubtitleMode.both:
        _subtitleMode = SubtitleMode.chinese;
        break;
      case SubtitleMode.chinese:
        _subtitleMode = SubtitleMode.english;
        break;
      case SubtitleMode.english:
        _subtitleMode = SubtitleMode.both;
        break;
    }
    notifyListeners();
  }

  void toggleMiniPlayer() {
    _miniPlayerVisible = !_miniPlayerVisible;
    miniPlayerVisibleNotifier.value = _miniPlayerVisible;
  }

  Future<void> createPodcastTask(String url) async {
    try {
      final taskId = await _apiService.createPodcastTask(url);
      _currentTaskId = taskId;
      notifyListeners();
      
      await _apiService.pollTaskStatus(
        taskId,
        onProgress: (task) {
          notifyListeners();
        },
        onComplete: () async {
          await refreshPodcastList();
          _currentTaskId = null;
          notifyListeners();
        },
        onError: (error) {
          _currentTaskId = null;
          notifyListeners();
          throw Exception(error);
        },
      );
    } catch (e) {
      _currentTaskId = null;
      notifyListeners();
      throw Exception('创建任务失败: $e');
    }
  }

  Future<void> _loadPodcastList() async {
    if (_isLoading) return; // 防止重复加载
    
    try {
      _isLoading = true;
      // 使用 scheduleMicrotask 延迟第一次通知
      scheduleMicrotask(() => notifyListeners());
      
      final podcasts = await _apiService.getPodcastList();
      
      // 使用 scheduleMicrotask 包装所有状态更新
      scheduleMicrotask(() {
        _podcastList = podcasts;
        _filteredPodcastList = podcasts;
        _isLoading = false;
        notifyListeners();
      });
      
    } catch (e) {
      print('加载播客列表失败: $e');
      scheduleMicrotask(() {
        _isLoading = false;
        notifyListeners();
      });
    }
  }

  Future<void> refreshPodcastList() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final newList = await _apiService.getPodcastList();
      _podcastList = newList;
      _filteredPodcastList = newList;
      
    } catch (e) {
      print('刷新播客列表失败: $e');
      // rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleSpeed() async {
    const speeds = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    final currentIndex = speeds.indexOf(_playbackSpeed);
    final newSpeed = speeds[(currentIndex + 1) % speeds.length];
    await setSpeed(newSpeed);  // 使用 setSpeed 方法来设置新的速度
  }

  Future<void> playPrevious() async {
    if (_currentIndex > 0) {
      await playPodcast(_currentIndex - 1);
    }
  }

  Future<void> playNext() async {
    if (_currentIndex < _podcastList.length - 1) {
      await playPodcast(_currentIndex + 1);
    }
  }

  void updateSubtitles(String chinese, String english) {
    _currentChineseSubtitle = chinese;
    _currentEnglishSubtitle = english;
    notifyListeners();
  }

  // 添加缓存管理方法
  Future<void> clearCache() async {
    await _audioCacheManager.emptyCache();
    await _subtitleCacheManager.emptyCache();
    notifyListeners();
  }

  Future<int> getCacheSize() async {
    int totalSize = 0;
    
    // 获取音频存文件
    final audioFiles = await _audioCacheManager.store.getCacheSize();
    totalSize += audioFiles;
    
    // 获取字幕缓存文件
    final subtitleFiles = await _subtitleCacheManager.store.getCacheSize();
    totalSize += subtitleFiles;
    
    return totalSize;
  }

  // 预缓存下一集
  Future<void> precacheNextEpisode() async {
    if (kIsWeb) return; // Web平台不进行预缓存
    
    if (_currentIndex < _podcastList.length - 1) {
      final nextPodcast = _podcastList[_currentIndex + 1];
      final audioUrl = _currentLanguage == 'en' ? 
          nextPodcast.audioUrlEn : nextPodcast.audioUrlCn;
      
      if (audioUrl != null) {
        _audioCacheManager.downloadFile(audioUrl);
      }
      
      final subtitleUrl = _currentLanguage == 'en' ? 
          nextPodcast.subtitleUrlEn : nextPodcast.subtitleUrlCn;
      
      if (subtitleUrl != null) {
        _subtitleCacheManager.downloadFile(subtitleUrl);
      }
    }
  }

  void searchPodcasts(String query) {
    if (query.isEmpty) {
      _filteredPodcastList = podcastList;
    } else {
      _filteredPodcastList = podcastList
          .where((podcast) => 
              podcast.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  Future<void> stopPlayback() async {
    await _audioService.stop();
    _isPlaying = false;
    _playerState = AudioPlayerState.none;
    isPlayingNotifier.value = false;
    _miniPlayerVisible = false;
    miniPlayerVisibleNotifier.value = false;
    notifyListeners();
  }

  Future<void> deletePodcast(String taskId) async {
    try {
      await _apiService.deletePodcast(taskId);
      await refreshPodcastList();
    } catch (e) {
      debugPrint('删除播客失败: $e');
      rethrow;
    }
  }

  void togglePlayMode() {
    switch (_playMode) {
      case PlayMode.sequence:
        _playMode = PlayMode.loop;
        break;
      case PlayMode.loop:
        _playMode = PlayMode.single;
        break;
      case PlayMode.single:
        _playMode = PlayMode.random;
        break;
      case PlayMode.random:
        _playMode = PlayMode.sequence;
        break;
    }
    notifyListeners();
  }

  void _onPlayComplete() {
    try {
      // 重置进度值
      progressNotifier.value = 0.0;
      
      print('播放完成，当前模式: $_playMode');
      switch (_playMode) {
        case PlayMode.sequence:
          if (_currentIndex < filteredPodcastList.length - 1) {
            print('顺序播放：播放下一首');
            playNext();
          } else {
            print('顺序播放：已是最后一首');
          }
          break;
        case PlayMode.loop:
          if (_currentIndex < filteredPodcastList.length - 1) {
            print('循环播放：播放下一首');
            playNext();
          } else {
            _currentIndex = 0;
            print('循环播放：已是最后一首');
            playPodcast(0);
          }
          break;
        case PlayMode.single:
          print('单循环：播放当前曲目');
          playPodcast(_currentIndex);
          break;
        case PlayMode.random:
          final random = Random();
          final nextIndex = random.nextInt(filteredPodcastList.length);
          print('随机播放：播放下一首');
          playPodcast(nextIndex);
          break;
      }
    } catch (e, stack) {
      print('播放完成处理错误: $e');
      print('错误堆: $stack');
    }
  }

  @override
  void dispose() {
    positionNotifier.dispose();
    progressNotifier.dispose();
    isPlayingNotifier.dispose();
    durationNotifier.dispose();
    chineseSubtitleNotifier.dispose();
    englishSubtitleNotifier.dispose();
    playbackSpeedNotifier.dispose();
    miniPlayerVisibleNotifier.dispose();
    _audioService.dispose();
    super.dispose();
  }
} 