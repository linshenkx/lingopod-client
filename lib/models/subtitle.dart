class SubtitleEntry {
  final int index;
  final Duration start;
  final Duration end;
  final String textCn;
  final String textEn;

  SubtitleEntry({
    required this.index,
    required this.start,
    required this.end,
    required this.textCn,
    required this.textEn,
  });
}

class SubtitleService {
  static Duration _parseTime(String time) {
    final parts = time.split(':');
    final secondsParts = parts[2].split(',');
    
    return Duration(
      hours: int.parse(parts[0]),
      minutes: int.parse(parts[1]),
      seconds: int.parse(secondsParts[0]),
      milliseconds: int.parse(secondsParts[1]),
    );
  }

  static List<SubtitleEntry> parseSRT(String content) {
    final entries = <SubtitleEntry>[];
    final blocks = content.split('\n\n');

    for (final block in blocks) {
      if (block.trim().isEmpty) continue;

      final lines = block.split('\n');
      if (lines.length < 4) continue;

      try {
        final index = int.parse(lines[0]);
        final times = lines[1].split(' --> ');
        final start = _parseTime(times[0]);
        final end = _parseTime(times[1]);
        final textCn = lines[2].trim();
        final textEn = lines[3].trim();

        entries.add(SubtitleEntry(
          index: index,
          start: start,
          end: end,
          textCn: textCn,
          textEn: textEn,
        ));
      } catch (e) {
        print('解析字幕块失败: $e');
        continue;
      }
    }

    return entries;
  }
}
