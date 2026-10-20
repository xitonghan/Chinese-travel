// 音频服务：录音（16kHz mono WAV）+ 播放标准音 + 录音 PCM 读取。
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioService {
  static final AudioService _i = AudioService._();
  factory AudioService() => _i;
  AudioService._();

  final _rec = AudioRecorder();
  final _player = AudioPlayer();
  String? _recPath;

  Future<bool> hasMicPermission() => _rec.hasPermission();

  Future<void> startRecording() async {
    final dir = await getTemporaryDirectory();
    _recPath =
        '${dir.path}/speak_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _rec.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: _recPath!,
    );
  }

  /// 停止录音并返回 PCM16 样本（跳过 44 字节 WAV 头）。
  Future<Int16List?> stopRecording() async {
    await _rec.stop();
    if (_recPath == null) return null;
    final f = File(_recPath!);
    if (!await f.exists()) return null;
    final bytes = await f.readAsBytes();
    if (bytes.length <= 44) return null;
    final pcm = bytes.buffer.asByteData(44);
    return pcm.buffer.asInt16List(44, (bytes.length - 44) ~/ 2);
  }

  Future<void> play(String assetOrPath) async {
    final isFile = !assetOrPath.startsWith('assets/');
    if (isFile) {
      await _player.play(DeviceFileSource(assetOrPath));
    } else {
      await _player.play(AssetSource(assetOrPath.replaceFirst('assets/', '')));
    }
  }

  /// 资源不存在时静默跳过（外部数据可能缺文件）。
  Future<void> playIfExists(String? assetOrPath) async {
    if (assetOrPath == null || assetOrPath.isEmpty) return;
    await play(assetOrPath);
  }

  Future<void> stopPlayback() async => _player.stop();

  Future<void> dispose() async {
    _rec.dispose();
    _player.dispose();
  }
}
