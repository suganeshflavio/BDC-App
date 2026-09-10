import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../models/about_us.dart';
import '../../providers/settings_provider.dart';
import 'font_size_dialog.dart';

class AboutUsScreen extends StatefulWidget {
  final ApiService? apiService;
  final SettingsProvider? settingsProvider;
  final bool showBackButton;

  const AboutUsScreen({
    super.key,
    this.apiService,
    this.settingsProvider,
    this.showBackButton = true,
  });

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  late final ApiService _apiService;
  AboutUs? _aboutUs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadAboutUs();
      }
    });
  }

  Future<void> _loadAboutUs() async {
    final info = await _apiService.fetchAboutUs();
    if (mounted) {
      setState(() {
        _aboutUs = info;
        _isLoading = false;
      });
    }
  }

  Future<void> _callHelpline(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleaned');
    try {
      await launchUrl(uri);
    } catch (e) {
      debugPrint('Could not call phone: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About Us',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              'எங்களைப் பற்றி • Church & Ministry',
              style: GoogleFonts.hindMadurai(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.amberGlow.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
        actions: [
          if (widget.settingsProvider != null)
            IconButton(
              icon: const Icon(Icons.format_size_rounded, color: AppColors.amberGlow),
              tooltip: 'Font Size Settings',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => FontSizeDialog(
                    settingsProvider: widget.settingsProvider!,
                  ),
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.sunriseGold,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),

                  // 1. Church Banner Card
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 380),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF0F172A),
                          Color(0xFF1E293B),
                          Color(0xFF14243F),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/images/church_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Emblem & Ministry Profile
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0F172A),
                          border: Border.all(
                            color: AppColors.sunriseGold,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.sunriseGold.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
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
                      const SizedBox(width: 14),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _aboutUs?.ministryName ??
                                  'The Feet of heavenly Father Ministries',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.sunriseGold.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _aboutUs?.churchName ??
                                    'Bethesda Deliverance Church',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // 3. Tamil Dedication Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.sunriseGold.withValues(alpha: 0.4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.sunriseGold.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.menu_book_rounded,
                              color: AppColors.sunriseAmber,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'பரமனின் கீதங்கள்',
                              style: GoogleFonts.hindMadurai(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _aboutUs?.description ??
                              'இந்த ஊழியத்தின் மூலமாக "பரமனின் கீதங்கள்" என்ற பாடல் செயலியை வெளியிடுவதில் மகிழ்ச்சியடைகிறோம். இப்பாடல்கள் யாவும் தேவ நாம மகிமைக்காகவும் உங்கள் ஆவிக்குரிய வளர்ச்சிக்காகவும் அர்ப்பணிக்கப்படுகிறது.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.hindMadurai(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                            height: 1.65,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. Church Service Timings Card
                  // Container(
                  //   width: double.infinity,
                  //   padding: const EdgeInsets.all(18),
                  //   decoration: BoxDecoration(
                  //     color: AppColors.cardBackground,
                  //     borderRadius: BorderRadius.circular(18),
                  //     border: Border.all(color: AppColors.cardBorder),
                  //     boxShadow: [
                  //       BoxShadow(
                  //         color: AppColors.primaryDark.withValues(alpha: 0.04),
                  //         blurRadius: 10,
                  //         offset: const Offset(0, 3),
                  //       ),
                  //     ],
                  //   ),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       Row(
                  //         children: [
                  //           Container(
                  //             padding: const EdgeInsets.all(8),
                  //             decoration: BoxDecoration(
                  //               color: AppColors.primaryLight.withValues(alpha: 0.1),
                  //               shape: BoxShape.circle,
                  //             ),
                  //             child: const Icon(
                  //               Icons.church_rounded,
                  //               color: AppColors.primary,
                  //               size: 20,
                  //             ),
                  //           ),
                  //           const SizedBox(width: 12),
                  //           Text(
                  //             'ஆராதனை நேரங்கள் • Services',
                  //             style: GoogleFonts.poppins(
                  //               fontSize: 15,
                  //               fontWeight: FontWeight.w600,
                  //               color: AppColors.primaryDark,
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //       const SizedBox(height: 14),
                  //       _buildServiceRow(
                  //         day: 'ஞாயிறு ஆராதனை (Sunday Worship)',
                  //         time: '9:00 AM – 12:30 PM',
                  //         icon: Icons.wb_sunny_outlined,
                  //       ),
                  //       const Divider(color: AppColors.cardBorder, height: 18),
                  //       _buildServiceRow(
                  //         day: 'வெள்ளி உபவாசம் (Friday Fasting)',
                  //         time: '10:00 AM – 1:00 PM',
                  //         icon: Icons.volunteer_activism_outlined,
                  //       ),
                  //     ],
                  //   ),
                  // ),

                  const SizedBox(height: 20),

                  // 5. 24/7 Prayer Helpline Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primaryDark,
                          AppColors.primary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'மேலும் விவரங்கள் அறிய மற்றும் ஜெப உதவிக்கு:',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.hindMadurai(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _aboutUs?.contactNumber ?? '94436-94891',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.amberGlow,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: () => _callHelpline(
                            _aboutUs?.contactNumber ?? '94436-94891',
                          ),
                          icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
                          label: Text(
                            'Call Prayer Line',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.sunriseGold,
                            foregroundColor: AppColors.primaryDark,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 6. Font Size Preference Card (if settingsProvider present)
                  if (widget.settingsProvider != null) ...[
                    const SizedBox(height: 20),
                    ListenableBuilder(
                      listenable: widget.settingsProvider!,
                      builder: (context, _) {
                        final fontSize = widget.settingsProvider!.fontSize;
                        return Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.cardBorder),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryDark.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => FontSizeDialog(
                                    settingsProvider: widget.settingsProvider!,
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.format_size_rounded,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'பாடல் எழுத்து அளவு • Text Size',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primaryDark,
                                            ),
                                          ),
                                          Text(
                                            'Current: ${fontSize.toInt()}pt • Tap to customize',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.sunriseGold.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${fontSize.toInt()}pt',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 30),
                  Text(
                    'Version 1.0.0 • Phase 1 Release',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildServiceRow({
    required String day,
    required String time,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.sunriseAmber),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            day,
            style: GoogleFonts.hindMadurai(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          time,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }
}
