import 'package:flutter/material.dart';

class VersionInfoScreen extends StatelessWidget {
  const VersionInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Version Info'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // App Icon or Logo
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.music_note_rounded, 
                        size: 50, 
                        color: Theme.of(context).primaryColor
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Vibe',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      'v1.0.0',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  const Text(
                    "How to Use",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSection("Immersive Experience"),
                  _buildFeatureItem(context, "Horizon Switch", "Day/Night toggle with fluid gradients and solar/lunar orbital physics."),
                  _buildFeatureItem(context, "Letters to Myself", "Encrypted memory capsules. Write now, read later."),
                  _buildFeatureItem(context, "Realistic Burn V4", "Delete memories with a physics-based fire engine featuring heat distortion, ash particles, and parallax depth."),

                  _buildSection("Audio Intelligence"),
                  _buildFeatureItem(context, "Gapless Playback", "Zero-latency transitions between consecutive tracks."),
                  _buildFeatureItem(context, "Smart Crossfade", "Seamlessly blends songs for a radio-style mix."),
                  _buildFeatureItem(context, "ReplayGain Normalization", "Auto-balances volume across different albums."),
                  _buildFeatureItem(context, "Sleep Timer", "Fade-out logic to gently stop music."),

                  _buildSection("Motion & Gestures"),
                  _buildFeatureItem(context, "Shake to Skip", "Accelerometer-based track skipping."),
                  _buildFeatureItem(context, "Flip to Pause", "Gyroscope detection to pause music when face down."),
                  _buildFeatureItem(context, "Pocket Mode", "Proximity sensor lock to prevent accidental touches."),
                  _buildFeatureItem(context, "Analog Tilt Control", "Tilt device to adjust volume with haptic feedback."),

                  _buildSection("Library Control"),
                  _buildFeatureItem(context, "Smart Sorting", "Sort by Duration, Date Added, Artist, or Year."),
                  _buildFeatureItem(context, "Folder Blacklist", "Exclude specific directories (e.g., WhatsApp Audio)."),
                  _buildFeatureItem(context, "Live Search", "Instant fuzzy search across Songs, Artists, and Albums."),
                  _buildFeatureItem(context, "Realtime Updates", "Auto-detects file changes without restarting."),

                  _buildSection("Visual Engine"),
                  _buildFeatureItem(context, "Mesh Gradients", "Procedurally generated backgrounds matching album art."),
                  _buildFeatureItem(context, "Glassmorphism", "Blur-based UI layers for depth and readability."),
                  _buildFeatureItem(context, "Analog UI", "Retro-styled knobs and squiggly sliders."),
                  _buildFeatureItem(context, "Theme Engine", "Light/Dark/Auto modes with dynamic accent extraction."),

                  _buildSection("Utilities"),
                  _buildFeatureItem(context, "Car Mode", "High-contrast, large-button interface for driving."),
                  _buildFeatureItem(context, "Guest Mode", "Freezes listing stats for incognito listening."),
                  _buildFeatureItem(context, "Backup & Restore", "Export your Playlists, Favorites, and Memories to JSON."),
                ],
              ),
            ),
            
            // Footer
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Created by",
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "VIBIN",
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  description, 
                  style: TextStyle(
                    fontSize: 13, 
                    color: Theme.of(context).textTheme.bodySmall?.color
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: Colors.grey,
        ),
      ),
    );
  }
}
