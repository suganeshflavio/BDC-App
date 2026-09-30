import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../models/about_us.dart';
import '../../providers/song_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/settings_provider.dart';
import '../lyrics/lyrics_screen.dart';
import 'all_songs_screen.dart';
import 'widgets/song_card.dart';
import '../../widgets/skeleton_loaders.dart';

class HomeScreen extends StatefulWidget {
  final SongProvider songProvider;
  final FavoriteProvider favoriteProvider;
  final SettingsProvider settingsProvider;

  const HomeScreen({
    super.key,
    required this.songProvider,
    required this.favoriteProvider,
    required this.settingsProvider,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PageController _bannerController;
  late final ApiService _apiService;
  AboutUs? _aboutUs;
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  List<Map<String, dynamic>> get _banners => [
    {
      'badge': 'SONG BOOK',
      'title': 'பரமனின் கீதங்கள்',
      'subtitle': 'Explore 120+ Christian Hymns, Chorus & Verses',
      'gradient': [const Color(0xFF1E1B38), const Color(0xFF384370), const Color(0xFFC15063)],
      'icon': Icons.music_note_rounded,
    },
    {
      'badge': 'SUNDAY SERVICE',
      'title': 'ஞாயிறு ஆராதனை',
      'subtitle': 'Join live worship & prophetic sermons every Sunday',
      'gradient': [const Color(0xFF0F2B48), const Color(0xFF1E5B7E), const Color(0xFFF6B071)],
      'icon': Icons.church_rounded,
    },
    {
      'badge': 'FASTING PRAYER',
      'title': 'வெள்ளி உபவாச ஜெபம்',
      'subtitle': 'Special fasting & deliverance healing prayer service',
      'gradient': [const Color(0xFF2E1C38), const Color(0xFF6F3B68), const Color(0xFFEAA15A)],
      'icon': Icons.volunteer_activism_rounded,
    },
    {
      'badge': '24/7 PRAYER LINE',
      'title': 'ஜெப உதவி மையம்',
      'subtitle': 'Contact Pastor & Prayer Warriors: ${_aboutUs?.contactNumber.isNotEmpty == true ? _aboutUs!.contactNumber : '94436-94891'}',
      'gradient': [const Color(0xFF1B3B2B), const Color(0xFF2E6B4F), const Color(0xFFFDD993)],
      'icon': Icons.phone_in_talk_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _bannerController = PageController();
    _startBannerAutoScroll();
    _loadAboutUs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.songProvider.songs.isEmpty) {
        widget.songProvider.loadSongs();
      }
    });
  }

  Future<void> _loadAboutUs({bool forceRefresh = false}) async {
    final info = await _apiService.fetchAboutUs(forceRefresh: forceRefresh);
    if (mounted && info != null) {
      setState(() {
        _aboutUs = info;
      });
    }
  }

