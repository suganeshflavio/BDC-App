import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/settings_provider.dart';
import 'font_size_dialog.dart';
import 'about_us_screen.dart';
import '../../core/config/app_environment.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsProvider settingsProvider;

  const SettingsScreen({super.key, required this.settingsProvider});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsProvider,
      builder: (context, _) {
        final currentFontSize = settingsProvider.fontSize;

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryDark,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'அமைப்புகள் • App Preferences',
                  style: GoogleFonts.hindMadurai(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.amberGlow.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. App / Ministry Profile Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0F172A),
                          border: Border.all(
                            color: AppColors.sunriseGold,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.sunriseGold.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(4),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Paramanin Keethangal',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Bethesda Deliverance Church',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'The Feet of Heavenly Father Ministries',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section Label
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'PREFERENCES & CONFIGURATION',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Settings Group Card
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 1. User / Admin Access
                      _buildSettingsTile(
                        icon: Icons.person_outline_rounded,
                        title: 'User Access Mode',
                        subtitle: 'Guest offline mode enabled',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Guest Mode',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        onTap: () => _showUserAccessSheet(context),
                      ),

                      const Divider(color: AppColors.cardBorder, height: 1),

                      // 2. Font Size
                      _buildSettingsTile(
                        icon: Icons.format_size_rounded,
                        title: 'Song Lyrics Font Size',
                        subtitle: 'Adjust reading size (${currentFontSize.toInt()} pt)',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${currentFontSize.toInt()} pt',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.edit_rounded,
                                color: AppColors.amberGlow,
                                size: 12,
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => FontSizeDialog(
                              settingsProvider: settingsProvider,
                            ),
                          );
                        },
                      ),

                      const Divider(color: AppColors.cardBorder, height: 1),

                      // 3. Server Environment
                      // _buildSettingsTile(
                      //   icon: Icons.dns_outlined,
                      //   title: 'API Server Endpoint',
                      //   subtitle: 'Configure backend server URL',
                      //   trailing: Row(
                      //     mainAxisSize: MainAxisSize.min,
                      //     children: [
                      //       Container(
                      //         constraints: const BoxConstraints(maxWidth: 120),
                      //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      //         decoration: BoxDecoration(
                      //           color: AppColors.primaryLight.withValues(alpha: 0.1),
                      //           borderRadius: BorderRadius.circular(8),
                      //         ),
                      //         child: Text(
                      //           AppEnvironment.baseUrl,
                      //           style: GoogleFonts.poppins(
                      //             fontSize: 10,
                      //             color: AppColors.primaryDark,
                      //             fontWeight: FontWeight.w500,
                      //           ),
                      //           maxLines: 1,
                      //           overflow: TextOverflow.ellipsis,
                      //         ),
                      //       ),
                      //       const SizedBox(width: 4),
                      //       const Icon(
                      //         Icons.chevron_right_rounded,
                      //         color: AppColors.textSecondary,
                      //         size: 18,
                      //       ),
                      //     ],
                      //   ),
                      //   onTap: () => _showEnvironmentDialog(context),
                      // ),

                      const Divider(color: AppColors.cardBorder, height: 1),

                      // 4. About Us
                      _buildSettingsTile(
                        icon: Icons.info_outline_rounded,
                        title: 'About Bethesda Church',
                        subtitle: 'History, leadership, and contact details',
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AboutUsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // Version Branding Footer
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Paramanin Keethangal • Version 1.0.0',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bethesda Deliverance Church © 2026',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primaryDark, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  void _showUserAccessSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'User Access',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'You are browsing in free Guest Mode. All song lyrics, search, and personal favorites are preserved offline on your device.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Continue as Guest'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  void _showEnvironmentDialog(BuildContext context) {
    final controller = TextEditingController(text: AppEnvironment.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.dns_rounded, color: AppColors.primaryDark, size: 22),
            const SizedBox(width: 8),
            Text(
              'API Environment',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configured Base URL endpoint:',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'https://bdc-lyrics.vercel.app/api/v1',
                filled: true,
                fillColor: AppColors.scaffoldBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Default: ${AppEnvironment.defaultUrl}',
              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await AppEnvironment.resetBaseUrl();
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: Text(
              'Reset Default',
              style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                await AppEnvironment.setBaseUrl(newUrl);
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: AppColors.amberGlow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
