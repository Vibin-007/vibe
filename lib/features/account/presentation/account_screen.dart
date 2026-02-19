import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/bloc/theme_bloc.dart';
import '../../../core/services/user_preferences_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../stats/presentation/stats_screen.dart';
import '../../stats/presentation/stats_screen.dart';


import 'dart:convert';
import 'package:flutter/services.dart';
import '../../songs/bloc/songs_bloc.dart';
import '../../songs/bloc/songs_event.dart';
import '../../songs/bloc/player_bloc.dart';
import '../../songs/presentation/folder_selection_screen.dart';
import 'blacklist_screen.dart';

import 'dart:io';
import 'accent_color_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'version_info_screen.dart';
import '../../dashboard/presentation/dashboard_layout_editor.dart';
import 'bluetooth_settings_screen.dart';
import 'sleep_timer_screen.dart';
import '../../main_navigation/presentation/navigation_layout_editor.dart';

import 'package:google_fonts/google_fonts.dart';
import '../../../core/ui/vibe_settings_card.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'widgets/appearance_settings_card.dart';


class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<void>(
        stream: RepositoryProvider.of<UserPreferencesService>(context).dataStream,
        builder: (context, _) {
          final userPrefs = RepositoryProvider.of<UserPreferencesService>(context);
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final profileImage = userPrefs.getProfileImagePath();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 110, 16, 0), // Reduced bottom padding
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4), // Space for border
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).primaryColor,
                    backgroundImage: profileImage != null ? FileImage(File(profileImage)) : null,
                    child: profileImage == null 
                      ? Text(
                          userPrefs.getUserName()?[0].toUpperCase() ?? 'U',
                          style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                        ) 
                      : null,
                  ),
                ),
              ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              userPrefs.getUserName() ?? 'User',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 40),
          _buildSectionHeader('Profile'),
          VibeSettingsCard(
            title: 'Edit Profile', 
            icon: Icons.edit_outlined, 
            onTap: () => _showEditProfileDialog(context, userPrefs),
            color: Colors.blueAccent,
          ),
          VibeSettingsCard(
            title: 'Listening Stats', 
            icon: Icons.bar_chart_rounded, 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StatsScreen())),
            color: Colors.orangeAccent,
          ),


          
          const SizedBox(height: 24),
          _buildSectionHeader('Settings'),
          const AppearanceSettingsCard(),
          VibeSettingsCard(
            title: 'Accent Color & Style',
            icon: Icons.palette_outlined,
            color: Colors.pinkAccent,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AccentColorScreen()));
            },
            trailing: BlocBuilder<ThemeBloc, ThemeState>(
              builder: (context, state) {
                final color = state.accentColor ?? Theme.of(context).primaryColor;
                return Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                  ),
                );
              },
            )
          ),

          if (profileImage != null)
             VibeSettingsCard(
               title: 'Profile Background',
               icon: Icons.image_rounded,
               color: Colors.purpleAccent,
               onTap: () {
                 userPrefs.setEnableProfileBackground(!userPrefs.getEnableProfileBackground());
               },
               trailing: Switch(
                 value: userPrefs.getEnableProfileBackground(),
                 onChanged: (val) => userPrefs.setEnableProfileBackground(val),
                 activeColor: Theme.of(context).primaryColor,
               ),
             ),
          



          VibeSettingsCard(
            title: 'Sleep Timer', 
            icon: Icons.timer_outlined, 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SleepTimerScreen())),
            color: Colors.indigoAccent,
          ),
          VibeSettingsCard(
            title: 'Customize Homepage', 
            icon: Icons.dashboard_customize_outlined, 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardLayoutEditor())),
            color: Colors.tealAccent,
          ),
          VibeSettingsCard(
            title: 'Customize Navigation', 
            icon: Icons.view_carousel_rounded, 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NavigationLayoutEditor())),
            color: Colors.cyanAccent,
          ),
          VibeSettingsCard(
            title: 'Bluetooth Auto-Play', 
            icon: Icons.bluetooth_audio_rounded, 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BluetoothSettingsScreen())),
            color: Colors.blue,
          ),

          VibeSettingsCard(
             title: 'Guest Mode',
             icon: Icons.visibility_off_rounded,
             color: Colors.grey,
             onTap: () {
                userPrefs.setGuestMode(!userPrefs.isGuestMode());
             },
             trailing: Switch(
               value: userPrefs.isGuestMode(), 
               onChanged: (val) => userPrefs.setGuestMode(val),
               activeColor: Theme.of(context).primaryColor,
             ),
          ),
          VibeSettingsCard(
             title: 'Shake to Skip',
             icon: Icons.vibration_rounded, // or broken_image_rounded / phone_iphone_rounded
             color: Colors.orange,
             onTap: () {
                userPrefs.setShakeToSkip(!userPrefs.getShakeToSkip());
             },
             trailing: Switch(
               value: userPrefs.getShakeToSkip(), 
               onChanged: (val) => userPrefs.setShakeToSkip(val),
               activeColor: Theme.of(context).primaryColor,
             ),
          ),
          VibeSettingsCard(
             title: 'Flip to Pause',
             icon: Icons.screen_rotation_rounded, // or phone_android_rounded
             color: Colors.indigo,
             onTap: () {
                userPrefs.setFlipToPause(!userPrefs.getFlipToPause());
             },
             trailing: Switch(
               value: userPrefs.getFlipToPause(), 
               onChanged: (val) => userPrefs.setFlipToPause(val),
               activeColor: Theme.of(context).primaryColor,
             ),
          ),
          VibeSettingsCard(
             title: 'Pocket Mode',
             icon: Icons.security_rounded, // or pocket / screen_lock_portrait
             color: Colors.brown,
             onTap: () {
                userPrefs.setPocketMode(!userPrefs.getPocketMode());
             },
             trailing: Switch(
               value: userPrefs.getPocketMode(), 
               onChanged: (val) => userPrefs.setPocketMode(val),
               activeColor: Theme.of(context).primaryColor,
             ),
          ),
          VibeSettingsCard(
             title: 'Analog Volume Tilt',
             icon: Icons.rotate_right_rounded,
             color: Colors.teal,
             onTap: () {
                userPrefs.setAnalogVolumeTilt(!userPrefs.getAnalogVolumeTilt());
             },
             trailing: Switch(
               value: userPrefs.getAnalogVolumeTilt(), 
               onChanged: (val) => userPrefs.setAnalogVolumeTilt(val),
               activeColor: Theme.of(context).primaryColor,
             ),
          ),
          VibeSettingsCard(
            title: 'Music Folders', 
            icon: Icons.folder_copy_outlined, 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FolderSelectionScreen())),
            color: Colors.amberAccent,
          ),
          VibeSettingsCard(
            title: 'Blacklist & Filters', 
            icon: Icons.filter_alt_off_outlined, 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BlacklistScreen())),
            color: Colors.redAccent,
          ),


          VibeSettingsCard(
            title: 'Backup & Restore', 
            icon: Icons.backup_outlined, 
            onTap: () => _showBackupDialog(context, userPrefs),
            color: Colors.lightBlueAccent,
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('About'),
          // Version info removed as requested
          VibeSettingsCard(
            title: 'Exit App', 
            icon: Icons.exit_to_app_rounded, 
            onTap: () => SystemNavigator.pop(),
            color: AppColors.error,
          ),
          
          const SizedBox(height: 80), // MiniPlayer offset reduced
          ],
        );
      }),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
  void _showBackupDialog(BuildContext context, UserPreferencesService prefs) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.output_rounded, color: Colors.blue), // Changed icon to Output
              title: const Text('Export JSON File'),
              subtitle: const Text('Share backup file'),
              onTap: () async {
                Navigator.pop(context);
                final json = prefs.exportBackup(); // Get JSON early for fallback
                try {
                  final file = await prefs.createBackupFile();
                  if (file != null) {
                    await Share.shareXFiles(
                      [XFile(file.path)], 
                      text: 'Vibe Music Backup (${DateTime.now().toString().split(' ')[0]})',
                      subject: 'Vibe Backup.json'
                    );
                  } else {
                    throw Exception("File creation failed");
                  }
                } catch (e) {
                  // Fallback to text share if file share fails
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File share failed, sharing text instead...')));
                    await Share.share(json, subject: 'Vibe Backup JSON');
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: Colors.orange),
              title: const Text('Copy to Clipboard'),
              subtitle: const Text('Legacy backup method'),
              onTap: () {
                final json = prefs.exportBackup();
                Clipboard.setData(ClipboardData(text: json));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup JSON copied to clipboard')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_rounded, color: Colors.green),
              title: const Text('Restore from File'),
              subtitle: const Text('Pick a .json backup file'),
              onTap: () async {
                Navigator.pop(context);
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['json'],
                );
                
                if (result != null && result.files.single.path != null) {
                  final file = File(result.files.single.path!);
                  try {
                    final json = await file.readAsString();
                    await prefs.importBackup(json);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup restored successfully!')));
                    }
                  } catch (e) {
                     if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid backup file')));
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, UserPreferencesService prefs) {
    final controller = TextEditingController(text: prefs.getUserName());
    String? currentImagePath = prefs.getProfileImagePath();
    
    showDialog(
      context: context, 
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Edit Profile"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 GestureDetector(
                   onTap: () async {
                      final picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        final appDir = await getApplicationDocumentsDirectory();
                        final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
                        final savedImage = await File(image.path).copy('${appDir.path}/$fileName');
                        setState(() {
                          currentImagePath = savedImage.path;
                        });
                      }
                   },
                   child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: currentImagePath != null ? FileImage(File(currentImagePath!)) : null,
                      child: currentImagePath == null ? const Icon(Icons.camera_alt, color: Colors.grey, size: 30) : null,
                   ),
                 ),
                 const SizedBox(height: 16),
                 TextField(
                  controller: controller,
                  decoration: const InputDecoration(hintText: "Enter your name"),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.isNotEmpty) {
                    await prefs.setUserName(controller.text);
                    if (currentImagePath != null) {
                      await prefs.setProfileImagePath(currentImagePath!);
                    }
                    Navigator.pop(context);
                  }
                }, 
                child: const Text("Save")
              )
            ],
          );
        }
      )
    );
  }

  void _showSleepTimerDialog(BuildContext context) {
    showModalBottomSheet(
      context: context, 
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text("Set Sleep Timer", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ...[15, 30, 45, 60].map((min) => ListTile(
              leading: const Icon(Icons.timer),
              title: Text('$min minutes'),
              onTap: () {
                context.read<PlayerBloc>().add(SetSleepTimer(Duration(minutes: min)));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sleep timer set for $min mins')));
              },
            )),
            ListTile(
              leading: const Icon(Icons.timer_off),
              title: const Text('Turn Off Timer'),
              onTap: () {
                context.read<PlayerBloc>().add(SetSleepTimer(null));
                Navigator.pop(context);
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sleep timer turned off')));
              },
            ),
          ],
        ),
      )
    );
  }

  void _showExcludedFoldersDialog(BuildContext context, UserPreferencesService prefs) {
    final controller = TextEditingController();
    final excluded = prefs.getExcludedFolders();
    
    showDialog(
      context: context, 
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Excluded Folders"),
            content: SizedBox(
               width: double.maxFinite,
               child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "/storage/emulated/0/WhatsApp/...",
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                           if (controller.text.isNotEmpty) {
                              excluded.add(controller.text);
                              prefs.setExcludedFolders(excluded);
                              controller.clear();
                              setState(() {});
                           }
                        },
                      )
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (excluded.isEmpty) 
                    const Text("No excluded folders", style: TextStyle(color: Colors.grey)),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: excluded.length,
                      itemBuilder: (context, index) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(excluded[index], style: const TextStyle(fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            excluded.removeAt(index);
                            prefs.setExcludedFolders(excluded);
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                  )
                ],
               ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  context.read<SongsBloc>().add(LoadSongs());
                  Navigator.pop(context);
                }, 
                child: const Text("Done")
              )
            ],
          );
        }
      )
    );
  }
}
