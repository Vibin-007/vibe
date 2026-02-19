import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/user_preferences_service.dart';
import '../../../core/ui/vibe_app_bar.dart';

class NavigationLayoutEditor extends StatefulWidget {
  const NavigationLayoutEditor({super.key});

  @override
  State<NavigationLayoutEditor> createState() => _NavigationLayoutEditorState();
}

class _NavigationLayoutEditorState extends State<NavigationLayoutEditor> {
  late UserPreferencesService _userPrefs;
  List<String> _currentLayout = [];

  final Map<String, NavItemData> _navItems = {
    'home': NavItemData(
      icon: Icons.home_rounded, 
      label: 'Home', 
      color: Colors.blueAccent,
      description: 'Your central hub for music discovery.'
    ),
    'songs': NavItemData(
      icon: Icons.music_note_rounded, 
      label: 'Songs', 
      color: Colors.pinkAccent,
      description: 'Browse your entire library by tracks.'
    ),
    'playlists': NavItemData(
      icon: Icons.playlist_play_rounded, 
      label: 'Playlists', 
      color: Colors.purpleAccent,
      description: 'Access your custom and auto-generated playlists.'
    ),
    'account': NavItemData(
      icon: Icons.person_rounded, 
      label: 'Account', 
      color: Colors.tealAccent,
      description: 'Settings, profile, and app customization.'
    ),
  };

  @override
  void initState() {
    super.initState();
    _userPrefs = RepositoryProvider.of<UserPreferencesService>(context);
    _currentLayout = List.from(_userPrefs.getNavigationLayout());
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    setState(() {
      final String item = _currentLayout.removeAt(oldIndex);
      _currentLayout.insert(newIndex, item);
    });
    _userPrefs.setNavigationLayout(_currentLayout);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const VibeAppBar(title: 'Customize Navigation'),
      body: Stack(
        children: [
          // Background Gradient matching Dashboard Editor
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).scaffoldBackgroundColor,
                  Theme.of(context).primaryColor.withOpacity(0.05),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Text(
                    'Arrange Tabs',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    'Drag to reorder the tabs at the bottom of your screen.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ReorderableListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    physics: const BouncingScrollPhysics(),
                    onReorder: _onReorder,
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (BuildContext context, Widget? child) {
                          final double animValue = Curves.easeInOut.transform(animation.value);
                          final double scale = 1 + 0.05 * animValue;
                          return Transform.scale(
                            scale: scale,
                            child: Material(
                              elevation: 10,
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              child: child,
                            ),
                          );
                        },
                        child: child,
                      );
                    },
                    children: [
                      for (int i = 0; i < _currentLayout.length; i++)
                        _buildConceptCard(_currentLayout[i], ValueKey(_currentLayout[i]))
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConceptCard(String id, Key key) {
    final data = _navItems[id];
    if (data == null) return const SizedBox.shrink(key: Key('empty'));

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: data.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(data.icon, color: data.color),
        ),
        title: Text(
          data.label,
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          data.description,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: const Icon(Icons.drag_handle_rounded, color: Colors.grey),
      ),
    );
  }
}

class NavItemData {
  final IconData icon;
  final String label;
  final Color color;
  final String description;

  NavItemData({
    required this.icon,
    required this.label,
    required this.color,
    required this.description,
  });
}
