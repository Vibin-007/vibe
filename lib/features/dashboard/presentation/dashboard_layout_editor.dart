import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/ui/vibe_app_bar.dart';
import '../../../core/services/user_preferences_service.dart';

class DashboardLayoutEditor extends StatefulWidget {
  const DashboardLayoutEditor({super.key});

  @override
  State<DashboardLayoutEditor> createState() => _DashboardLayoutEditorState();
}

class _DashboardLayoutEditorState extends State<DashboardLayoutEditor> {
  late List<String> _layout;
  late List<String> _hidden;
  bool _changed = false;

  final Map<String, _SectionMetadata> _sections = {
    'playlists': _SectionMetadata('Playlists', Icons.playlist_play_rounded, Colors.purpleAccent),
    'favorites': _SectionMetadata('Favorites', Icons.favorite_rounded, Colors.redAccent),
    'recent': _SectionMetadata('Recently Played', Icons.history_rounded, Colors.orangeAccent),
    'center_player': _SectionMetadata('Mini Player', Icons.music_note_rounded, Colors.blueAccent),
  };

  @override
  void initState() {
    super.initState();
    final prefs = context.read<UserPreferencesService>();
    _layout = List.from(prefs.getDashboardLayout());
    _hidden = List.from(prefs.getDashboardHiddenSections());
  }

  void _save() {
    final prefs = context.read<UserPreferencesService>();
    prefs.setDashboardLayout(_layout);
    prefs.setDashboardHiddenSections(_hidden);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Layout saved successfully')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Customize Home'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: _changed ? _save : null, 
              style: TextButton.styleFrom(
                backgroundColor: _changed ? Theme.of(context).primaryColor : Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
              ),
              child: Text(
                'Save', 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: _changed ? Colors.white : Theme.of(context).disabledColor
                )
              )
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(
              children: [
                Text(
                  'Design Your Space',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                const SizedBox(height: 8),
                Text(
                  'Drag cards to reorder. Toggle to hide.',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 14),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ReorderableListView(
              padding: const EdgeInsets.all(24),
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (BuildContext context, Widget? child) {
                    final double animValue = Curves.easeInOut.transform(animation.value);
                    final double elevation = lerpDouble(0, 6, animValue)!;
                    return Material(
                      elevation: elevation,
                      color: Colors.transparent,
                      shadowColor: Colors.black.withOpacity(0.3),
                      child: child,
                    );
                  },
                  child: child,
                );
              },
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final item = _layout.removeAt(oldIndex);
                  _layout.insert(newIndex, item);
                  _changed = true;
                });
              },
              children: [
                 for (final id in _layout)
                   _buildLayoutCard(id)
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutCard(String id) {
    final meta = _sections[id] ?? _SectionMetadata(id, Icons.widgets_rounded, Colors.grey);
    final isVisible = !_hidden.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isVisible 
            ? meta.color.withOpacity(0.3) 
            : Theme.of(context).dividerColor.withOpacity(0.1),
          width: 1.5
        ),
        boxShadow: [
          if (isVisible)
            BoxShadow(
              color: meta.color.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 4)
            )
        ]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
               // HapticFeedback.lightImpact(); // Optional
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isVisible ? meta.color.withOpacity(0.1) : Theme.of(context).disabledColor.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(meta.icon, color: isVisible ? meta.color : Theme.of(context).disabledColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meta.name,
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold,
                            color: isVisible ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).disabledColor
                          ),
                        ),
                        if (!isVisible)
                          Text(
                            'Hidden from Home',
                            style: TextStyle(fontSize: 12, color: Theme.of(context).disabledColor),
                          )
                      ],
                    ),
                  ),

                  // Actions
                  Switch.adaptive(
                    value: isVisible,
                    activeColor: meta.color,
                    onChanged: (val) {
                      setState(() {
                         if (val) {
                           _hidden.remove(id);
                         } else {
                           _hidden.add(id);
                         }
                         _changed = true;
                      });
                    }
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.drag_indicator_rounded, color: Theme.of(context).dividerColor),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate(key: ValueKey(id), target: isVisible ? 1 : 0).saturate(duration: 300.ms);
  }
  
  // Helper for web/desktop standard lerp
  double? lerpDouble(num? a, num? b, double t) {
    if (a == null && b == null) return null;
    a ??= 0.0;
    b ??= 0.0;
    return a + (b - a) * t;
  }
}

class _SectionMetadata {
  final String name;
  final IconData icon;
  final Color color;

  _SectionMetadata(this.name, this.icon, this.color);
}
