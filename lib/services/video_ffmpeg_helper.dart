import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Desktop-safe video processing via FFmpeg CLI (Windows / macOS / Linux).
class VideoFfmpegHelper {
  static String? _cachedExecutable;

  static bool get isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  /// Extract one JPEG/PNG frame at [timeSeconds] using FFmpeg.
  static Future<Uint8List?> extractJpegFrame(
    String videoPath, {
    double timeSeconds = 1.5,
  }) async {
    final ffmpeg = await _resolveExecutable();
    if (ffmpeg == null) return null;

    // Try multiple output pipelines — some phone/camera MP4s use YUV ranges
    // that break the MJPEG pipe encoder on newer FFmpeg builds.
    final strategies = <List<String>>[
      [
        '-vf',
        'scale=720:-2:flags=lanczos,format=yuvj420p',
        '-frames:v',
        '1',
        '-q:v',
        '3',
        '-c:v',
        'mjpeg',
        '-f',
        'image2pipe',
        'pipe:1',
      ],
      [
        '-vf',
        'scale=720:-2:flags=lanczos,format=yuv420p',
        '-frames:v',
        '1',
        '-c:v',
        'mjpeg',
        '-strict',
        'unofficial',
        '-q:v',
        '3',
        '-f',
        'image2pipe',
        'pipe:1',
      ],
      [
        '-vf',
        'scale=720:-2:flags=lanczos',
        '-frames:v',
        '1',
        '-c:v',
        'png',
        '-f',
        'image2pipe',
        'pipe:1',
      ],
    ];

    for (var i = 0; i < strategies.length; i++) {
      final bytes = await _runExtract(
        ffmpeg: ffmpeg,
        videoPath: videoPath,
        timeSeconds: timeSeconds,
        outputArgs: strategies[i],
        accurateSeek: i > 0,
      );
      if (bytes != null) {
        debugPrint(
          'VideoFfmpeg: frame OK at ${timeSeconds}s '
          '(${bytes.length} bytes, strategy ${i + 1})',
        );
        return bytes;
      }
    }

    debugPrint('VideoFfmpeg: all extract strategies failed at ${timeSeconds}s');
    return null;
  }

  static Future<Uint8List?> _runExtract({
    required String ffmpeg,
    required String videoPath,
    required double timeSeconds,
    required List<String> outputArgs,
    required bool accurateSeek,
  }) async {
    try {
      final inputArgs = accurateSeek
          ? [
              '-i',
              videoPath,
              '-ss',
              timeSeconds.toStringAsFixed(2),
            ]
          : [
              '-ss',
              timeSeconds.toStringAsFixed(2),
              '-i',
              videoPath,
            ];

      final result = await Process.run(
        ffmpeg,
        [
          '-hide_banner',
          '-loglevel',
          'error',
          ...inputArgs,
          ...outputArgs,
        ],
        stdoutEncoding: null,
        stderrEncoding: null,
      );

      if (result.exitCode != 0) {
        debugPrint(
          'VideoFfmpeg: extract failed at ${timeSeconds}s — '
          '${_decodeProcessText(result.stderr)}',
        );
        return null;
      }

      final out = result.stdout;
      if (out is! List<int> || out.length < 128) return null;
      return Uint8List.fromList(out);
    } catch (e) {
      debugPrint('VideoFfmpeg: extract error at ${timeSeconds}s — $e');
      return null;
    }
  }

  static String _decodeProcessText(Object? data) {
    if (data == null) return '';
    if (data is String) return data.trim();
    if (data is List<int>) {
      return utf8.decode(data, allowMalformed: true).trim();
    }
    return data.toString();
  }

  /// Re-encode video to fit under [maxBytes]. Returns null if FFmpeg unavailable.
  static Future<Uint8List?> compressToMaxSize(
    String videoPath,
    int maxBytes,
  ) async {
    final ffmpeg = await _resolveExecutable();
    if (ffmpeg == null) return null;

    try {
      final tempDir = await getTemporaryDirectory();
      final outPath =
          '${tempDir.path}${Platform.pathSeparator}cattle_ai_${DateTime.now().millisecondsSinceEpoch}.mp4';

      for (final crf in [28, 32, 36]) {
        final result = await Process.run(
          ffmpeg,
          [
            '-hide_banner',
            '-loglevel',
            'error',
            '-y',
            '-i',
            videoPath,
            '-c:v',
            'libx264',
            '-crf',
            '$crf',
            '-preset',
            'fast',
            '-an',
            '-movflags',
            '+faststart',
            outPath,
          ],
        );

        if (result.exitCode != 0) {
          debugPrint(
            'VideoFfmpeg: compress crf=$crf failed — '
            '${_decodeProcessText(result.stderr)}',
          );
          continue;
        }

        final outFile = File(outPath);
        if (!outFile.existsSync()) continue;

        final bytes = await outFile.readAsBytes();
        try {
          await outFile.delete();
        } catch (_) {}

        debugPrint('VideoFfmpeg: compressed crf=$crf → ${bytes.length} bytes');
        if (bytes.length <= maxBytes) return bytes;
      }
    } catch (e) {
      debugPrint('VideoFfmpeg: compress error — $e');
    }
    return null;
  }

  static Future<String?> _resolveExecutable() async {
    if (_cachedExecutable != null) return _cachedExecutable;

    final fromEnv = Platform.environment['FFMPEG_PATH']?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty && File(fromEnv).existsSync()) {
      _cachedExecutable = fromEnv;
      return _cachedExecutable;
    }

    if (Platform.isWindows) {
      final where = await Process.run('where', ['ffmpeg'], runInShell: true);
      if (where.exitCode == 0) {
        final line = where.stdout.toString().trim().split('\n').first.trim();
        if (line.isNotEmpty && File(line).existsSync()) {
          _cachedExecutable = line;
          return _cachedExecutable;
        }
      }
      const common = [
        r'C:\ffmpeg\bin\ffmpeg.exe',
        r'C:\Program Files\ffmpeg\bin\ffmpeg.exe',
      ];
      for (final p in common) {
        if (File(p).existsSync()) {
          _cachedExecutable = p;
          return _cachedExecutable;
        }
      }
    } else {
      final which = await Process.run('which', ['ffmpeg']);
      if (which.exitCode == 0) {
        final p = which.stdout.toString().trim();
        if (p.isNotEmpty) {
          _cachedExecutable = p;
          return _cachedExecutable;
        }
      }
    }

    debugPrint(
      'VideoFfmpeg: ffmpeg not found — install FFmpeg and add to PATH, '
      'or set FFMPEG_PATH environment variable.',
    );
    return null;
  }
}
