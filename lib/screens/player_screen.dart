import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/playlist_bottom_sheet.dart';

class PlayerScreen extends StatelessWidget {
  final VoidCallback onClose;

  const PlayerScreen({super.key, required this.onClose});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  String _getSubtitleModeText(SubtitleMode mode) {
    switch (mode) {
      case SubtitleMode.both:
        return '中英文';
      case SubtitleMode.chinese:
        return '仅中文';
      case SubtitleMode.english:
        return '仅英文';
    }
  }

  void _showPlaylist(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const PlaylistBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: true);
    final currentPodcast = audioProvider.currentPodcast;

    return Material(
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // 顶部栏 - 只保留返回按钮
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down),
                      onPressed: onClose,
                    ),
                  ],
                ),
              ),
              
              // 标题
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  currentPodcast?.title ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 32),  // 增加间距

              // 字幕区域
              Expanded(
                child: Center(  // 添加 Center
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,  // 增加水平内边距
                        vertical: 32.0,    // 添加垂直内边距
                      ),
                      child: ValueListenableBuilder<String>(
                        valueListenable: audioProvider.chineseSubtitleNotifier,
                        builder: (context, chineseSubtitle, child) {
                          return ValueListenableBuilder<String>(
                            valueListenable: audioProvider.englishSubtitleNotifier,
                            builder: (context, englishSubtitle, child) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (audioProvider.subtitleMode != SubtitleMode.english && 
                                      chineseSubtitle.isNotEmpty)
                                    Text(
                                      chineseSubtitle,
                                      style: const TextStyle(
                                        fontSize: 20,  // 增大字体
                                        height: 1.8,   // 增加行高
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  if (audioProvider.subtitleMode == SubtitleMode.both)
                                    const SizedBox(height: 24),  // 增加中英文间距
                                  if (audioProvider.subtitleMode != SubtitleMode.chinese && 
                                      englishSubtitle.isNotEmpty)
                                    Text(
                                      englishSubtitle,
                                      style: const TextStyle(
                                        fontSize: 20,  // 增大字体
                                        height: 1.8,   // 增加行高
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // 播放控制区域
              Container(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 16.0,    // 增加顶部间距
                  bottom: 24.0, // 增加底部间距
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 进度条
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: ValueListenableBuilder<double>(
                        valueListenable: audioProvider.progressNotifier,
                        builder: (context, progress, child) {
                          return Slider(
                            value: progress,
                            onChanged: (value) => audioProvider.seek(
                              Duration(milliseconds: (value * audioProvider.duration.inMilliseconds).round())
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // 时间显示
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ValueListenableBuilder<Duration>(
                            valueListenable: audioProvider.positionNotifier,
                            builder: (context, position, child) {
                              return Text(_formatDuration(position));
                            },
                          ),
                          ValueListenableBuilder<Duration>(
                            valueListenable: audioProvider.durationNotifier,
                            builder: (context, duration, child) {
                              return Text(_formatDuration(duration));
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 功能按钮行
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: audioProvider.toggleLanguage,
                          icon: const Icon(Icons.volume_up, size: 20),
                          label: Text(
                            audioProvider.currentLanguage == 'cn' ? '中文' : 'English',
                            style: const TextStyle(fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: audioProvider.toggleSubtitleMode,
                          icon: const Icon(Icons.subtitles, size: 20),
                          label: Text(
                            _getSubtitleModeText(audioProvider.subtitleMode),
                            style: const TextStyle(fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // 播放控制按钮行
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous),
                          onPressed: audioProvider.playPrevious,
                          iconSize: 32,
                          padding: EdgeInsets.zero,
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: audioProvider.isPlayingNotifier,
                          builder: (context, isPlaying, child) {
                            return IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                              ),
                              onPressed: audioProvider.togglePlayPause,
                              iconSize: 48,
                              padding: EdgeInsets.zero,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next),
                          onPressed: audioProvider.playNext,
                          iconSize: 32,
                          padding: EdgeInsets.zero,
                        ),
                        ValueListenableBuilder<double>(
                          valueListenable: audioProvider.playbackSpeedNotifier,
                          builder: (context, speed, child) {
                            return Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              child: GestureDetector(
                                onTap: audioProvider.toggleSpeed,
                                child: Text(
                                  '${speed}x',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.queue_music),
                          onPressed: () => _showPlaylist(context),
                          iconSize: 32,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 