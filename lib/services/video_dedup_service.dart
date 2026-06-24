import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers processed video files so the same upload is not analyzed twice.
class VideoDedupService {
  VideoDedupService._();
  static final VideoDedupService instance = VideoDedupService._();

  static const _prefsKey = 'processed_video_hashes_v1';

  Future<String> hashFile(String filePath) async {
    final file = File(filePath);
    final digest = await md5.bind(file.openRead()).first;
    return digest.toString();
  }

  Future<bool> isProcessed(String fileHash) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    return raw.contains(fileHash);
  }

  Future<void> markProcessed(String fileHash) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    if (raw.contains(fileHash)) return;
    raw.insert(0, fileHash);
    // Keep last 200 video hashes
    final trimmed = raw.length > 200 ? raw.sublist(0, 200) : raw;
    await prefs.setStringList(_prefsKey, trimmed);
    debugPrint('VideoDedupService: marked processed $fileHash');
  }

  /// Debug helper — not used in production flow.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
