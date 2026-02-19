import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/bloc/theme_bloc.dart';

class AccentColorScreen extends StatefulWidget {
  const AccentColorScreen({super.key});

  @override
  State<AccentColorScreen> createState() => _AccentColorScreenState();
}

class _AccentColorScreenState extends State<AccentColorScreen> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(

              background: _buildPreviewHeader(context),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
              child: Text(
                "Curated Palette", 
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
              ),
            ),
          ),

          _buildPresetsGrid(),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 10),
              child: Text(
                "Custom Mix", 
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
              ),
            ),
          ),
          
          SliverToBoxAdapter(child: _buildCustomPicker()),
          
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  Widget _buildPreviewHeader(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final color = state.accentColor ?? Theme.of(context).primaryColor;
        return Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Simulated UI Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, spreadRadius: 2)
                      ]
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         Container(
                           padding: const EdgeInsets.all(12),
                           decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
                           child: Icon(Icons.play_arrow_rounded, color: color, size: 32),
                         ),
                         const SizedBox(width: 16),
                         Column(
                           mainAxisSize: MainAxisSize.min,
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text("Preview Title", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                             const SizedBox(height: 4),
                             Container(width: 60, height: 6, decoration: BoxDecoration(color: color.withOpacity(0.3), borderRadius: BorderRadius.circular(3)))
                           ],
                         )
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPresetsGrid() {
    final List<Color> allColors = [
      Colors.redAccent, Colors.pinkAccent, Colors.purpleAccent, Colors.deepPurpleAccent,
      Colors.indigoAccent, Colors.blueAccent, Colors.lightBlueAccent, Colors.cyanAccent,
      Colors.tealAccent, Colors.greenAccent, Colors.lightGreenAccent, Colors.limeAccent,
      Colors.yellowAccent, Colors.amberAccent, Colors.orangeAccent, Colors.deepOrangeAccent,
      const Color(0xFF6D4C41), // Brownish
      const Color(0xFF546E7A), // BlueGreyish
      const Color(0xFF263238), // Dark
      const Color(0xFF9147FF), // Brand Purple (Replaced White)
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Filter logic:
    // In Dark Mode: Background is dark. Text/Icons need to be Light. 
    //   -> Hide very dark colors (low luminance).
    // In Light Mode: Background is light. Text/Icons need to be Dark.
    //   -> Hide very light colors (high luminance).
    
    final visibleColors = allColors.where((color) {
      final lum = color.computeLuminance();
      if (isDark) {
        return lum > 0.08; // Allow most colors, but filter near-blacks
      } else {
        return lum < 0.65; // Filter out Yellows/Cyans/Limes that are too bright on white
      }
    }).toList();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final color = visibleColors[index];
            return BlocBuilder<ThemeBloc, ThemeState>(
              builder: (context, state) {
                final isSelected = state.accentColor?.value == color.value;
                return GestureDetector(
                  onTap: () {
                    context.read<ThemeBloc>().add(ChangeAccentColor(color));
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: Theme.of(context).colorScheme.onBackground, width: 3) : Border.all(color: Colors.black12),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(color: color.withOpacity(0.6), blurRadius: 12, spreadRadius: 2)
                      ],
                    ),
                    child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                  ),
                );
              },
            );
          },
          childCount: visibleColors.length,
        ),
      ),
    );
  }

  Widget _buildCustomPicker() {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final currentColor = state.accentColor ?? Colors.blue;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
          ),
          child: _CustomColorSliders(
            initialColor: currentColor,
            onColorChanged: (color) {
              context.read<ThemeBloc>().add(ChangeAccentColor(color));
            },
          ),
        );
      },
    );
  }
}

class _CustomColorSliders extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  const _CustomColorSliders({required this.initialColor, required this.onColorChanged});

  @override
  State<_CustomColorSliders> createState() => _CustomColorSlidersState();
}

class _CustomColorSlidersState extends State<_CustomColorSliders> {
  late HSVColor _hsv;
  late TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initialColor);
    _hexController = TextEditingController(text: _toHex(widget.initialColor));
  }
  
  @override
  void didUpdateWidget(_CustomColorSliders oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialColor != widget.initialColor) {
       _hsv = HSVColor.fromColor(widget.initialColor);
       if (!_hexController.selection.isValid) {
         _hexController.text = _toHex(widget.initialColor);
       }
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _toHex(Color color) => '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  void _onHexSubmitted(String value) {
    if (value.startsWith('#')) value = value.substring(1);
    if (value.length == 6) {
      try {
        final color = Color(int.parse('0xFF$value'));
        setState(() {
          _hsv = HSVColor.fromColor(color);
        });
        widget.onColorChanged(color);
      } catch (e) {
        // Ignore invalid hex
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("Hue"),
        SizedBox(
          height: 30, // Thinner, sleek slider
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 12,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
              thumbColor: Colors.white,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: const LinearGradient(
                  colors: [
                    Colors.red, Colors.yellow, Colors.green, 
                    Colors.cyan, Colors.blue, Colors.purpleAccent, Colors.red
                  ],
                ),
              ),
              child: Slider(
                value: _hsv.hue,
                min: 0,
                max: 360,
                onChanged: (val) {
                  final newColor = _hsv.withHue(val).toColor();
                  setState(() {
                    _hsv = _hsv.withHue(val);
                    _hexController.text = _toHex(newColor);
                  });
                  widget.onColorChanged(newColor);
                },
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        _buildLabel("Saturation"),
        SliderTheme(
          data: SliderThemeData(activeTrackColor: _hsv.toColor(), thumbColor: _hsv.toColor()),
          child: Slider(
            value: _hsv.saturation,
            min: 0,
            max: 1,
            onChanged: (val) {
              final newColor = _hsv.withSaturation(val).toColor();
              setState(() {
                _hsv = _hsv.withSaturation(val);
                _hexController.text = _toHex(newColor);
              });
              widget.onColorChanged(newColor);
            },
          ),
        ),

        const SizedBox(height: 10),
        _buildLabel("Brightness"),
        SliderTheme(
          data: SliderThemeData(activeTrackColor: Colors.grey[400], thumbColor: Colors.grey[400]),
          child: Slider(
            value: _hsv.value,
            min: 0,
            max: 1,
            onChanged: (val) {
              final newColor = _hsv.withValue(val).toColor();
              setState(() {
                _hsv = _hsv.withValue(val);
                _hexController.text = _toHex(newColor);
              });
              widget.onColorChanged(newColor);
            },
          ),
        ),

        const SizedBox(height: 24),
        TextField(
          controller: _hexController,
          decoration: InputDecoration(
            labelText: 'Hex Code',
            hintText: '#RRGGBB',
            prefixIcon: const Icon(Icons.colorize),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => _onHexSubmitted(_hexController.text),
            )
          ),
          onSubmitted: _onHexSubmitted,
        ),
      ],
    );
  }
  
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}
