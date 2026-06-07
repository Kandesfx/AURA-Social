import 'dart:html' as html;
import 'dart:typed_data';

void requestMicPermission() {
  html.window.navigator.getUserMedia(audio: true).then((stream) {
    // Permission granted, stop the stream immediately to close recording indicator
    stream.getTracks().forEach((track) => track.stop());
  }).catchError((e) {
    // Permission denied or error
  });
}

html.SpeechRecognition? _recognition;

void startSpeechToText({
  required Function(String text) onResult,
  required Function(String error) onError,
  required Function() onListeningStarted,
  required Function() onListeningStopped,
}) {
  try {
    if (!html.SpeechRecognition.supported) {
      onError('Speech recognition not supported in this browser.');
      return;
    }
    
    _recognition = html.SpeechRecognition()
      ..continuous = false
      ..interimResults = false
      ..lang = 'vi-VN';

    _recognition!.onStart.listen((_) {
      onListeningStarted();
    });

    _recognition!.onEnd.listen((_) {
      onListeningStopped();
    });

    _recognition!.onResult.listen((event) {
      final results = event.results;
      if (results != null && results.isNotEmpty) {
        final alternative = results[0].item(0);
        final transcript = alternative?.transcript;
        if (transcript != null) {
          onResult(transcript);
        }
      }
    });

    _recognition!.onError.listen((event) {
      onError('Lỗi mic: ${event.error}');
    });

    _recognition!.start();
  } catch (e) {
    onError('Khởi tạo Mic thất bại: $e');
  }
}

void stopSpeechToText() {
  _recognition?.stop();
}

html.MediaRecorder? _mediaRecorder;
List<html.Blob> _audioChunks = [];
html.MediaStream? _mediaStream;

void startAudioRecording() {
  html.window.navigator.mediaDevices?.getUserMedia({'audio': true}).then((stream) {
    _mediaStream = stream;
    _audioChunks = [];
    _mediaRecorder = html.MediaRecorder(stream);
    
    _mediaRecorder!.on['dataavailable'].listen((event) {
      final blob = (event as dynamic).data as html.Blob?;
      if (blob != null) {
        _audioChunks.add(blob);
      }
    });
    
    _mediaRecorder!.start();
  }).catchError((e) {
    // Microphone permission denied or not found
  });
}

void stopAudioRecording(Function(Uint8List bytes) onComplete) {
  if (_mediaRecorder == null) return;
  
  _mediaRecorder!.on['stop'].listen((event) {
    final blob = html.Blob(_audioChunks, 'audio/webm');
    final reader = html.FileReader();
    
    reader.onLoadEnd.listen((e) {
      final res = reader.result;
      if (res is Uint8List) {
        onComplete(res);
      } else if (res is ByteBuffer) {
        onComplete(res.asUint8List());
      } else if (res is List<int>) {
        onComplete(Uint8List.fromList(res));
      } else {
        onComplete(Uint8List(0));
      }
    });
    
    reader.readAsArrayBuffer(blob);
    
    // Stop all tracks to release mic recording light
    _mediaStream?.getTracks().forEach((track) => track.stop());
    _mediaStream = null;
  });
  
  _mediaRecorder!.stop();
  _mediaRecorder = null;
}

void cancelAudioRecording() {
  if (_mediaRecorder == null) return;
  
  // Stop all tracks to release mic recording light
  _mediaStream?.getTracks().forEach((track) => track.stop());
  _mediaStream = null;
  _mediaRecorder = null;
  _audioChunks = [];
}

html.AudioElement? _activeAudio;
Function()? _onActiveStopped;

void playAudioUrl(String url, Function() onEnded, Function(String error) onError) {
  try {
    // Stop any existing playing audio first
    stopAudioPlayback();
    
    final audio = html.AudioElement(url);
    _activeAudio = audio;
    _onActiveStopped = onEnded;
    
    audio.onEnded.listen((_) {
      _activeAudio = null;
      _onActiveStopped = null;
      onEnded();
    });
    
    audio.onError.listen((e) {
      _activeAudio = null;
      _onActiveStopped = null;
      onError('Lỗi phát âm thanh');
    });
    
    audio.play();
  } catch (e) {
    onError(e.toString());
  }
}

void stopAudioPlayback() {
  if (_activeAudio != null) {
    try {
      _activeAudio!.pause();
    } catch (_) {}
    _activeAudio = null;
  }
  if (_onActiveStopped != null) {
    try {
      _onActiveStopped!();
    } catch (_) {}
    _onActiveStopped = null;
  }
}
