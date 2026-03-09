import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AudioService {
  final _record = AudioRecorder();

  Future<void> startRecording() async {
    if (await _record.hasPermission()) {
      if (kIsWeb) {
        // On web, record doesn't need a path, it uses a blob
        await _record.start(const RecordConfig(), path: '');
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final path = p.join(dir.path, 'vibe_${DateTime.now().millisecondsSinceEpoch}.m4a');
        await _record.start(const RecordConfig(), path: path);
      }
    }
  }

  Future<String?> stopRecording() async {
    final path = await _record.stop();
    return path;
  }

  Stream<Amplitude> get onAmplitudeChanged {
    return _record.onAmplitudeChanged(const Duration(milliseconds: 50));
  }

  void dispose() {
    _record.dispose();
  }
}
