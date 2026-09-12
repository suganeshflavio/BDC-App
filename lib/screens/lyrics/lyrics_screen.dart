import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/song.dart';
import '../../models/song_verse.dart';
import '../../providers/settings_provider.dart';
import '../../providers/song_provider.dart';
import '../../providers/favorite_provider.dart';
import '../settings/font_size_dialog.dart';
import '../../widgets/skeleton_loaders.dart';

class LyricsScreen extends StatefulWidget {
  final Song song;
  final SettingsProvider settingsProvider;
  final SongProvider songProvider;
  final FavoriteProvider favoriteProvider;

  const LyricsScreen({
    super.key,
    required this.song,
    required this.settingsProvider,
    required this.songProvider,
    required this.favoriteProvider,
  });

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  late Song _currentSong;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentSong = widget.song;
    _loadVersesIfNeeded();
  }

  Future<void> _loadVersesIfNeeded() async {
    if (_currentSong.songVerses.isEmpty) {
      setState(() => _isLoading = true);
      final fullSong = await widget.songProvider.getSongDetail(_currentSong.id);
      if (mounted && fullSong != null) {
        setState(() {
          _currentSong = fullSong;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleFavorite() {
    setState(() {
      _currentSong.isFavorite = !_currentSong.isFavorite;
    });
    widget.songProvider.toggleFavorite(_currentSong);
    widget.favoriteProvider.loadFavorites();
  }

  void _copyAllLyrics() {
    final buffer = StringBuffer();
    buffer.writeln('${_currentSong.songNumber}. ${_currentSong.title}');
    if (_currentSong.titleThanglish.isNotEmpty) {
      buffer.writeln(_currentSong.titleThanglish);
    }
    buffer.writeln();

    if (_currentSong.songVerses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'பாடல் வரிகள் பதிவேற்றப்படுகிறது...',
            style: GoogleFonts.hindMadurai(color: Colors.white),
          ),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    for (final verse in _currentSong.songVerses) {
      if (verse.isIntro) {
        buffer.writeln(verse.content.trim());
        buffer.writeln();
      } else if (verse.isChorus) {
        buffer.writeln('[பல்லவி / Chorus]');
        buffer.writeln(verse.content.trim());
        buffer.writeln();
      } else {
        final prefix = verse.verseNumber != null ? '${verse.verseNumber}. ' : '';
        buffer.writeln('$prefix${verse.content.trim()}');
        buffer.writeln();
      }
    }

    final fullText = buffer.toString().trim();
    Clipboard.setData(ClipboardData(text: fullText));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.sunriseGold, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'பாடல் வரிகள் நகலெடுக்கப்பட்டது • Lyrics copied!',
                style: GoogleFonts.hindMadurai(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settingsProvider,
      builder: (context, _) {
        final currentFontSize = widget.settingsProvider.fontSize;

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryDark,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            titleSpacing: 0,
            title: Text(
              '${_currentSong.songNumber}. ${_currentSong.title}',
              style: GoogleFonts.hindMadurai(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              // Font Size Quick Selector
              IconButton(
                icon: const Icon(Icons.format_size_rounded, color: AppColors.amberGlow),
                tooltip: 'Adjust Font Size (${currentFontSize.toInt()}pt)',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => FontSizeDialog(
                      settingsProvider: widget.settingsProvider,
                    ),
                  );
                },
              ),
              // Favorite Button
              IconButton(
                icon: Icon(
                  _currentSong.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: _currentSong.isFavorite
                      ? AppColors.favoriteRed
                      : Colors.white,
                ),
                tooltip: _currentSong.isFavorite
                    ? 'Remove from Favorites'
                    : 'Add to Favorites',
                onPressed: _toggleFavorite,
              ),
              // Copy All Lyrics Button
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: Colors.white),
                tooltip: 'Copy all lyrics • பாடல் வரிகளை நகலெடு',
                onPressed: _copyAllLyrics,
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: _isLoading
              ? const LyricsScreenSkeleton()
              : _buildLyricsContent(currentFontSize),
        );
      },
    );
  }

  Widget _buildLyricsContent(double fontSize) {
    final verses = _currentSong.songVerses;

    if (verses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_rounded, size: 64, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text(
                _currentSong.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.hindMadurai(
                  fontSize: fontSize + 2,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'பாடல் வரிகள் பதிவேற்றப்படுகிறது...',
                style: GoogleFonts.hindMadurai(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryDark,
                  AppColors.celestialBlue,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.sunriseGold.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.amberGlow.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        'பாடல் எண்: ${_currentSong.songNumber}',
                        style: GoogleFonts.poppins(
                          color: AppColors.amberGlow,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _copyAllLyrics,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.copy_rounded, size: 13, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(
                              'Copy Lyrics',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _currentSong.title,
                  style: GoogleFonts.hindMadurai(
                    fontSize: fontSize + 4,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                if (_currentSong.titleThanglish.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _currentSong.titleThanglish,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.amberGlow.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Render Verses
          ...verses.map((verse) => _buildVerseItem(verse, fontSize)),

          const SizedBox(height: 40),

          // Bottom Amen / Blessing Footer
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Text(
                '✦ அல்லேலூயா • ஆமென் ✦',
                style: GoogleFonts.hindMadurai(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sunriseAmber,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildVerseItem(SongVerse verse, double fontSize) {
    if (verse.isIntro) {
      // Intro block
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.sunriseGold.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.sunriseGold.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              verse.content,
              textAlign: TextAlign.center,
              style: GoogleFonts.hindMadurai(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
                height: 1.65,
              ),
            ),
          ],
        ),
      );
    } else if (verse.isChorus) {
      // Chorus block
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.sunriseGold.withValues(alpha: 0.8),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.sunriseGold.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.sunriseGold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'பல்லவி (Chorus)',
                    style: GoogleFonts.hindMadurai(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              verse.content,
              style: GoogleFonts.hindMadurai(
                fontSize: fontSize + 1,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.65,
              ),
            ),
          ],
        ),
      );
    } else {
      // Numbered verse
      final numberStr = verse.verseNumber != null ? '${verse.verseNumber}' : '';
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (numberStr.isNotEmpty) ...[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  numberStr,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              verse.content,
              style: GoogleFonts.hindMadurai(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                height: 1.65,
              ),
            ),
          ],
        ),
      );
    }
  }
}
