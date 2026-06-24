import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

/// AuthProvider — Supabase Auth wrapper
class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;
  bool _emailConfirmationPending = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get emailConfirmationPending => _emailConfirmationPending;

  SupabaseClient get _auth => Supabase.instance.client;

  /// Call once from main.dart after Supabase.initialize()
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      _auth.auth.onAuthStateChange.listen((event) {
        if (event.event == AuthChangeEvent.signedOut) {
          _currentUser = null;
          _isLoading = false;
          notifyListeners();
          return;
        }

        final session = event.session;
        if (session == null) {
          _currentUser = null;
        } else if (event.event == AuthChangeEvent.signedIn ||
            event.event == AuthChangeEvent.tokenRefreshed ||
            event.event == AuthChangeEvent.userUpdated) {
          _currentUser = _userFromSupabaseUser(session.user);
        }
        _isLoading = false;
        notifyListeners();
      });

      final session = _auth.auth.currentSession;
      if (session != null) {
        final valid = await _validateSessionWithServer();
        if (valid) {
          debugPrint(
            '✅ AuthProvider: valid session for ${_currentUser?.email}',
          );
        } else {
          debugPrint(
            '⚠️ AuthProvider: session invalid — user removed from Supabase',
          );
          await _forceSignOut();
        }
      }
    } catch (e) {
      debugPrint('⚠️ AuthProvider.initialize error: $e');
      await _forceSignOut();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Re-check with Supabase that the current user still exists (call on app resume).
  Future<bool> refreshSessionValidity() async {
    if (_auth.auth.currentSession == null) {
      _currentUser = null;
      notifyListeners();
      return false;
    }
    final valid = await _validateSessionWithServer();
    if (!valid) {
      await _forceSignOut();
      return false;
    }
    notifyListeners();
    return true;
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _emailConfirmationPending = false;
    notifyListeners();

    if (!await _hasNetwork()) {
      _errorMessage =
          'No internet connection. Turn on Wi‑Fi or mobile data and try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final res = await _auth.auth.signUp(
        email: email,
        password: password,
        data: name != null ? {'name': name} : null,
      );

      debugPrint('✅ signUp response: user=${res.user?.email}, '
          'hasSession=${res.session != null}');

      if (res.user != null) {
        if (res.session == null) {
          _emailConfirmationPending = true;
          debugPrint('📧 Email confirmation required for ${res.user!.email}');
        } else {
          _currentUser = _userFromSupabaseUser(res.user!);
          debugPrint('✅ AuthProvider: signed up and logged in as ${_currentUser?.email}');
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage =
          'This email may already be registered. Try signing in, or check '
          'your inbox for a confirmation link.';
      debugPrint('⚠️ signUp: user is null (possible duplicate/unconfirmed email)');
      _isLoading = false;
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      _errorMessage = _authExceptionMessage(e);
      debugPrint('⚠️ signUp AuthException [${e.statusCode}]: ${e.message}');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      debugPrint('⚠️ signUp error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (!await _hasNetwork()) {
      _errorMessage =
          'No internet connection. Turn on Wi‑Fi or mobile data and try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final res = await _auth.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user != null) {
        final valid = await _validateSessionWithServer();
        if (!valid) {
          _errorMessage =
              'This account is no longer active. Contact support or sign up again.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        debugPrint('✅ AuthProvider: signed in as ${_currentUser?.email}');
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = 'Login failed. Please check your credentials.';
      debugPrint('⚠️ signIn: user is null');
      _isLoading = false;
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      _errorMessage = _authExceptionMessage(e);
      debugPrint('⚠️ signIn AuthException [${e.statusCode}]: ${e.message}');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      debugPrint('⚠️ signIn error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.auth.signOut();
      _currentUser = null;
      debugPrint('✅ AuthProvider: signed out');
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('⚠️ signOut error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _auth.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      debugPrint('⚠️ resetPassword error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({String? name, String? farmName}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name.trim();
      if (farmName != null) data['farm_name'] = farmName.trim();

      await _auth.auth.updateUser(UserAttributes(data: data));

      final user = _auth.auth.currentUser;
      if (user != null) {
        _currentUser = _userFromSupabaseUser(user);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Confirms the JWT user still exists on Supabase (not deleted in dashboard).
  Future<bool> _validateSessionWithServer() async {
    try {
      final res = await _auth.auth.getUser();
      final user = res.user;
      if (user == null) return false;
      _currentUser = _userFromSupabaseUser(user);
      return true;
    } on AuthException catch (e) {
      debugPrint('⚠️ AuthProvider: getUser failed — ${e.message}');
      return false;
    } catch (e) {
      debugPrint('⚠️ AuthProvider: session validation error — $e');
      return false;
    }
  }

  Future<void> _forceSignOut() async {
    _currentUser = null;
    try {
      await _auth.auth.signOut();
    } catch (_) {}
  }

  UserModel _userFromSupabaseUser(User user) => UserModel(
        id: user.id,
        email: user.email ?? '',
        name: user.userMetadata?['name'] as String?,
        farmName: user.userMetadata?['farm_name'] as String?,
        createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
      );

  Future<bool> _hasNetwork() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (_) {
      return true;
    }
  }

  String _authExceptionMessage(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('no address associated with hostname') ||
        msg.contains('network is unreachable') ||
        msg.contains('connection refused') ||
        msg.contains('connection timed out') ||
        msg.contains('clientexception')) {
      return 'Cannot reach the server. Check your internet connection '
          'and try again.';
    }
    if (msg.contains('user already registered') ||
        msg.contains('already been registered') ||
        msg.contains('already exists')) {
      return 'An account with this email already exists. Please sign in instead.';
    }
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid email or password') ||
        msg.contains('wrong password') ||
        msg.contains('user not found')) {
      return 'Incorrect email or password, or this account was removed.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Your email is not confirmed. Check your inbox and click the confirmation link.';
    }
    if (msg.contains('password') &&
        (msg.contains('characters') || msg.contains('too short') || msg.contains('weak'))) {
      return 'Password is too weak. Use at least 8 characters with uppercase, lowercase, and a number.';
    }
    if (msg.contains('invalid email') || msg.contains('email format')) {
      return 'Invalid email address format.';
    }
    if (msg.contains('signups not allowed') ||
        msg.contains('signup disabled') ||
        msg.contains('not enabled')) {
      return 'Sign-ups are currently disabled. Please contact support.';
    }
    if (msg.contains('rate limit') || msg.contains('too many requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return e.message;
  }

  String _friendlyError(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('no address associated with hostname') ||
        msg.contains('connection refused') ||
        msg.contains('network is unreachable')) {
      return 'Cannot reach the server. Check your internet connection '
          'and try again.';
    }
    if (msg.contains('timeoutexception')) {
      return 'Request timed out. Try again.';
    }
    return e.toString().replaceAll('Exception: ', '');
  }
}
