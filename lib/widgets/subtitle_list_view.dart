import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:async';
import '../providers/audio_provider.dart';
import '../config/style_config.dart';

class SubtitleListView extends StatefulWidget {
  const SubtitleListView({super.key});

  @override
  State<SubtitleListView> createState() => _SubtitleListViewState();
}

class _SubtitleListViewState extends State<SubtitleListView> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  bool _userScrolling = false;
  Timer? _scrollTimer;
  int _currentIndex = -1;

  @override
  void dispose() {
    _scrollTimer?.cancel();
    super.dispose();
  }

  void _onUserScroll() {
    _userScrolling = true;
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 200), () {
      _userScrolling = false;
    });
  }

  void _scrollToIndex(int index, bool animated) {
    if (index < 0 || _userScrolling) return;

    _itemScrollController.scrollTo(
      index: index + 1,
      duration: animated ? const Duration(milliseconds: 200) : Duration.zero,
      curve: Curves.easeOutCubic,
      alignment: 0.4,
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final subtitles = audioProvider.subtitleEntries;

    return LayoutBuilder(
      builder: (context, constraints) {
        return ValueListenableBuilder<Duration>(
          valueListenable: audioProvider.positionNotifier,
          builder: (context, position, child) {
            final currentIndex = audioProvider.getCurrentSubtitleIndex();

            if (currentIndex != _currentIndex && !_userScrolling) {
              _currentIndex = currentIndex;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToIndex(currentIndex, true);
              });
            }

            return Container(
              decoration: BoxDecoration(
                color: isDarkMode
                    ? StyleConfig.darkBackground
                    : StyleConfig.lightBackground,
                borderRadius: BorderRadius.circular(StyleConfig.radiusM),
              ),
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification) {
                    _onUserScroll();
                  }
                  return true;
                },
                child: ScrollablePositionedList.builder(
                  itemCount: subtitles.length + 2, // 添加头尾空白项
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  itemBuilder: (context, index) {
                    // 头尾空白项
                    if (index == 0 || index == subtitles.length + 1) {
                      return SizedBox(height: constraints.maxHeight / 2);
                    }

                    final realIndex = index - 1;
                    final subtitle = subtitles[realIndex];
                    final isCurrentSubtitle = realIndex == currentIndex;

                    return GestureDetector(
                      onTap: () {
                        audioProvider.seekToSubtitle(realIndex);
                        _userScrolling = false;
                        _scrollToIndex(realIndex, true);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: StyleConfig.spacingM,
                          vertical: StyleConfig.spacingS,
                        ),
                        margin: EdgeInsets.symmetric(
                          vertical: StyleConfig.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrentSubtitle
                              ? (isDarkMode
                                  ? StyleConfig.brandPrimary.withOpacity(0.2)
                                  : StyleConfig.brandPrimary.withOpacity(0.1))
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(StyleConfig.radiusS),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (audioProvider.subtitleMode !=
                                SubtitleMode.chinese)
                              Text(
                                subtitle.english,
                                style: TextStyle(
                                  fontSize: StyleConfig.fontSizeM,
                                  color: isCurrentSubtitle
                                      ? StyleConfig.brandPrimary
                                      : (isDarkMode
                                          ? StyleConfig.darkTextPrimary
                                          : StyleConfig.lightTextPrimary),
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            if (audioProvider.subtitleMode !=
                                    SubtitleMode.chinese &&
                                audioProvider.subtitleMode !=
                                    SubtitleMode.english)
                              SizedBox(height: StyleConfig.spacingXS),
                            if (audioProvider.subtitleMode !=
                                SubtitleMode.english)
                              Text(
                                subtitle.chinese,
                                style: TextStyle(
                                  fontSize: StyleConfig.fontSizeM,
                                  color: isCurrentSubtitle
                                      ? StyleConfig.brandPrimary
                                      : (isDarkMode
                                          ? StyleConfig.darkTextSecondary
                                          : StyleConfig.lightTextSecondary),
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
