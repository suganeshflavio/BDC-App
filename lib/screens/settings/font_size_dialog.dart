import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/settings_provider.dart';

class FontSizeDialog extends StatelessWidget {
  final SettingsProvider settingsProvider;

  const FontSizeDialog({super.key, required this.settingsProvider});

  @override
  Widget build(BuildContext context) {
    final currentSize = settingsProvider.fontSize;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1C2F), // Dark sleek theme matching PDF page 8
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.sunriseGold.withValues(alpha: 0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: const BoxDecoration(
                color: Color(0xFF0F3952), // Deep Teal/Blue matching PDF screenshot
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(19),
                  topRight: Radius.circular(19),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'Select Font Size',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Font Size List
            ...SettingsProvider.availableFontSizes.map((size) {
              final isSelected = (currentSize == size);
              return InkWell(
                onTap: () {
                  settingsProvider.setFontSize(size);
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.sunriseGold.withValues(alpha: 0.15)
                        : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 1,
                      ),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${size.toInt()}',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.sunriseGold
                              : Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.sunriseGold,
                          size: 18,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 8),

            // Cancel Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'cancel',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white60,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
