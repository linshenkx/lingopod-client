import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final currentPodcast = audioProvider.currentPodcast;
    final bool hasNext = audioProvider.currentIndex < audioProvider.podcastList.length - 1;
    final bool hasPrevious = audioProvider.currentIndex > 0;
    
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 进度条
          SizedBox(
            height: 20,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: ValueListenableBuilder<double>(
                valueListenable: audioProvider.progressNotifier,
                builder: (context, progress, child) {
                  final clampedProgress = progress.clamp(0.0, 1.0);
                  return Slider(
                    value: clampedProgress,
                    onChanged: (value) => audioProvider.seek(
                      Duration(milliseconds: (value * audioProvider.duration.inMilliseconds).round())
                    ),
                  );
                },
              ),
            ),
          ),
          // 播放时间
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ValueListenableBuilder<Duration>(
                  valueListenable: audioProvider.positionNotifier,
                  builder: (context, position, child) {
                    return Text(
                      _formatDuration(position),
                      style: const TextStyle(fontSize: 12),
                    );
                  },
                ),
                ValueListenableBuilder<Duration>(
                  valueListenable: audioProvider.durationNotifier,
                  builder: (context, duration, child) {
                    return Text(
                      _formatDuration(duration),
                      style: const TextStyle(fontSize: 12),
                    );
                  },
                ),
              ],
            ),
          ),
          // 控制按钮行
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // 播客标题
                  Expanded(
                    child: Text(
                      currentPodcast?.title ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 控制按钮
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: hasPrevious ? audioProvider.playPrevious : null,
                    padding: EdgeInsets.zero,
                    color: hasPrevious ? null : Colors.grey,
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: audioProvider.isPlayingNotifier,
                    builder: (context, isPlaying, child) {
                      return IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 32,
                        ),
                        onPressed: () {
                          if (audioProvider.currentPodcast != null) {
                            audioProvider.togglePlayPause();
                          }
                        },
                        padding: EdgeInsets.zero,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: hasNext ? audioProvider.playNext : null,
                    padding: EdgeInsets.zero,
                    color: hasNext ? null : Colors.grey,
                  ),
                  ValueListenableBuilder<double>(
                    valueListenable: audioProvider.playbackSpeedNotifier,
                    builder: (context, speed, child) {
                      return TextButton(
                        onPressed: audioProvider.toggleSpeed,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 40),
                        ),
                        child: Text(
                          '${speed}x',
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.language),
                    onPressed: audioProvider.toggleLanguage,
                    padding: EdgeInsets.zero,
                  ),
                  IconButton(
                    icon: const Icon(Icons.expand_less),
                    onPressed: () => Navigator.pushNamed(context, '/player'),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 