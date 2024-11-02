import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';

class SubtitleDisplay extends StatelessWidget {
  const SubtitleDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: true);
    
    return ValueListenableBuilder<String>(
      valueListenable: audioProvider.chineseSubtitleNotifier,
      builder: (context, chineseSubtitle, child) {
        return ValueListenableBuilder<String>(
          valueListenable: audioProvider.englishSubtitleNotifier,
          builder: (context, englishSubtitle, child) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (audioProvider.subtitleMode != SubtitleMode.english)
                    Text(
                      chineseSubtitle,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  if (audioProvider.subtitleMode != SubtitleMode.chinese)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        englishSubtitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
} 