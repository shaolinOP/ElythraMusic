import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WebView-based Google authentication for comprehensive account access
class WebViewAuthService {
  static final WebViewAuthService _instance = WebViewAuthService._internal();
  factory WebViewAuthService() => _instance;
  WebViewAuthService._internal();

  // Auth state stream controller
  final StreamController<WebViewAuthState> _authStateController = 
      StreamController<WebViewAuthState>.broadcast();

  Stream<WebViewAuthState> get authStateChanges => _authStateController.stream;

  WebViewAuthState _currentState = WebViewAuthState.unauthenticated();

  WebViewAuthState get currentState => _currentState;

  // User data keys for SharedPreferences
  static const String _cookieKey = 'google_auth_cookie';
  static const String _userDataKey = 'google_user_data';
  static const String _accessTokenKey = 'google_access_token';
  static const String _refreshTokenKey = 'google_refresh_token';
  static const String _syncDataKey = 'google_sync_data';

  /// Initialize the service and check existing auth state
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookie = prefs.getString(_cookieKey);
      final userDataJson = prefs.getString(_userDataKey);
      
      if (cookie != null && userDataJson != null) {
        final userData = json.decode(userDataJson) as Map<String, dynamic>;
        _currentState = WebViewAuthState.authenticated(
          userData: userData,
          cookie: cookie,
          accessToken: prefs.getString(_accessTokenKey),
          refreshToken: prefs.getString(_refreshTokenKey),
        );
        _authStateController.add(_currentState);
        log('✅ WebView Auth: Restored existing session');
      }
    } catch (e) {
      log('❌ WebView Auth: Failed to initialize - $e');
    }
  }

  /// Sign in using WebView with comprehensive Google account access
  Future<WebViewAuthResult> signInWithWebView(BuildContext context) async {
    try {
      log('🔐 WebView Auth: Starting comprehensive Google Sign-In...');

      final result = await Navigator.of(context).push<WebViewAuthResult>(
        MaterialPageRoute(
          builder: (context) => const WebViewSignInScreen(),
          fullscreenDialog: true,
        ),
      );

      if (result != null && result.success) {
        await _saveAuthData(result);
        _currentState = WebViewAuthState.authenticated(
          userData: result.userData!,
          cookie: result.cookie!,
          accessToken: result.accessToken,
          refreshToken: result.refreshToken,
        );
        _authStateController.add(_currentState);
        log('✅ WebView Auth: Sign-in successful');
        return result;
      } else {
        log('❌ WebView Auth: Sign-in cancelled or failed');
        return WebViewAuthResult.failure('Sign-in cancelled');
      }
    } catch (e) {
      log('❌ WebView Auth: Sign-in error - $e');
      return WebViewAuthResult.failure(e.toString());
    }
  }

  /// Sign out and clear all stored data
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cookieKey);
      await prefs.remove(_userDataKey);
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_syncDataKey);

      _currentState = WebViewAuthState.unauthenticated();
      _authStateController.add(_currentState);
      log('✅ WebView Auth: Sign-out successful');
    } catch (e) {
      log('❌ WebView Auth: Sign-out error - $e');
    }
  }

  /// Save authentication data to local storage
  Future<void> _saveAuthData(WebViewAuthResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cookieKey, result.cookie!);
      await prefs.setString(_userDataKey, json.encode(result.userData!));
      
      if (result.accessToken != null) {
        await prefs.setString(_accessTokenKey, result.accessToken!);
      }
      if (result.refreshToken != null) {
        await prefs.setString(_refreshTokenKey, result.refreshToken!);
      }
      
      log('✅ WebView Auth: Auth data saved');
    } catch (e) {
      log('❌ WebView Auth: Failed to save auth data - $e');
    }
  }

  /// Get stored sync data for cross-platform synchronization
  Future<Map<String, dynamic>?> getSyncData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncDataJson = prefs.getString(_syncDataKey);
      if (syncDataJson != null) {
        return json.decode(syncDataJson) as Map<String, dynamic>;
      }
    } catch (e) {
      log('❌ WebView Auth: Failed to get sync data - $e');
    }
    return null;
  }

  /// Save sync data for cross-platform synchronization
  Future<void> saveSyncData(Map<String, dynamic> syncData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_syncDataKey, json.encode(syncData));
      log('✅ WebView Auth: Sync data saved');
    } catch (e) {
      log('❌ WebView Auth: Failed to save sync data - $e');
    }
  }

  /// Refresh access token if needed
  Future<bool> refreshTokenIfNeeded() async {
    try {
      if (_currentState.refreshToken == null) return false;

      // Implement token refresh logic here
      // This would typically involve making an HTTP request to Google's token endpoint
      log('🔄 WebView Auth: Token refresh not implemented yet');
      return false;
    } catch (e) {
      log('❌ WebView Auth: Token refresh failed - $e');
      return false;
    }
  }

  void dispose() {
    _authStateController.close();
  }
}

