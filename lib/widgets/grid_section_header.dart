import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'grid_form_fields.dart';

class GridSectionHeader extends StatelessWidget {
  final String label;
  final String title;

  const GridSectionHeader({
    super.key,
    required this.label,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: GridFormTheme.labelBg,
        border: Border(
          bottom: BorderSide(color: GridFormTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: GridFormTheme.accentGreen,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: GridFormTheme.darkGreen,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

