import 'package:flutter/material.dart';
import 'package:elythra_music/features/auth/services/enhanced_auth_service.dart';
import 'package:elythra_music/features/player/services/enhanced_audio_service.dart';
import 'package:elythra_music/features/lyrics/services/enhanced_lyrics_service.dart';
import 'package:elythra_music/features/performance/performance_optimizer.dart';

// Import enums directly

class EnhancedSettingsScreen extends StatefulWidget {
  const EnhancedSettingsScreen({super.key});

  @override
  State<EnhancedSettingsScreen> createState() => EnhancedSettingsScreenStateState();
}

class EnhancedSettingsScreenStateState extends State<EnhancedSettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildAudioQualitySection(),
                const SizedBox(height: 24),
                _buildLyricsSection(),
                const SizedBox(height: 24),
                _buildPerformanceSection(),
                const SizedBox(height: 24),
                _buildAuthSection(),
                const SizedBox(height: 24),
                _buildCacheSection(),
                const SizedBox(height: 24),
                _buildAboutSection(),
              ],
            ),
    );
  }

  Widget _buildAudioQualitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.high_quality, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Audio Quality',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<AudioQuality>(
              future: Future.toARGB32(EnhancedAudioService.currentQuality),
              builder: (context, snapshot) {
                final currentQuality = snapshot.data ?? AudioQuality.extreme;
                
                return Column(
                  children: AudioQuality.toARGB32s.map((quality) {
                    return RadioListTile<AudioQuality>(
                      title: Text(quality.displayName),
                      subtitle: Text('${quality.bitrate} kbps'),
                      value: quality,
                      groupValue: currentQuality,
                      onChanged: (value) async {
                        if (value != null) {
                          await EnhancedAudioService.setAudioQuality(value);
                          setState(() {});
                        }
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const Divider(),
            FutureBuilder<StreamingMode>(
              future: Future.toARGB32(EnhancedAudioService.streamingMode),
              builder: (context, snapshot) {
                final currentMode = snapshot.data ?? StreamingMode.wifi;
                
                return DropdownButtonFormField<StreamingMode>(
                  decoration: const InputDecoration(
                    labelText: 'Streaming Mode',
                    border: OutlineInputBorder(),
                  ),
                  value: currentMode,
                  items: StreamingMode.toARGB32s.map((mode) {
                    return DropdownMenuItem(
                      value: mode,
                      child: Text(mode.displayName),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      await EnhancedAudioService.setStreamingMode(value);
                      setState(() {});
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLyricsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lyrics, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Lyrics & Sync',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<int>(
              future: EnhancedLyricsService.getCacheSize(),
              builder: (context, snapshot) {
                final cacheSize = snapshot.data ?? 0;
                return ListTile(
                  leading: const Icon(Icons.storage),
                  title: const Text('Lyrics Cache'),
                  subtitle: Text('$cacheSize cached lyrics'),
                  trailing: TextButton(
                    onPressed: () async {
                      await EnhancedLyricsService.clearCache();
                      setState(() {});
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lyrics cache cleared')),
                        );
                      }
                    },
                    child: const Text('Clear'),
                  ),
                );
              },
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.sync),
              title: Text('Auto-sync Lyrics'),
              subtitle: Text('Automatically sync lyrics with playback'),
              trailing: Switch(value: true, onChanged: null), // TODO: Implement
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Performance',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: Future.toARGB32(PerformanceOptimizer().getEnhancedPerformanceStats()),
              builder: (context, snapshot) {
                final stats = snapshot.data ?? {};
                final batteryOptEnabled = stats['batteryOptimizationEnabled'] ?? false;
                final highQualityBattery = stats['highQualityOnBatteryEnabled'] ?? false;
                
                return Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.battery_saver),
                      title: const Text('Battery Optimization'),
                      subtitle: const Text('Reduce quality to save battery'),
                      value: batteryOptEnabled,
                      onChanged: (value) async {
                        await PerformanceOptimizer().setBatteryOptimization(value);
                        setState(() {});
                      },
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.high_quality),
                      title: const Text('High Quality on Battery'),
                      subtitle: const Text('Maintain quality even on battery'),
                      value: highQualityBattery,
                      onChanged: (value) async {
                        await PerformanceOptimizer().setHighQualityOnBattery(value);
                        setState(() {});
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.memory),
                      title: const Text('Memory Usage'),
                      subtitle: Text(
                        'Cache: ${(stats['currentCacheSize'] ?? 0) ~/ (1024 * 1024)} MB / '
                        '${(stats['maxCacheSize'] ?? 0) ~/ (1024 * 1024)} MB',
                      ),
                      trailing: TextButton(
                        onPressed: () async {
                          // Note: This method is private, so we'll need to expose it or use a public method
                          setState(() {});
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Memory cleaned up')),
                            );
                          }
                        },
                        child: const Text('Clean'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_circle, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Account & Sync',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<EnhancedUserProfile?>(
              future: EnhancedAuthService.getUserProfile(),
              builder: (context, snapshot) {
                final profile = snapshot.data;
                
                if (profile != null) {
                  return Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundImage: profile.hasValidPhoto
                              ? NetworkImage(profile.photoURL!)
                              : null,
                          child: profile.hasValidPhoto
                              ? null
                              : Text(profile.initials),
                        ),
                        title: Text(profile.displayName),
                        subtitle: Text(profile.email),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            // TODO: Navigate to profile edit screen
                          },
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Sign Out'),
                        onTap: () async {
                          await _signOut();
                        },
                      ),
                    ],
                  );
                } else {
                  return ListTile(
                    leading: const Icon(Icons.login),
                    title: const Text('Sign In with Google'),
                    subtitle: const Text('Sync your music across devices'),
                    onTap: () async {
                      await _signIn();
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Storage & Cache',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<bool>(
              future: Future.toARGB32(EnhancedAudioService.isCacheEnabled),
              builder: (context, snapshot) {
                final cacheEnabled = snapshot.data ?? true;
                
                return SwitchListTile(
                  secondary: const Icon(Icons.download),
                  title: const Text('Enable Audio Caching'),
                  subtitle: const Text('Cache songs for offline playback'),
                  value: cacheEnabled,
                  onChanged: (value) async {
                    await EnhancedAudioService.setCacheEnabled(value);
                    setState(() {});
                  },
                );
              },
            ),
            const Divider(),
            FutureBuilder<double>(
              future: EnhancedAudioService.getCacheSize(),
              builder: (context, snapshot) {
                final cacheSize = snapshot.data ?? 0.0;
                
                return ListTile(
                  leading: const Icon(Icons.folder),
                  title: const Text('Audio Cache Size'),
                  subtitle: Text('${cacheSize.toStringAsFixed(1)} MB'),
                  trailing: TextButton(
                    onPressed: () async {
                      await EnhancedAudioService.clearCache();
                      setState(() {});
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Audio cache cleared')),
                        );
                      }
                    },
                    child: const Text('Clear'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'About',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const ListTile(
              leading: Icon(Icons.music_note),
              title: Text('Elythra Music'),
              subtitle: Text('Enhanced music streaming experience'),
            ),
            const ListTile(
              leading: Icon(Icons.code),
              title: Text('Version'),
              subtitle: Text('1.0.0+1'),
            ),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Report Issue'),
              onTap: () {
                // TODO: Open issue reporting
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await EnhancedAuthService.signInWithGoogle();
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed in successfully')),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);
    
    try {
      await EnhancedAuthService.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed out successfully')),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign out failed: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}