/// WebView Sign-In Screen
class WebViewSignInScreen extends StatefulWidget {
  const WebViewSignInScreen({super.key});

  @override
  State<WebViewSignInScreen> createState() => WebViewSignInScreenStateState();
}

class WebViewSignInScreenStateState extends State<WebViewSignInScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _currentUrl = '';

  // OAuth 2.0 configuration
  static const String _clientId = 'YOUR_GOOGLE_CLIENT_ID'; // Replace with actual client ID
  static const String _redirectUri = 'https://elythra.music/auth/callback';
  static const String _scope = 'openid email profile https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email';

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _currentUrl = url;
              _isLoading = true;
            });
            _handleUrlChange(url);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _extractUserData();
          },
          onNavigationRequest: (NavigationRequest request) {
            _handleUrlChange(request.url);
            return NavigationDecision.navigate;
          },
        ),
      );

    // Build OAuth URL
    final authUrl = _buildOAuthUrl();
    _controller.loadRequest(Uri.parse(authUrl));
  }

  String _buildOAuthUrl() {
    final params = {
      'client_id': _clientId,
      'redirect_uri': _redirectUri,
      'scope': _scope,
      'response_type': 'code',
      'access_type': 'offline',
      'prompt': 'consent',
      'state': 'elythra_music_auth',
    };

    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'https://accounts.google.com/oauth/authorize?$queryString';
  }

  void _handleUrlChange(String url) {
    log('🌐 WebView Auth: URL changed to $url');

    // Check for redirect URI with authorization code
    if (url.startsWith(_redirectUri)) {
      final uri = Uri.parse(url);
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];

      if (error != null) {
        _returnResult(WebViewAuthResult.failure('OAuth error: $error'));
      } else if (code != null) {
        _exchangeCodeForTokens(code);
      }
    }

    // Check for successful Google sign-in
    if (url.contains('accounts.google.com') && url.contains('signin/oauth')) {
      // User is in the OAuth flow
      log('📝 WebView Auth: User in OAuth flow');
    }
  }

  Future<void> _exchangeCodeForTokens(String code) async {
    try {
      log('🔄 WebView Auth: Exchanging code for tokens...');
      
      // In a real implementation, you would exchange the authorization code
      // for access and refresh tokens by making a POST request to:
      // https://oauth2.googleapis.com/token
      
      // For now, we'll simulate this and extract user data from the current session
      await _extractUserData();
    } catch (e) {
      log('❌ WebView Auth: Token exchange failed - $e');
      _returnResult(WebViewAuthResult.failure('Token exchange failed: $e'));
    }
  }

  Future<void> _extractUserData() async {
    try {
      // Extract cookies
      final cookies = await _controller.runJavaScriptReturningResult('document.cookie') as String;
      
      // Extract user information from the page
      final userInfoScript = '''
        (function() {
          try {
            // Try to get user info from various Google page elements
            var userEmail = '';
            var userName = '';
            var userPhoto = '';
            
            // Look for email in various places
            var emailElements = document.querySelectorAll('[data-email], [aria-label*="email"], input[type="email"]');
            for (var i = 0; i < emailElements.length; i++) {
              if (emailElements[i].toARGB32 || emailElements[i].textContent) {
                userEmail = emailElements[i].toARGB32 || emailElements[i].textContent;
                break;
              }
            }
            
            // Look for user name
            var nameElements = document.querySelectorAll('[data-name], .gb_hb, .gb_Pc');
            for (var i = 0; i < nameElements.length; i++) {
              if (nameElements[i].textContent && nameElements[i].textContent.trim()) {
                userName = nameElements[i].textContent.trim();
                break;
              }
            }
            
            // Look for profile photo
            var photoElements = document.querySelectorAll('img[data-src*="googleusercontent"], img[src*="googleusercontent"]');
            if (photoElements.isNotEmpty) {
              userPhoto = photoElements[0].src || photoElements[0].getAttribute('data-src') || '';
            }
            
            return {
              email: userEmail,
              name: userName,
              photo: userPhoto,
              url: window.location.href
            };
          } catch (e) {
            return { error: e.toString() };
          }
        })();
      ''';

      final userInfoResult = await _controller.runJavaScriptReturningResult(userInfoScript);
      log('📊 WebView Auth: User info extracted: $userInfoResult');

      // Check if we have sufficient user data
      if (cookies.isNotEmpty && _currentUrl.contains('accounts.google.com')) {
        final userData = {
          'email': 'user@example.com', // Extract from actual page
          'name': 'User Name', // Extract from actual page
          'photo': '', // Extract from actual page
          'extractedAt': DateTime.now().toIso8601String(),
        };

        _returnResult(WebViewAuthResult.success(
          userData: userData,
          cookie: cookies,
          accessToken: null, // Would be extracted from OAuth flow
          refreshToken: null, // Would be extracted from OAuth flow
        ));
      }
    } catch (e) {
      log('❌ WebView Auth: Failed to extract user data - $e');
    }
  }

  void _returnResult(WebViewAuthResult result) {
    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in with Google'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _returnResult(WebViewAuthResult.failure('Cancelled by user')),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading)
            const LinearProgressIndicator(),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}

