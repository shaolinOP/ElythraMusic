import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:elythra_music/features/auth/auth_cubit.dart';
import 'package:elythra_music/features/auth/webview_auth_service.dart';

/// Hybrid authentication screen offering both Firebase and WebView options
class HybridAuthScreen extends StatefulWidget {
  const HybridAuthScreen({super.key});

  @override
  State<HybridAuthScreen> createState() => HybridAuthScreenStateState();
}

class HybridAuthScreenStateState extends State<HybridAuthScreen> {
  bool _isWebViewLoading = false;
  final WebViewAuthService _webViewAuth = WebViewAuthService();

  @override
  void initState() {
    super.initState();
    _webViewAuth.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Text(state.message)),
                  ],
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AuthLoading || _isWebViewLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Container(
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
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    
                    // App Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
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
                        size: 60,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // App Name
                    Text(
                      'Elythra Music',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    Text(
                      'Your music, synced everywhere',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 64),
                    
                    // Authentication Options
                    _buildAuthOptions(context),
                    
                    const SizedBox(height: 32),
                    
                    // Features list
                    _buildFeaturesList(context),
                    
                    const Spacer(flex: 2),
                    
                    // Skip button
                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
                      child: Text(
                        'Skip for now',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAuthOptions(BuildContext context) {
    return Column(
      children: [
        // Standard Firebase Google Sign-In
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => context.read<AuthCubit>().signInWithGoogle(),
            icon: Image.asset(
              'assets/icons/google_logo.png',
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.login, color: Colors.white),
            ),
            label: const Text(
              'Quick Sign In with Google',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Divider with "OR"
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Colors.white.withValues(alpha: 0.3),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: Colors.white.withValues(alpha: 0.3),
                thickness: 1,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Advanced WebView Sign-In
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: _signInWithWebView,
            icon: const Icon(Icons.web, color: Colors.white),
            label: const Text(
              'Advanced Sync Sign In',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Advanced option description
        Text(
          'For comprehensive account sync across all platforms',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeaturesList(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Sign in to unlock:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildFeatureItem('🎵 Sync playlists across all devices'),
          _buildFeatureItem('💾 Backup your music library'),
          _buildFeatureItem('🎯 Personalized recommendations'),
          _buildFeatureItem('📝 Synchronized lyrics'),
          _buildFeatureItem('📊 Listening history and analytics'),
          _buildFeatureItem('☁️ Cloud storage for favorites'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.white.withValues(alpha: 0.8),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithWebView() async {
    setState(() {
      _isWebViewLoading = true;
    });

    try {
      final result = await _webViewAuth.signInWithWebView(context);
      
      if (result.success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Advanced sync enabled for ${result.userData?['name'] ?? 'your account'}!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Navigate to home
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (result.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Advanced sign in failed: ${result.error}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Sign in error: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isWebViewLoading = false;
        });
      }
    }
  }
}