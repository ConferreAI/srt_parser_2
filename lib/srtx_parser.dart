import 'dart:convert' show LineSplitter;
import 'package:meta/meta.dart';

/// formatting (partial compliance) : https://en.wikipedia.org/wiki/SubRip#Formatting
class Range {
  const Range(this.begin, this.end);

  final int begin;
  final int end;

  Duration get duration => Duration(milliseconds: end - begin);
}

class Subtitle {
  Subtitle({
    required this.id,
    required this.range,
    required this.content,
    this.lineBrake = false,
    this.translation,
  });

  final int id;
  final Range range;
  final String content;
  final String? translation;
  final bool lineBrake;
}

@visibleForTesting
Range? parseBeginEnd(String line) {
  final RegExp pattern = RegExp(
      r'(\d\d):(\d\d):(\d\d),(\d\d\d) --> (\d\d):(\d\d):(\d\d),(\d\d\d)');
  final Match? match = pattern.firstMatch(line);

  if (match == null) {
    return null;
  } else if (match.groups([1, 2, 3, 4, 5, 6, 7, 8]).any((g) => g == null) ||
      int.parse(match.group(1)!) > 23 ||
      int.parse(match.group(2)!) > 59 ||
      int.parse(match.group(3)!) > 59 ||
      int.parse(match.group(4)!) > 999 ||
      int.parse(match.group(5)!) > 23 ||
      int.parse(match.group(6)!) > 59 ||
      int.parse(match.group(7)!) > 59 ||
      int.parse(match.group(8)!) > 999) {
    throw RangeError(
        'time components are out of range. Please modify the .srt file.');
  } else {
    final int begin = timeStampToMillis(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
        int.parse(match.group(4)!));

    final int end = timeStampToMillis(
        int.parse(match.group(5)!),
        int.parse(match.group(6)!),
        int.parse(match.group(7)!),
        int.parse(match.group(8)!));

    return Range(begin, end);
  }
}

@visibleForTesting
int timeStampToMillis(int hour, int minute, int sec, int ms) {
  if (hour <= 23 &&
      hour >= 0 &&
      minute <= 59 &&
      minute >= 0 &&
      sec <= 59 &&
      sec >= 0 &&
      ms <= 999 &&
      ms >= 0) {
    int result = ms;
    result += sec * 1000;
    result += minute * 60 * 1000;
    result += hour * 60 * 60 * 1000;
    return result;
  } else {
    throw RangeError('sth. is outa range');
  }
}

@visibleForTesting
List<String> splitIntoLines(String data) {
  return LineSplitter().convert(data);
}

//splits
@visibleForTesting
List<List<String>> splitByEmptyLine(List<String> lines) {
  final List<List<String>> result = [];
  List<String> chunk = <String>[];

  for (String line in lines) {
    if (line.isEmpty) {
      result.add(chunk);
      chunk = [];
    } else {
      chunk.add(line);
    }
  }

  if (chunk.isNotEmpty) {
    result.add(chunk);
  }

  return result;
}

List<Subtitle> parseSrtx(String srt) {
  final List<Subtitle> result = [];

  final List<String> split = splitIntoLines(srt);
  final List<List<String>> splitChunk = splitByEmptyLine(split);

  for (List<String> chunk in splitChunk) {
    if (chunk.length < 3) {
      continue;
    }

    // print(chunk);
    final Range? range = parseBeginEnd(chunk[1]);
    if (range == null) continue;
    final int id = int.parse(chunk[0]);
    final String text = chunk[2];

    var translation;
    var lineBrake = false;
    for (var i = 2; i < chunk.length; i++) {
      var chunkLet = chunk[i];
      if (chunkLet.startsWith('translation: ')) {
        translation = chunkLet.split(': ')[1];
      }
      if (chunkLet == '<br>') {
        lineBrake = true;
      }
    }
    final Subtitle subtitle = Subtitle(
        id: id,
        range: range,
        content: text,
        translation: translation,
        lineBrake: lineBrake);
    result.add(subtitle);
  }

  return result;
}
