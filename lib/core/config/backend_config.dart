import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Resolves the Python PyTorch backend URL.
///
/// Debug → [LOCAL_MODEL_BACKEND_URL] (127.0.0.1 / emulator).
/// Release APK → [RENDER_MODEL_BACKEND_URL] if set, else [RELEASE_LOCAL_BACKEND_URL]
/// or [LOCAL_MODEL_BACKEND_URL] (PC Wi‑Fi IP for physical phone + local backend).
class BackendConfig {
  BackendConfig._();

  static const int fallbackPort = 8000;

  static bool _isPlaceholderUrl(String? url) {
    if (url == null || url.trim().isEmpty) return true;
    final u = url.toLowerCase();
    return u.contains('your-service') ||
        u.contains('your-project') ||
        u.contains('example.com') ||
        u.contains('placeholder');
  }

  static String get modelBackendUrl {
    if (kDebugMode) {
      final local = _firstNonEmpty([dotenv.env['LOCAL_MODEL_BACKEND_URL']]);
      return _normalizeUrl(local ?? 'http://127.0.0.1:$fallbackPort');
    }

    final remote = _firstNonEmpty([
      dotenv.env['RENDER_MODEL_BACKEND_URL'],
      dotenv.env['MODEL_BACKEND_URL'],
    ]);
    if (remote != null && !_isPlaceholderUrl(remote)) {
      return _normalizeUrl(remote);
    }

    // Release APK + local Python backend on PC (same Wi‑Fi or adb reverse)
    final releaseLocal = _firstNonEmpty([
      dotenv.env['RELEASE_LOCAL_BACKEND_URL'],
      dotenv.env['LOCAL_MODEL_BACKEND_URL'],
    ]);
    return _normalizeUrl(
      releaseLocal ?? 'http://127.0.0.1:$fallbackPort',
    );
  }

  static int get defaultPort {
    final uri = Uri.tryParse(modelBackendUrl);
    final port = uri?.port;
    if (port != null && port > 0) return port;
    return fallbackPort;
  }

  /// Android: emulator maps localhost → 10.0.2.2 (debug only).
  static List<String> get modelBackendUrlCandidates {
    final primary = modelBackendUrl;
    if (primary.isEmpty) return [];
    if (kIsWeb || !Platform.isAndroid) return [primary];

    final uri = Uri.tryParse(primary);
    if (uri == null) return [primary];

    final host = uri.host.toLowerCase();
    final isLoopback = host == '127.0.0.1' || host == 'localhost';

    if (!isLoopback) return [primary];

    // Debug emulator: try 10.0.2.2 then 127.0.0.1 (adb reverse on physical)
    if (kDebugMode) {
      final emulatorUrl = _normalizeUrl(
        uri.replace(host: emulatorHost).toString(),
      );
      if (emulatorUrl != primary) return [emulatorUrl, primary];
    }

    return [primary];
  }

  static const String emulatorHost = '10.0.2.2';

  static bool get isConfigured => modelBackendUrl.isNotEmpty;

  static bool get isLocalBackend {
    if (kDebugMode) return true;
    final remote = _firstNonEmpty([
      dotenv.env['RENDER_MODEL_BACKEND_URL'],
      dotenv.env['MODEL_BACKEND_URL'],
    ]);
    if (remote != null && !_isPlaceholderUrl(remote)) return false;
    return true;
  }

  static Duration get healthTimeout => const Duration(seconds: 10);

  static Duration get healthRetryDelay => const Duration(seconds: 2);

  static int get healthRetryAttempts => 3;

  static Duration get analyzeTimeout => const Duration(minutes: 2);

  static String get backendStartCommand => '.\\scripts\\start_backend.ps1';

  static String get backendUvicornCommand =>
      'python -m uvicorn python_backend.main:app --host 0.0.0.0 --port $defaultPort';

  static String get platformHint {
    if (!isLocalBackend) {
      return 'Release uses Render. Check internet and RENDER_MODEL_BACKEND_URL in .env.';
    }
    if (kIsWeb) {
      return 'Run the Python backend on this PC, then try again.';
    }
    if (!kIsWeb && Platform.isAndroid) {
      if (kDebugMode) {
        return 'Emulator: $emulatorHost. Physical USB: adb reverse tcp:$defaultPort tcp:$defaultPort. '
            'Wi‑Fi: set RELEASE_LOCAL_BACKEND_URL to PC IP (e.g. http://192.168.1.42:$defaultPort).';
      }
      return 'Start backend on PC ($backendUvicornCommand). Phone on same Wi‑Fi needs '
          'RELEASE_LOCAL_BACKEND_URL=http://YOUR_PC_IP:$defaultPort in .env before building APK. '
          'USB: adb reverse tcp:$defaultPort tcp:$defaultPort and use 127.0.0.1.';
    }
    if (!kIsWeb && Platform.isWindows) {
      return 'Start backend: $backendUvicornCommand';
    }
    return 'Start the Python backend on your PC, then try again.';
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  static String _normalizeUrl(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
}
