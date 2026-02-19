import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VibeSettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? color;
  final String? subtitle;

  const VibeSettingsCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.trailing,
    this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8), // Reduced from 12
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Reduced vertical from 16
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8), // Reduced from 12
                  decoration: BoxDecoration(
                    color: (color ?? Theme.of(context).primaryColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color ?? Theme.of(context).primaryColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 16, 
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: GoogleFonts.outfit(
                            fontSize: 12, 
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null)
                   trailing!
                else
                   Icon(Icons.chevron_right_rounded, color: Theme.of(context).dividerColor.withOpacity(0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