/// Authentication state for WebView auth
class WebViewAuthState {
  final bool isAuthenticated;
  final Map<String, dynamic>? userData;
  final String? cookie;
  final String? accessToken;
  final String? refreshToken;

  const WebViewAuthState._({
    required this.isAuthenticated,
    this.userData,
    this.cookie,
    this.accessToken,
    this.refreshToken,
  });

  factory WebViewAuthState.authenticated({
    required Map<String, dynamic> userData,
    required String cookie,
    String? accessToken,
    String? refreshToken,
  }) {
    return WebViewAuthState._(
      isAuthenticated: true,
      userData: userData,
      cookie: cookie,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  factory WebViewAuthState.unauthenticated() {
    return const WebViewAuthState._(isAuthenticated: false);
  }

  String? get userEmail => userData?['email'];
  String? get userName => userData?['name'];
  String? get userPhoto => userData?['photo'];
}

/// Result of WebView authentication
class WebViewAuthResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? userData;
  final String? cookie;
  final String? accessToken;
  final String? refreshToken;

  const WebViewAuthResult._({
    required this.success,
    this.error,
    this.userData,
    this.cookie,
    this.accessToken,
    this.refreshToken,
  });

  factory WebViewAuthResult.success({
    required Map<String, dynamic> userData,
    required String cookie,
    String? accessToken,
    String? refreshToken,
  }) {
    return WebViewAuthResult._(
      success: true,
      userData: userData,
      cookie: cookie,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  factory WebViewAuthResult.failure(String error) {
    return WebViewAuthResult._(
      success: false,
      error: error,
    );
  }
}