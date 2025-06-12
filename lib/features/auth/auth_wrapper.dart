import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:elythra_music/features/auth/auth_cubit.dart';
import 'package:elythra_music/features/auth/hybrid_auth_screen.dart';
import 'package:elythra_music/features/auth/webview_auth_service.dart';
import 'package:elythra_music/features/auth/cross_platform_sync_service.dart';

/// Authentication wrapper that determines which screen to show
class AuthWrapper extends StatefulWidget {
  final Widget homeScreen;
  
  const AuthWrapper({
    super.key,
    required this.homeScreen,
  });

  @override
  State<AuthWrapper> createState() => AuthWrapperStateState();
}

class AuthWrapperStateState extends State<AuthWrapper> {
  final WebViewAuthService _webViewAuth = WebViewAuthService();
  final CrossPlatformSyncService _syncService = CrossPlatformSyncService();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        return StreamBuilder<WebViewAuthState>(
          stream: _webViewAuth.authStateChanges,
          builder: (context, webViewSnapshot) {
            return StreamBuilder<SyncStatus>(
              stream: _syncService.syncStatusStream,
              builder: (context, syncSnapshot) {
                // Show loading if any auth is in progress
                if (authState is AuthLoading) {
                  return const _LoadingScreen(message: 'Signing in...');
                }

                // Show sync status if syncing
                if (syncSnapshot.hasData && syncSnapshot.data!.isActive) {
                  return const _LoadingScreen(message: 'Syncing your data...');
                }

                // Check if user is authenticated with either method
                final isFirebaseAuth = authState is AuthAuthenticated;
                final isWebViewAuth = webViewSnapshot.hasData && 
                    webViewSnapshot.data!.isAuthenticated;

                if (isFirebaseAuth || isWebViewAuth) {
                  return _AuthenticatedWrapper(
                    homeScreen: widget.homeScreen,
                    authState: authState,
                    webViewState: webViewSnapshot.data,
                    syncStatus: syncSnapshot.data,
                  );
                }

                // Show authentication screen
                return const HybridAuthScreen();
              },
            );
          },
        );
      },
    );
  }
}

/// Wrapper for authenticated users showing sync status
class _AuthenticatedWrapper extends StatelessWidget {
  final Widget homeScreen;
  final AuthState authState;
  final WebViewAuthState? webViewState;
  final SyncStatus? syncStatus;

  const _AuthenticatedWrapper({
    required this.homeScreen,
    required this.authState,
    this.webViewState,
    this.syncStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main home screen
          homeScreen,
          
          // Sync status overlay
          if (syncStatus != null && syncStatus!.isActive)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: _SyncStatusBanner(syncStatus: syncStatus!),
            ),
        ],
      ),
    );
  }
}

/// Loading screen with message
class _LoadingScreen extends StatelessWidget {
  final String message;

  const _LoadingScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.8),
              Theme.of(context).primaryColor.withValues(alpha: 0.6),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.music_note,
                  size: 40,
                  color: Colors.deepPurple,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              
              const SizedBox(height: 16),
              
              // Loading message
              Text(
                message,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sync status banner
class _SyncStatusBanner extends StatelessWidget {
  final SyncStatus syncStatus;

  const _SyncStatusBanner({required this.syncStatus});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    IconData icon;
    String message;

    if (syncStatus.isActive) {
      backgroundColor = Colors.blue;
      icon = Icons.sync;
      message = 'Syncing your data...';
    } else if (syncStatus.isCompleted) {
      backgroundColor = Colors.green;
      icon = Icons.check_circle;
      message = 'Sync completed successfully';
    } else if (syncStatus.isFailed) {
      backgroundColor = Colors.red;
      icon = Icons.error;
      message = 'Sync failed: ${syncStatus.error}';
    } else {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (syncStatus.isActive)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else
            Icon(icon, color: Colors.white, size: 16),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          if (!syncStatus.isActive)
            GestureDetector(
              onTap: () {
                // Auto-hide after 3 seconds for completed/failed states
              },
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }
}

/// Authentication status widget for debugging
class AuthStatusWidget extends StatelessWidget {
  const AuthStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        return StreamBuilder<WebViewAuthState>(
          stream: WebViewAuthService().authStateChanges,
          builder: (context, webViewSnapshot) {
            return StreamBuilder<SyncStatus>(
              stream: CrossPlatformSyncService().syncStatusStream,
              builder: (context, syncSnapshot) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Auth Status (Debug)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Firebase: ${authState.runtimeType}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      Text(
                        'WebView: ${webViewSnapshot.hasData ? (webViewSnapshot.data!.isAuthenticated ? 'Authenticated' : 'Not authenticated') : 'Loading...'}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      Text(
                        'Sync: ${syncSnapshot.hasData ? syncSnapshot.data!.state.name : 'Unknown'}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}