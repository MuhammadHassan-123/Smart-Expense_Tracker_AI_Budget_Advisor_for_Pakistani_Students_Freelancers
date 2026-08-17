import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText speech = SpeechToText();

  Future<String> listen() async {
    final available = await speech.initialize();

    if (!available) {
      return '';
    }

    String result = '';

    await speech.listen(
      onResult: (value) {
        result = value.recognizedWords;
      },
    );

    await Future.delayed(const Duration(seconds: 5));
    await speech.stop();

    return result;
  }

  void dispose() {
    speech.stop();
  }
}
