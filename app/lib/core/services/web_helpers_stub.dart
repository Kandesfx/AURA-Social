import 'dart:typed_data';

// Fallback stub for non-web platforms

void requestMicPermission() {
  // No-op on mobile/desktop stub
}

void startSpeechToText({
  required Function(String text) onResult,
  required Function(String error) onError,
  required Function() onListeningStarted,
  required Function() onListeningStopped,
}) {
  onError('Speech recognition is only supported on Web Chrome.');
}

void stopSpeechToText() {
  // No-op
}

void startAudioRecording() {
  // No-op
}

void stopAudioRecording(Function(Uint8List bytes) onComplete) {
  // No-op
}

void cancelAudioRecording() {
  // No-op
}

void playAudioUrl(String url, Function() onEnded, Function(String error) onError) {
  // No-op
}

void stopAudioPlayback() {
  // No-op
}