  void _startBannerAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || !_bannerController.hasClients) return;
      int nextPage = (_currentBannerIndex + 1) % _banners.length;
      _bannerController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  void _navigateToAllSongs({bool autoFocusSearch = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AllSongsScreen(
          songProvider: widget.songProvider,
          favoriteProvider: widget.favoriteProvider,
          settingsProvider: widget.settingsProvider,
          autoFocusSearch: autoFocusSearch,
        ),
      ),
    );
  }

  Future<void> _callPrayerHelpline([String? customPhone]) async {
    final phone = customPhone ?? _aboutUs?.contactNumber ?? '94436-94891';
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleaned');
    try {
      await launchUrl(uri);
    } catch (e) {
      debugPrint('Could not call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.songProvider,
      builder: (context, _) {
        final songs = widget.songProvider.songs;
        final latestThreeSongs = songs.take(5).toList();
        final isLoading = widget.songProvider.isLoading;

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryDark,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'பரமனின் கீதங்கள்',
                  style: GoogleFonts.hindMadurai(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Paramanin Keethangal • பாடல் செயலி',
                  style: GoogleFonts.hindMadurai(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.amberGlow.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded, color: Colors.white),
                tooltip: 'Search Songs',
                onPressed: () => _navigateToAllSongs(autoFocusSearch: true),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: RefreshIndicator(
            color: AppColors.sunriseGold,
            onRefresh: () => Future.wait([
              widget.songProvider.loadSongs(forceRefresh: true),
              _loadAboutUs(forceRefresh: true),
            ]),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. WELCOME & GREETING CARD (Disabled)
                  // _buildWelcomeHeader(),

                  const SizedBox(height: 16),

                  // 2. CHURCH DETAILS CARD WITH IMAGE (Dynamic About Us API)
                  // _buildChurchDetailsCard(),

                  const SizedBox(height: 20),

                  // 3. HORIZONTAL BANNER IMAGE SCROLL CAROUSEL
                  _buildBannerCarousel(),

                  const SizedBox(height: 24),

                  // 4. LATEST SONGS SECTION HEADER WITH "SEE ALL" BUTTON
                  _buildLatestSongsHeader(songs.length),

                  const SizedBox(height: 8),

                  if (isLoading && songs.isEmpty)
                    const SongListSkeleton(count: 5, shrinkWrap: true)
                  else if (latestThreeSongs.isEmpty)
                    _buildEmptySongsPlaceholder()
                  else
                    ...latestThreeSongs.map(
                      (song) => SongCard(
                        song: song,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => LyricsScreen(
                                song: song,
                                settingsProvider: widget.settingsProvider,
                                songProvider: widget.songProvider,
                                favoriteProvider: widget.favoriteProvider,
                              ),
                            ),
                          );
                        },
                        onToggleFavorite: () async {
                          await widget.songProvider.toggleFavorite(song);
                          await widget.favoriteProvider.loadFavorites();
                        },
                      ),
                    ),

                  // View all songs button at the bottom of the list
                  if (songs.length > 5)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _navigateToAllSongs(),
                          icon: const Icon(Icons.library_music_rounded, size: 18),
                          label: Text(
                            'View All ${songs.length} Songs (முழு பாடல் பட்டியல்) →',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(
                              color: AppColors.sunriseGold.withValues(alpha: 0.8),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 1. Welcome & Greeting Top Header (Disabled)
  // Widget _buildWelcomeHeader() {
  //   return Container( ... );
  // }

  /// 2. Church Details Card with Church Image (Loaded from About Us API)
  // Widget _buildChurchDetailsCard() {
  //   final churchName = _aboutUs?.churchName.isNotEmpty == true
  //       ? _aboutUs!.churchName
  //       : 'Bethesda Deliverance Church';
  //   final ministryName = _aboutUs?.ministryName.isNotEmpty == true
  //       ? _aboutUs!.ministryName
  //       : 'The Feet of Heavenly Father Ministries';
  //   final description = _aboutUs?.description.isNotEmpty == true
  //       ? _aboutUs!.description
  //       : 'Join Bethesda Deliverance Church Family in Erode for uplifting sermons, live worship and real-life testimonies that strengthen faith.';
  //   final contactNumber = _aboutUs?.contactNumber.isNotEmpty == true
  //       ? _aboutUs!.contactNumber
  //       : '94436-94891';

  //   return Container(
  //     margin: const EdgeInsets.symmetric(horizontal: 16),
  //     decoration: BoxDecoration(
  //       color: AppColors.cardBackground,
  //       borderRadius: BorderRadius.circular(20),
  //       border: Border.all(
  //         color: AppColors.cardBorder,
  //         width: 1,
  //       ),
  //       boxShadow: [
  //         BoxShadow(
  //           color: AppColors.primaryDark.withValues(alpha: 0.05),
  //           blurRadius: 10,
  //           offset: const Offset(0, 4),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       children: [
  //         // Church Image / Banner Header
  //         ClipRRect(
  //           borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
  //           child: Container(
  //             decoration: const BoxDecoration(
  //               gradient: LinearGradient(
  //                 begin: Alignment.topLeft,
  //                 end: Alignment.bottomRight,
  //                 colors: [
  //                   Color(0xFF0F172A),
  //                   Color(0xFF1E293B),
  //                   Color(0xFF14243F),
  //                 ],
  //               ),
  //             ),
  //             width: double.infinity,
  //             height: 125,
  //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //             child: Image.asset(
  //               'assets/images/church_logo.png',
  //               fit: BoxFit.contain,
  //             ),
  //           ),
  //         ),

  //         const Divider(height: 1, color: AppColors.cardBorder),

  //         // Church & Ministry Info
  //         Padding(
  //           padding: const EdgeInsets.all(16),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   Expanded(
  //                     child: Text(
  //                       churchName,
  //                       style: GoogleFonts.poppins(
  //                         fontSize: 16,
  //                         fontWeight: FontWeight.w700,
  //                         color: AppColors.primaryDark,
  //                       ),
  //                     ),
  //                   ),
  //                   Container(
  //                     padding: const EdgeInsets.symmetric(
  //                       horizontal: 8,
  //                       vertical: 3,
  //                     ),
  //                     decoration: BoxDecoration(
  //                       color: AppColors.sunriseGold.withValues(alpha: 0.15),
  //                       borderRadius: BorderRadius.circular(12),
  //                       border: Border.all(
  //                         color: AppColors.sunriseGold.withValues(alpha: 0.5),
  //                       ),
  //                     ),
  //                     child: Text(
  //                       'To Bring Healing',
  //                       style: GoogleFonts.poppins(
  //                         fontSize: 10,
  //                         fontWeight: FontWeight.w600,
  //                         color: AppColors.primary,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 4),
  //               Text(
  //                 ministryName,
  //                 style: GoogleFonts.poppins(
  //                   fontSize: 12,
  //                   fontWeight: FontWeight.w500,
  //                   color: AppColors.textSecondary,
  //                 ),
  //               ),
  //               const SizedBox(height: 8),
  //               Text(
  //                 description,
  //                 style: GoogleFonts.poppins(
  //                   fontSize: 13,
  //                   color: AppColors.textPrimary,
  //                   height: 1.45,
  //                 ),
  //               ),
  //               const SizedBox(height: 14),

  //               // Quick Call & Helpline Row
  //               Row(
  //                 children: [
  //                   Expanded(
  //                     child: ElevatedButton.icon(
  //                       onPressed: () => _callPrayerHelpline(contactNumber),
  //                       icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
  //                       label: Text(
  //                         'Prayer Line: $contactNumber',
  //                         style: GoogleFonts.poppins(
  //                           fontSize: 12,
  //                           fontWeight: FontWeight.w600,
  //                         ),
  //                       ),
  //                       style: ElevatedButton.styleFrom(
  //                         backgroundColor: AppColors.primaryDark,
  //                         foregroundColor: AppColors.amberGlow,
  //                         elevation: 1,
  //                         padding: const EdgeInsets.symmetric(vertical: 10),
  //                         shape: RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.circular(12),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  /// 3. Horizontal Banner Image Scroll Option (Carousel)
  Widget _buildBannerCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppColors.sunriseAmber,
              ),
              const SizedBox(width: 6),
              Text(
                'Featured & Announcements',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 155,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) {
              setState(() => _currentBannerIndex = index);
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              final gradient = banner['gradient'] as List<Color>;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              banner['badge'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            banner['title'] as String,
                            style: GoogleFonts.hindMadurai(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            banner['subtitle'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        banner['icon'] as IconData,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Dot indicators for banner carousel
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (index) {
            final isSelected = _currentBannerIndex == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isSelected ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.sunriseGold
                    : AppColors.primaryLight.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// 4. Latest Songs Header with "See All" Button
  Widget _buildLatestSongsHeader(int totalSongs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.sunriseGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.queue_music_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Latest Added Songs',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'சமீபத்திய பாடல்கள் • 5 பாடல்கள்',
                    style: GoogleFonts.hindMadurai(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // "SEE ALL" BUTTON to navigate to all songs list
          TextButton.icon(
            onPressed: () => _navigateToAllSongs(),
            icon: Text(
              'See All',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            label: const Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: AppColors.primary,
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              backgroundColor: AppColors.sunriseGold.withValues(alpha: 0.18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySongsPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          'பாடல்கள் எதுவும் கிடைக்கவில்லை',
          style: GoogleFonts.hindMadurai(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
