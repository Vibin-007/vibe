import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'glass_box.dart';

class VibeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const VibeAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      height: preferredSize.height + MediaQuery.of(context).padding.top,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (showBackButton)
              GestureDetector(
                onTap: onBackPressed ?? () => Navigator.pop(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16), // Squircle-ish
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: GlassBox(
                    borderRadius: BorderRadius.circular(16),
                    opacity: 0.1,
                    child: Center(
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: Theme.of(context).iconTheme.color,
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: 44),

            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            if (actions != null)
              ...actions!
            else
              const SizedBox(width: 44), // Balance the title
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80); // Taller for that floaty feel
}
