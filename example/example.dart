import 'package:srt_parser_2/srt_parser_2.dart';
import 'dart:io';


Future<void> main() async {
  String srt = await File('test/transcription.srtx').readAsString();
  List<Subtitle> subtitles = parseSrt(srt);
  for (Subtitle item in subtitles) {
    print('subtitle\'s ID is: ${item.id}');
    print(
        'subtitle\'s Begin is: ${item.range.begin} and End is: ${item.range.end}');
    print(
        'subtitle\'s Text is: ${item.content}');
    print(
        'subtitle\'s Translation is: ${item.translation}');
    print('----');
  }
}
