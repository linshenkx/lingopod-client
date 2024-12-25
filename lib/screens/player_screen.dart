import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/playlist_bottom_sheet.dart';
import '../widgets/subtitle_list_view.dart';
import '../config/style_config.dart';

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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentPodcast = audioProvider.currentPodcast;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWideScreen = screenWidth >= StyleConfig.tabletBreakpoint;
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Theme(
      data: isDarkMode
          ? StyleConfig.getPlayerDarkTheme()
          : StyleConfig.getPlayerLightTheme(),
      child: Scaffold(
        backgroundColor: isDarkMode
            ? StyleConfig.darkBackground
            : StyleConfig.lightBackground,
        body: SafeArea(
          bottom: true,
          child: Container(
            color: isDarkMode
                ? StyleConfig.darkBackground
                : StyleConfig.lightBackground,
            child: Column(
              children: [
                // 顶部栏
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        StyleConfig.getResponsivePadding(context).horizontal,
                    vertical: StyleConfig.spacingM,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? StyleConfig.darkSurfaceColor
                        : StyleConfig.lightSurfaceColor,
                    boxShadow: isDarkMode
                        ? StyleConfig.darkShadow
                        : StyleConfig.lightShadow,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down),
                        onPressed: onClose,
                        iconSize: 28,
                        color: isDarkMode
                            ? StyleConfig.darkTextPrimary
                            : StyleConfig.lightTextPrimary,
                      ),
                      Expanded(
                        child: Text(
                          currentPodcast?.title ?? '',
                          style: (isDarkMode
                                  ? StyleConfig.getDarkTheme()
                                  : StyleConfig.getLightTheme())
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontSize: isWideScreen
                                    ? StyleConfig.fontSizeL
                                    : StyleConfig.fontSizeM,
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 48), // 平衡布局
                    ],
                  ),
                ),

                // 主内容区域
                Expanded(
                  child: Column(
                    children: [
                      // 字幕区域 - 使用 Expanded 确保占据所有剩余空间
                      Expanded(
                        child: Container(
                          color: isDarkMode
                              ? StyleConfig.darkBackground
                              : StyleConfig.lightBackground,
                          child: const SubtitleListView(),
                        ),
                      ),

                      // 控制区域 - 固定在底部，不使用 Stack
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? StyleConfig.darkSurfaceColor
                              : StyleConfig.lightSurfaceColor,
                          boxShadow: isDarkMode
                              ? StyleConfig.darkShadow
                              : StyleConfig.lightShadow,
                        ),
                        child: SafeArea(
                          top: false,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 进度条
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isWideScreen
                                      ? StyleConfig.spacingXL * 2
                                      : StyleConfig.spacingM,
                                  vertical: isWideScreen
                                      ? StyleConfig.spacingM
                                      : StyleConfig.spacingS,
                                ),
                                child: ValueListenableBuilder<Duration>(
                                  valueListenable:
                                      audioProvider.positionNotifier,
                                  builder: (context, position, child) {
                                    return ValueListenableBuilder<Duration?>(
                                      valueListenable:
                                          audioProvider.durationNotifier,
                                      builder: (context, duration, child) {
                                        final total = duration ?? Duration.zero;
                                        return Column(
                                          children: [
                                            Slider(
                                              value: position.inSeconds >
                                                      total.inSeconds
                                                  ? total.inSeconds.toDouble()
                                                  : position.inSeconds
                                                      .toDouble(),
                                              max: total.inSeconds.toDouble(),
                                              min: 0.0,
                                              onChanged: (value) {
                                                audioProvider.seek(Duration(
                                                    seconds: value.toInt()));
                                              },
                                              activeColor:
                                                  StyleConfig.brandPrimary,
                                              inactiveColor: isDarkMode
                                                  ? StyleConfig.darkDividerColor
                                                  : StyleConfig
                                                      .lightDividerColor,
                                            ),
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal:
                                                    StyleConfig.spacingM,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    _formatDuration(position),
                                                    style: TextStyle(
                                                      color: isDarkMode
                                                          ? StyleConfig
                                                              .darkTextSecondary
                                                          : StyleConfig
                                                              .lightTextSecondary,
                                                    ),
                                                  ),
                                                  Text(
                                                    _formatDuration(total),
                                                    style: TextStyle(
                                                      color: isDarkMode
                                                          ? StyleConfig
                                                              .darkTextSecondary
                                                          : StyleConfig
                                                              .lightTextSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),

                              // 控制按钮区域
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: StyleConfig.spacingM,
                                  vertical: isWideScreen
                                      ? StyleConfig.spacingS
                                      : StyleConfig.spacingXS,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // 音频语言切换
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: audioProvider.toggleLanguage,
                                        icon: const Icon(Icons.volume_up,
                                            size: 20),
                                        label: Text(
                                          audioProvider.currentLanguage == 'cn'
                                              ? '中文'
                                              : 'EN',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            vertical: StyleConfig.spacingS,
                                          ),
                                          backgroundColor: isDarkMode
                                              ? StyleConfig.brandPrimary
                                                  .withOpacity(0.8)
                                              : StyleConfig.brandPrimary,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),

                                    SizedBox(width: StyleConfig.spacingS),

                                    // 字幕模式切换
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            audioProvider.toggleSubtitleMode,
                                        icon: const Icon(Icons.subtitles,
                                            size: 20),
                                        label: Text(
                                          _getSubtitleModeText(
                                              audioProvider.subtitleMode),
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            vertical: StyleConfig.spacingS,
                                          ),
                                          backgroundColor: isDarkMode
                                              ? Color(0xFF9C27B0)
                                                  .withOpacity(0.8)
                                              : Color(0xFF9C27B0),
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),

                                    SizedBox(width: StyleConfig.spacingS),

                                    // 难度等级
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            audioProvider.toggleDifficulty,
                                        icon:
                                            const Icon(Icons.school, size: 20),
                                        label: Text(
                                          audioProvider.difficultyText,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            vertical: StyleConfig.spacingS,
                                          ),
                                          backgroundColor: isDarkMode
                                              ? Color(0xFF4CAF50)
                                                  .withOpacity(0.8)
                                              : Color(0xFF4CAF50),
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 播放控制按钮行
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: isWideScreen
                                      ? StyleConfig.spacingM
                                      : StyleConfig.spacingS,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.skip_previous),
                                      onPressed: audioProvider.playPrevious,
                                      iconSize: isWideScreen ? 36 : 32,
                                      padding: EdgeInsets.zero,
                                      color: isDarkMode
                                          ? StyleConfig.darkTextPrimary
                                          : StyleConfig.lightTextPrimary,
                                    ),
                                    ValueListenableBuilder<bool>(
                                      valueListenable:
                                          audioProvider.isPlayingNotifier,
                                      builder: (context, isPlaying, child) {
                                        return IconButton(
                                          icon: Icon(
                                            isPlaying
                                                ? Icons.pause
                                                : Icons.play_arrow,
                                          ),
                                          onPressed:
                                              audioProvider.togglePlayPause,
                                          iconSize: isWideScreen ? 56 : 48,
                                          padding: EdgeInsets.zero,
                                          color: StyleConfig.brandPrimary,
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.skip_next),
                                      onPressed: audioProvider.playNext,
                                      iconSize: isWideScreen ? 36 : 32,
                                      padding: EdgeInsets.zero,
                                      color: isDarkMode
                                          ? StyleConfig.darkTextPrimary
                                          : StyleConfig.lightTextPrimary,
                                    ),
                                    ValueListenableBuilder<double>(
                                      valueListenable:
                                          audioProvider.playbackSpeedNotifier,
                                      builder: (context, speed, child) {
                                        return Container(
                                          width: isWideScreen ? 56 : 48,
                                          height: isWideScreen ? 56 : 48,
                                          alignment: Alignment.center,
                                          child: GestureDetector(
                                            onTap: audioProvider.toggleSpeed,
                                            child: Text(
                                              '${speed}x',
                                              style: TextStyle(
                                                fontSize:
                                                    isWideScreen ? 18 : 16,
                                                color: isDarkMode
                                                    ? StyleConfig
                                                        .darkTextPrimary
                                                    : StyleConfig
                                                        .lightTextPrimary,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.queue_music),
                                      onPressed: () => _showPlaylist(context),
                                      iconSize: isWideScreen ? 36 : 32,
                                      padding: EdgeInsets.zero,
                                      color: isDarkMode
                                          ? StyleConfig.darkTextPrimary
                                          : StyleConfig.lightTextPrimary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
