import 'package:flutter/material.dart';
import '../models/podcast.dart';
import '../services/api_service.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'dart:math';
import 'dart:async';
import '../providers/settings_provider.dart';
import '../services/audio_service.dart';
import '../services/audio_player_interface.dart'
    show AudioPlayerState, FileAudioSource, UrlAudioSource;
import 'dart:io' show Platform;

enum SubtitleMode { both, chinese, english }

enum PlayMode {
  sequence, // 顺序播放
  loop, // 循环播放
  single, // 单曲循环
  random // 随机播放
}

enum DifficultyLevel { elementary, intermediate, advanced }

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
    Config(key),
  );
}

// 字幕缓存管理器
class SubtitleCacheManager {
  static const key = 'subtitleCache';
  static CacheManager instance = CacheManager(
    Config(key),
  );
}

class AudioProvider with ChangeNotifier {
  final AudioService _audioService;
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
  List<Podcast> get filteredPodcastList =>
      _filteredPodcastList.isEmpty ? _podcastList : _filteredPodcastList;

  PlayMode _playMode = PlayMode.sequence;
  PlayMode get playMode => _playMode;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  double _durationRatio = 1.0; // 时长修正比例
  Duration _originalDuration = Duration.zero; // 原始时长（从字幕获取）

  DifficultyLevel _currentDifficulty = DifficultyLevel.intermediate;
  DifficultyLevel get currentDifficulty => _currentDifficulty;

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
    AudioPlayerState? lastState;

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
            debugPrint(
                '异常进度值: $progress, position: $position, duration: $_duration');
          }
        }
      } catch (e, stack) {
        debugPrint('进度更新错误: $e');
        debugPrint('错误堆栈: $stack');
      }
    });

    // 时长更新监听
    _audioService.onDurationChanged.listen((duration) {
      if (duration != null) {
        _duration = duration;
        durationNotifier.value = duration;

        // 总是打印音频时长
        debugPrint('音频实际时长: ${_formatDuration(duration)}');

        // 如果有字幕时长，总是计算并打印比例
        if (_originalDuration.inMilliseconds > 0) {
          final ratio =
              _originalDuration.inMilliseconds / duration.inMilliseconds;
          debugPrint(
              '时长比例: $ratio (字幕: ${_formatDuration(_originalDuration)}, 音频: ${_formatDuration(duration)})');

          // 仅在 Windows 平台时应用比例
          if (_isWindowsPlatform()) {
            _durationRatio = ratio;
          }
        }
      }
    });

    // 播放状态监听
    _audioService.onPlayerStateChanged.listen((state) {
      // 如果状态没有变化，不处理
      if (state == lastState) return;
      lastState = state;

      debugPrint('收到播放器状态变化: $state');
      _playerState = state;

      switch (state) {
        case AudioPlayerState.playing:
          _isPlaying = true;
          isPlayingNotifier.value = true;
          debugPrint('更新为播放状态');
          break;
        case AudioPlayerState.paused:
          _isPlaying = false;
          isPlayingNotifier.value = false;
          debugPrint('更新为暂停状态');
          break;
        case AudioPlayerState.stopped:
        case AudioPlayerState.completed:
        case AudioPlayerState.none:
        case AudioPlayerState.loading:
        case AudioPlayerState.error:
          _isPlaying = false;
          isPlayingNotifier.value = false;
          debugPrint('更新为其他状态: $state');
          break;
      }
      notifyListeners();
    });

    // 播放完成监听
    _audioService.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _playerState = AudioPlayerState.completed;
      isPlayingNotifier.value = false;
      notifyListeners();
      onPlaybackCompleted();
      precacheNextEpisode();
    });
  }

  void _updateSubtitlesAtPosition(Duration position) {
    try {
      // 应用时长比例修正
      final adjustedPosition = Duration(
          milliseconds: (position.inMilliseconds * _durationRatio).round());
      final positionMs = adjustedPosition.inMilliseconds;

      for (var entry in _subtitleEntries) {
        final startMs = entry.start.inMilliseconds;
        final endMs = entry.end.inMilliseconds;

        if (positionMs >= startMs && positionMs <= endMs) {
          if (_currentChineseSubtitle != entry.chinese ||
              _currentEnglishSubtitle != entry.english) {
            debugPrint('找到匹配字幕 - 中文: ${entry.chinese}, 英文: ${entry.english}');
            _currentChineseSubtitle = entry.chinese;
            _currentEnglishSubtitle = entry.english;
            chineseSubtitleNotifier.value = entry.chinese;
            englishSubtitleNotifier.value = entry.english;
          }
          return;
        }
      }

      // 如果没有找到匹配的字幕，清空当前字幕
      if (_currentChineseSubtitle.isNotEmpty ||
          _currentEnglishSubtitle.isNotEmpty) {
        _currentChineseSubtitle = '';
        _currentEnglishSubtitle = '';
        chineseSubtitleNotifier.value = '';
        englishSubtitleNotifier.value = '';
      }
    } catch (e, stack) {
      debugPrint('更新字幕出错: $e');
      debugPrint('错误堆栈: $stack');
    }
  }

  List<SubtitleEntry> _parseSrtWithTimecode(String srtContent) {
    try {
      final entries = <SubtitleEntry>[];

      // 统一换行符
      final normalizedContent = srtContent.replaceAll('\r\n', '\n');
      final blocks = normalizedContent.split('\n\n');
      debugPrint('解析字幕块数量: ${blocks.length}');

      Duration lastEndTime = Duration.zero;

      for (var block in blocks) {
        if (block.trim().isEmpty) continue;

        final lines = block.split('\n');
        if (lines.length < 4) continue;

        final timeMatch =
            RegExp(r'(\d{2}:\d{2}:\d{2},\d{3}) --> (\d{2}:\d{2}:\d{2},\d{3})')
                .firstMatch(lines[1]);

        if (timeMatch != null) {
          final startTime = _parseTimeCode(timeMatch.group(1)!);
          final endTime = _parseTimeCode(timeMatch.group(2)!);

          // 更新最后的结束时间
          if (endTime > lastEndTime) {
            lastEndTime = endTime;
          }

          entries.add(SubtitleEntry(
            start: startTime,
            end: endTime,
            chinese: lines[2].trim(),
            english: lines[3].trim(),
          ));
        }
      }

      // 设置原始时长
      _originalDuration = lastEndTime;
      debugPrint('字幕原始时长: ${_formatDuration(_originalDuration)}');

      return entries;
    } catch (e, stackTrace) {
      debugPrint('解析字幕时间轴失败: $e');
      debugPrint('错误堆栈: $stackTrace');
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

  Future<void> playPodcast(int index, {bool autoPlay = true}) async {
    try {
      _miniPlayerVisible = true;
      miniPlayerVisibleNotifier.value = true;
      notifyListeners();

      _subtitleEntries = [];
      _currentChineseSubtitle = '';
      _currentEnglishSubtitle = '';
      chineseSubtitleNotifier.value = '';
      englishSubtitleNotifier.value = '';

      _currentIndex = index;
      _currentPodcast = _podcastList[index];
      final podcast = _podcastList[index];

      // 获取当前难度的字幕
      final subtitleUrl =
          podcast.files[_difficultyString]?[_currentLanguage]?['subtitle'];
      if (subtitleUrl != null) {
        try {
          final subtitleFile =
              await _subtitleCacheManager.getSingleFile(subtitleUrl);
          final bytes = await subtitleFile.readAsBytes();
          final subtitleContent = utf8.decode(bytes);
          _subtitleEntries = _parseSrtWithTimecode(subtitleContent);
          debugPrint('字幕加载成功，共 ${_subtitleEntries.length} 条字幕');
        } catch (e) {
          debugPrint('加载字幕失败: $e');
          _subtitleEntries = [];
        }
      }

      if (!autoPlay) {
        _miniPlayerVisible = true;
        notifyListeners();
        return;
      }

      // 获取当前难度的音频
      final url = podcast.files[_difficultyString]?[_currentLanguage]?['audio'];
      if (url != null) {
        try {
          await _audioService.stop();

          if (kIsWeb) {
            await _audioService.play(UrlAudioSource(url));
          } else {
            final audioFile = await _audioCacheManager.getSingleFile(url);
            await _audioService.play(FileAudioSource(audioFile.path));
          }

          await Future.delayed(const Duration(milliseconds: 500));

          if (_originalDuration.inMilliseconds > 0 &&
              _duration.inMilliseconds > 0) {
            final ratio =
                _originalDuration.inMilliseconds / _duration.inMilliseconds;
            debugPrint(
                '初始化时长比例: $ratio (字幕: ${_formatDuration(_originalDuration)}, 音频: ${_formatDuration(_duration)})');

            if (_isWindowsPlatform()) {
              _durationRatio = ratio;
            }
          }

          _miniPlayerVisible = true;
          notifyListeners();
        } catch (e, stack) {
          debugPrint('音频加载失败: $e');
          debugPrint('错误堆栈: $stack');
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('播放出错: $e');
      _playerState = AudioPlayerState.error;
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (_currentIndex < 0 || _currentPodcast == null) return;

    try {
      debugPrint('开始切换播放状态 - 当前状态: $_playerState, 是否播放: $_isPlaying');

      // 防止重复操作
      if (_playerState == AudioPlayerState.loading) {
        debugPrint('正在加载中，忽略操作');
        return;
      }

      // 使用本地变量保存当前状态，避免状态判断不一致
      final currentState = _playerState;

      debugPrint('当前实际状态 - playerState: $currentState');

      if (currentState == AudioPlayerState.playing) {
        debugPrint('准备暂停播放');
        await _audioService.pause();
      } else if (currentState == AudioPlayerState.paused) {
        debugPrint('准备继续播放');
        await _audioService.play();
      } else {
        // 如果是 stopped 或其他状态，需要重新加载并播放
        debugPrint('准备初始化播放');
        await playPodcast(_currentIndex, autoPlay: true);
      }
    } catch (e, stack) {
      debugPrint('播放控制出错: $e');
      debugPrint('错误堆栈: $stack');

      // 发生错误时恢复状态
      _isPlaying = false;
      isPlayingNotifier.value = false;
      _playerState = AudioPlayerState.error;
      notifyListeners();
    }
  }

  void updatePodcastList(List<Podcast> podcasts) {
    _podcastList = podcasts;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    try {
      // 直接使用原始位置，不需要���用比例
      final clampedPosition = Duration(
          milliseconds:
              position.inMilliseconds.clamp(0, _duration.inMilliseconds));
      await _audioService.seek(clampedPosition);
    } catch (e) {
      debugPrint('Seek failed: $e');
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
      throw Exception('创任务败: $e');
    }
  }

  Future<void> _loadPodcastList({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    try {
      _isLoading = true;
      scheduleMicrotask(() => notifyListeners());

      debugPrint('开始加载播客列表...');
      final podcasts = await _apiService.getPodcastList(
        status: 'completed',
        limit: 100,
      );

      debugPrint('获取到 ${podcasts.length} 个播客');

      _podcastList = podcasts;
      _filteredPodcastList = podcasts;
      _isLoading = false;
      notifyListeners();

      debugPrint('播客列表加载完成');
    } catch (e) {
      debugPrint('加载播客列表失败: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPodcastList() async {
    final currentPodcastId = _currentPodcast?.taskId;
    await _loadPodcastList(refresh: true);

    // 刷新后，找到当前播放的播客在新列表中的位置
    if (currentPodcastId != null) {
      final newIndex =
          _podcastList.indexWhere((p) => p.taskId == currentPodcastId);
      if (newIndex != -1) {
        _currentIndex = newIndex;
        _currentPodcast = _podcastList[newIndex];
        notifyListeners();
      }
    }
  }

  Future<void> toggleSpeed() async {
    const speeds = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    final currentIndex = speeds.indexOf(_playbackSpeed);
    final newSpeed = speeds[(currentIndex + 1) % speeds.length];
    await setSpeed(newSpeed); // 使用 setSpeed 方法来设置新的速度
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

  // 预缓存下一集和当前播客的其他难度
  Future<void> precacheNextEpisode() async {
    if (kIsWeb) return;

    // 1. 缓存当前播客的其他难度
    if (_currentPodcast != null) {
      // 遍历所有难度
      for (final difficulty in DifficultyLevel.values) {
        // 跳过当前难度
        if (difficulty == _currentDifficulty) continue;

        // 获取该难度的音频和字幕URL
        final audioUrl =
            _currentPodcast!.files[_getDifficultyString(difficulty)]
                ?[_currentLanguage]?['audio'];
        final subtitleUrl =
            _currentPodcast!.files[_getDifficultyString(difficulty)]
                ?[_currentLanguage]?['subtitle'];

        // 缓存音频
        if (audioUrl != null) {
          debugPrint(
              '缓存当前播客 ${_currentPodcast!.title} 的 ${_getDifficultyText(difficulty)} 难度音频');
          _audioCacheManager.downloadFile(audioUrl);
        }

        // 缓存字幕
        if (subtitleUrl != null) {
          debugPrint(
              '缓存当前播客 ${_currentPodcast!.title} 的 ${_getDifficultyText(difficulty)} 难度字幕');
          _subtitleCacheManager.downloadFile(subtitleUrl);
        }
      }
    }

    // 2. 缓存下一集
    if (_currentIndex < _podcastList.length - 1) {
      final nextPodcast = _podcastList[_currentIndex + 1];
      debugPrint('开始缓存下一集: ${nextPodcast.title}');

      // 缓存下一集当前难度的文件
      final audioUrl =
          nextPodcast.files[_difficultyString]?[_currentLanguage]?['audio'];
      if (audioUrl != null) {
        debugPrint('缓存下一集当前难度音频');
        _audioCacheManager.downloadFile(audioUrl);
      }

      final subtitleUrl =
          nextPodcast.files[_difficultyString]?[_currentLanguage]?['subtitle'];
      if (subtitleUrl != null) {
        debugPrint('缓存下一集当前难度字幕');
        _subtitleCacheManager.downloadFile(subtitleUrl);
      }
    }
  }

  // 根据难度获取对应的字符串
  String _getDifficultyString(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.elementary:
        return 'elementary';
      case DifficultyLevel.intermediate:
        return 'intermediate';
      case DifficultyLevel.advanced:
        return 'advanced';
    }
  }

  // 根据难度获取显示文本
  String _getDifficultyText(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.elementary:
        return '初级';
      case DifficultyLevel.intermediate:
        return '中级';
      case DifficultyLevel.advanced:
        return '高级';
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

      debugPrint('播放完成，当前模式: $_playMode');
      switch (_playMode) {
        case PlayMode.sequence:
          if (_currentIndex < filteredPodcastList.length - 1) {
            debugPrint('顺序播放：播放下一首');
            playNext();
          } else {
            debugPrint('顺序播放：已是最后一首');
          }
          break;
        case PlayMode.loop:
          if (_currentIndex < filteredPodcastList.length - 1) {
            debugPrint('循环播放：播放下一首');
            playNext();
          } else {
            _currentIndex = 0;
            debugPrint('循环播放：已是最后一首');
            playPodcast(0);
          }
          break;
        case PlayMode.single:
          debugPrint('单循环：播放当前曲目');
          playPodcast(_currentIndex);
          break;
        case PlayMode.random:
          if (filteredPodcastList.length <= 1) {
            // 如果只有一首歌，直接重播
            playPodcast(currentIndex);
          } else {
            // 如果有多首歌，确保选择一个不同的索引
            final random = Random();
            int nextIndex = currentIndex;
            // 直接生成一个不同的索引
            while (nextIndex == currentIndex) {
              nextIndex = random.nextInt(filteredPodcastList.length);
            }
            playPodcast(nextIndex);
          }
          break;
      }
    } catch (e, stack) {
      debugPrint('播放完成处理错误: $e');
      debugPrint('错误堆: $stack');
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

  // 添加一个辅助函数来检查是否是 Windows 平台
  bool _isWindowsPlatform() {
    try {
      if (kIsWeb) return false;
      return Platform.isWindows;
    } catch (e) {
      return false;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void onPlaybackCompleted() {
    switch (playMode) {
      case PlayMode.sequence:
        // 如果不是最后一首，播放下一首
        if (currentIndex < filteredPodcastList.length - 1) {
          playPodcast(currentIndex + 1);
        }
        break;

      case PlayMode.loop:
        // 如果是最后一首，回到第一首
        if (currentIndex >= filteredPodcastList.length - 1) {
          playPodcast(0);
        } else {
          playPodcast(currentIndex + 1);
        }
        break;

      case PlayMode.single:
        // 重新播放当前歌曲
        playPodcast(currentIndex);
        break;

      case PlayMode.random:
        // 随机选择一首（避免重复选中当前歌曲）
        final random = Random();
        int nextIndex;
        do {
          nextIndex = random.nextInt(filteredPodcastList.length);
        } while (nextIndex == currentIndex && filteredPodcastList.length > 1);
        playPodcast(nextIndex);
        break;
    }
  }

  Future<void> retryTask(String taskId) async {
    await _apiService.retryTask(taskId);
    await refreshPodcastList(); // 重试后刷新列表
  }

  void setCurrentPodcast(Podcast podcast, {bool autoPlay = true}) {
    _currentPodcast = podcast;
    _currentIndex = _podcastList.indexOf(podcast);
    _miniPlayerVisible = true;
    miniPlayerVisibleNotifier.value = true;

    if (autoPlay) {
      playPodcast(_currentIndex);
    }
    notifyListeners();
  }

  // 添加重置状态的方法
  void reset() {
    _podcastList = [];
    _filteredPodcastList = [];
    _currentIndex = -1;
    _currentPodcast = null;
    _playerState = AudioPlayerState.none;
    _isPlaying = false;
    _miniPlayerVisible = false;

    // 重置所有 ValueNotifier
    positionNotifier.value = Duration.zero;
    progressNotifier.value = 0.0;
    isPlayingNotifier.value = false;
    durationNotifier.value = Duration.zero;
    chineseSubtitleNotifier.value = '';
    englishSubtitleNotifier.value = '';
    miniPlayerVisibleNotifier.value = false;

    // 停止当前播放
    _audioService.stop();

    notifyListeners();
  }

  // 获取当前难度的字符串表示
  String get _difficultyString {
    switch (_currentDifficulty) {
      case DifficultyLevel.elementary:
        return 'elementary';
      case DifficultyLevel.intermediate:
        return 'intermediate';
      case DifficultyLevel.advanced:
        return 'advanced';
    }
  }

  // 添加切换难度的方法
  void toggleDifficulty() {
    switch (_currentDifficulty) {
      case DifficultyLevel.elementary:
        _currentDifficulty = DifficultyLevel.intermediate;
        break;
      case DifficultyLevel.intermediate:
        _currentDifficulty = DifficultyLevel.advanced;
        break;
      case DifficultyLevel.advanced:
        _currentDifficulty = DifficultyLevel.elementary;
        break;
    }

    if (_currentIndex >= 0) {
      playPodcast(_currentIndex);
    }
    notifyListeners();
  }

  // 获取当前难度的显示文本
  String get difficultyText {
    switch (_currentDifficulty) {
      case DifficultyLevel.elementary:
        return '初级';
      case DifficultyLevel.intermediate:
        return '中级';
      case DifficultyLevel.advanced:
        return '高级';
    }
  }

  List<SubtitleEntry> get subtitleEntries => _subtitleEntries;

  // 获取当前播放位置对应的字幕索引
  int getCurrentSubtitleIndex() {
    final adjustedPosition = Duration(
      milliseconds: (_position.inMilliseconds * _durationRatio).round(),
    );
    final positionMs = adjustedPosition.inMilliseconds;

    for (var i = 0; i < _subtitleEntries.length; i++) {
      final entry = _subtitleEntries[i];
      if (positionMs >= entry.start.inMilliseconds &&
          positionMs < entry.end.inMilliseconds) {
        return i;
      }
    }
    return -1;
  }

  // 跳转到指定字幕
  void seekToSubtitle(int index) {
    if (index >= 0 && index < _subtitleEntries.length) {
      final targetPosition = Duration(
        milliseconds:
            (_subtitleEntries[index].start.inMilliseconds / _durationRatio)
                .round(),
      );
      seek(targetPosition);
    }
  }
}
