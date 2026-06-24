import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config/backend_config.dart';
import '../data/repositories/cattle_analysis_repository_impl.dart';
import '../services/http_model_service.dart';

enum BackendConnectionStatus { idle, checking, connected, disconnected }

/// Tracks Python model backend reachability (checked after login or video analysis).
class BackendConnectionProvider extends ChangeNotifier {
  BackendConnectionStatus _status = BackendConnectionStatus.idle;
  String? _errorMessage;
  DateTime? _lastVerifiedAt;
  Timer? _watchTimer;

  BackendConnectionStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _status == BackendConnectionStatus.connected;
  bool get hasBeenChecked => _status != BackendConnectionStatus.idle;
  DateTime? get lastVerifiedAt => _lastVerifiedAt;

  String get backendUrl => HttpModelService.instance.isReady
      ? HttpModelService.instance.baseUrl
      : (BackendConfig.modelBackendUrlCandidates.isNotEmpty
          ? BackendConfig.modelBackendUrlCandidates.first
          : BackendConfig.modelBackendUrl);

  /// Health-check the backend (after login/signup or user-initiated refresh).
  Future<void> check({bool userInitiated = false}) async {
    if (userInitiated || _status != BackendConnectionStatus.connected) {
      _status = BackendConnectionStatus.checking;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      HttpModelService.instance.reset();
      await CattleAnalysisRepositoryImpl.instance.ensureInitialized();
      _markConnected();
      startMonitoring();
      debugPrint('BackendConnectionProvider: connected → $backendUrl');
    } catch (e) {
      _markDisconnected(_formatError(e));
      debugPrint('BackendConnectionProvider: offline — $_errorMessage');
    }

    notifyListeners();
  }

  /// Lightweight background ping while the app is in use (only after first check).
  void startMonitoring() {
    if (_status == BackendConnectionStatus.idle) return;
    _watchTimer?.cancel();
    _watchTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      unawaited(_verifySilently());
    });
  }

  void stopMonitoring() {
    _watchTimer?.cancel();
    _watchTimer = null;
  }

  Future<void> _verifySilently() async {
    if (_status == BackendConnectionStatus.checking ||
        _status == BackendConnectionStatus.idle) {
      return;
    }

    try {
      final resp = await http
          .get(Uri.parse('$backendUrl/health'))
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode != 200) {
        throw StateError('HTTP ${resp.statusCode}');
      }

      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      if (body['status'] != 'ok') {
        throw StateError('models loading');
      }

      _lastVerifiedAt = DateTime.now();
      if (_status != BackendConnectionStatus.connected) {
        _status = BackendConnectionStatus.connected;
        _errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      if (_status == BackendConnectionStatus.connected) {
        HttpModelService.instance.reset();
        _markDisconnected('Connection lost — AI server is not responding.');
        notifyListeners();
      }
    }
  }

  void _markConnected() {
    _status = BackendConnectionStatus.connected;
    _errorMessage = null;
    _lastVerifiedAt = DateTime.now();
  }

  void _markDisconnected(String message) {
    _status = BackendConnectionStatus.disconnected;
    _errorMessage = message;
  }

  String _formatError(Object e) {
    final msg = e.toString().replaceFirst('Exception: ', '');
    if (msg.contains('AnalysisException:')) {
      return msg.replaceFirst('AnalysisException:', '').trim();
    }
    return msg;
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
