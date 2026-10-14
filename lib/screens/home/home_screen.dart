import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../models/about_us.dart';
import '../../models/announcement.dart';
import '../../providers/song_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/settings_provider.dart';
import '../lyrics/lyrics_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/about_us_screen.dart';
import 'all_songs_screen.dart';
import 'widgets/song_card.dart';
import '../../widgets/skeleton_loaders.dart';

class AnnouncementBannerSlide {
  final Announcement announcement;
  final String? imageUrl;
  final int imageIndex;
  final int totalImagesForAnnouncement;

  AnnouncementBannerSlide({
    required this.announcement,
    this.imageUrl,
    this.imageIndex = 0,
    this.totalImagesForAnnouncement = 1,
  });
}

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
  List<Announcement> _announcements = [];
  List<AnnouncementBannerSlide> _bannerSlides = [];
  bool _isLoadingAnnouncements = true;
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _bannerController = PageController();
    _loadAboutUs();
    _loadAnnouncements();
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

  Future<void> _loadAnnouncements({bool forceRefresh = false}) async {
    try {
      final list = await _apiService.fetchAnnouncements();
      if (!mounted) return;

      final List<AnnouncementBannerSlide> slides = [];
      for (final a in list) {
        if (a.bannerImages.isNotEmpty) {
          for (int i = 0; i < a.bannerImages.length; i++) {
            slides.add(AnnouncementBannerSlide(
              announcement: a,
              imageUrl: a.bannerImages[i],
              imageIndex: i,
              totalImagesForAnnouncement: a.bannerImages.length,
            ));
          }
        } else {
          slides.add(AnnouncementBannerSlide(
            announcement: a,
            imageUrl: null,
          ));
        }
      }

      setState(() {
        _announcements = list;
        _bannerSlides = slides;
        _isLoadingAnnouncements = false;
        if (_currentBannerIndex >= slides.length) {
          _currentBannerIndex = 0;
        }
      });
      _startBannerAutoScroll();
    } catch (e) {
      debugPrint('HomeScreen._loadAnnouncements error: $e');
      if (mounted) {
        setState(() => _isLoadingAnnouncements = false);
      }
    }
  }

  void _startBannerAutoScroll() {
    _bannerTimer?.cancel();
    if (_bannerSlides.length <= 1) return;
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || !_bannerController.hasClients || _bannerSlides.isEmpty) return;
      int nextPage = (_currentBannerIndex + 1) % _bannerSlides.length;
      _bannerController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  String _resolveImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final uri = Uri.tryParse(_apiService.baseUrl);
    if (uri != null && uri.hasScheme && uri.hasAuthority) {
      final origin = '${uri.scheme}://${uri.authority}';
      return origin + (url.startsWith('/') ? url : '/$url');
    }
    return url;
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
                  'BDC Family',
                  style: GoogleFonts.hindMadurai(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'A Covenant of Prayer',
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
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                tooltip: 'Settings & Preferences',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SettingsScreen(
                        settingsProvider: widget.settingsProvider,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: RefreshIndicator(
            color: AppColors.sunriseGold,
            onRefresh: () => Future.wait([
              widget.songProvider.loadSongs(forceRefresh: true),
              _loadAboutUs(forceRefresh: true),
              _loadAnnouncements(forceRefresh: true),
            ]),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. SIMPLE WELCOME TEXT HEADER
                  _buildWelcomeText(),

                  const SizedBox(height: 10),

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

  /// 1. Simple Welcome Text Header
  Widget _buildWelcomeText() {
    final userName = StorageService.getUserName();
    final hasName = userName != null && userName.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasName ? 'Welcome, ${userName.trim()}' : 'Welcome to BDC Family',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'A Covenant of Prayer • கர்த்தருக்குள் அன்பின் வாழ்த்துகள்',
            style: GoogleFonts.hindMadurai(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Horizontal Banner Image Scroll Option (Dynamic Announcements Carousel)
  Widget _buildBannerCarousel() {
    if (_isLoadingAnnouncements) {
      return _buildBannerSkeleton();
    }

    if (_bannerSlides.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              // const Icon(
              //   Icons.campaign_rounded,
              //   size: 18,
              //   color: AppColors.sunriseAmber,
              // ),
              // const SizedBox(width: 6),
              // Text(
              //   'Featured & Announcements',
              //   style: GoogleFonts.poppins(
              //     fontSize: 13,
              //     fontWeight: FontWeight.w600,
              //     color: AppColors.textSecondary,
              //     letterSpacing: 0.5,
              //   ),
              // ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final bannerHeight = constraints.maxWidth * 9 / 16;
            return SizedBox(
              height: bannerHeight,
              child: PageView.builder(
                controller: _bannerController,
                onPageChanged: (index) {
                  setState(() => _currentBannerIndex = index);
                },
                itemCount: _bannerSlides.length,
                itemBuilder: (context, index) {
              final slide = _bannerSlides[index];

              return GestureDetector(
                onTap: () => _showAnnouncementDetail(slide.announcement, slide.imageUrl),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background image or fallback card
                        _buildBannerImage(slide.imageUrl, slide.announcement),

                        // Bottom gradient scrim for text readability
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.85),
                                  Colors.black.withValues(alpha: 0.45),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (slide.announcement.subject.isNotEmpty)
                                  // Text(
                                  //   slide.announcement.subject,
                                  //   style: GoogleFonts.hindMadurai(
                                  //     fontSize: 16,
                                  //     fontWeight: FontWeight.w700,
                                  //     color: Colors.white,
                                  //     shadows: const [
                                  //       Shadow(
                                  //         blurRadius: 4,
                                  //         color: Colors.black87,
                                  //         offset: Offset(0, 1),
                                  //       ),
                                  //     ],
                                  //   ),
                                  //   maxLines: 1,
                                  //   overflow: TextOverflow.ellipsis,
                                  // ),
                                if (slide.announcement.description.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  // Text(
                                  //   slide.announcement.description,
                                  //   style: GoogleFonts.poppins(
                                  //     fontSize: 11,
                                  //     color: Colors.white.withValues(alpha: 0.9),
                                  //     shadows: const [
                                  //       Shadow(
                                  //         blurRadius: 4,
                                  //         color: Colors.black87,
                                  //         offset: Offset(0, 1),
                                  //       ),
                                  //     ],
                                  //   ),
                                  //   maxLines: 1,
                                  //   overflow: TextOverflow.ellipsis,
                                  // ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // Announcement badge in top left
                        // Positioned(
                        //   top: 10,
                        //   left: 12,
                        //   child: Container(
                        //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        //     decoration: BoxDecoration(
                        //       color: AppColors.primaryDark.withValues(alpha: 0.85),
                        //       borderRadius: BorderRadius.circular(8),
                        //       border: Border.all(
                        //         color: AppColors.sunriseGold.withValues(alpha: 0.5),
                        //         width: 1,
                        //       ),
                        //     ),
                        //     child: Row(
                        //       mainAxisSize: MainAxisSize.min,
                        //       children: [
                        //         const Icon(
                        //           Icons.campaign_rounded,
                        //           size: 13,
                        //           color: AppColors.sunriseGold,
                        //         ),
                        //         const SizedBox(width: 4),
                        //         Text(
                        //           'ANNOUNCEMENT',
                        //           style: GoogleFonts.poppins(
                        //             fontSize: 9,
                        //             fontWeight: FontWeight.w700,
                        //             color: AppColors.sunriseGold,
                        //             letterSpacing: 0.5,
                        //           ),
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                        // ),

                        // Multi-image index indicator in top right (if more than 1 image for announcement)
                        if (slide.totalImagesForAnnouncement > 1)
                          Positioned(
                            top: 10,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${slide.imageIndex + 1}/${slide.totalImagesForAnnouncement}',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    ),

        // Dot indicators for banner carousel
        if (_bannerSlides.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_bannerSlides.length, (index) {
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
      ],
    );
  }

  Widget _buildBannerImage(String? imageUrl, Announcement announcement) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return _buildFallbackBannerCard(announcement);
    }

    final trimmed = imageUrl.trim();

    // Support Base64 Data URIs (e.g. data:image/jpeg;base64,...)
    if (trimmed.startsWith('data:image/') && trimmed.contains('base64,')) {
      try {
        final base64String = trimmed.split('base64,').last.trim();
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackBannerCard(announcement);
          },
        );
      } catch (e) {
        debugPrint('Base64 banner image decode error: $e');
        return _buildFallbackBannerCard(announcement);
      }
    }

    return Image.network(
      _resolveImageUrl(trimmed),
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.primaryDark.withValues(alpha: 0.1),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.sunriseGold,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Network banner image load error: $error');
        return _buildFallbackBannerCard(announcement);
      },
    );
  }

  Widget _buildDetailImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final trimmed = imageUrl.trim();
    if (trimmed.startsWith('data:image/') && trimmed.contains('base64,')) {
      try {
        final base64String = trimmed.split('base64,').last.trim();
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        );
      } catch (_) {
        return const SizedBox.shrink();
      }
    }
    return Image.network(
      _resolveImageUrl(trimmed),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  Widget _buildFallbackBannerCard(Announcement announcement) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1B38), Color(0xFF384370), Color(0xFF5A4A78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Text(
                //   announcement.subject.isNotEmpty ? announcement.subject : 'Bethesda Announcement',
                //   style: GoogleFonts.hindMadurai(
                //     fontSize: 17,
                //     fontWeight: FontWeight.bold,
                //     color: Colors.white,
                //   ),
                //   maxLines: 2,
                //   overflow: TextOverflow.ellipsis,
                // ),
                if (announcement.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  // Text(
                  //   announcement.description,
                  //   style: GoogleFonts.poppins(
                  //     fontSize: 12,
                  //     color: Colors.white.withValues(alpha: 0.85),
                  //   ),
                  //   maxLines: 2,
                  //   overflow: TextOverflow.ellipsis,
                  // ),
                ],
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
            child: const Icon(
              Icons.campaign_rounded,
              color: AppColors.sunriseGold,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.sunriseGold,
            ),
          ),
        ),
      ),
    );
  }

  void _showAnnouncementDetail(Announcement announcement, String? imageUrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (imageUrl != null && imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _buildDetailImage(imageUrl),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Text(
              //   announcement.subject,
              //   style: GoogleFonts.hindMadurai(
              //     fontSize: 20,
              //     fontWeight: FontWeight.w700,
              //     color: AppColors.primaryDark,
              //   ),
              // ),
              if (announcement.createdAt != null) ...[
                const SizedBox(height: 4),
                // Text(
                //   '${announcement.createdAt!.day}/${announcement.createdAt!.month}/${announcement.createdAt!.year}',
                //   style: GoogleFonts.poppins(
                //     fontSize: 12,
                //     color: AppColors.textMuted,
                //   ),
                // ),
              ],
              if (announcement.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                // Text(
                //   announcement.description,
                //   style: GoogleFonts.hindMadurai(
                //     fontSize: 15,
                //     height: 1.5,
                //     color: AppColors.textPrimary,
                //   ),
                // ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: AppColors.sunriseGold,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
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
