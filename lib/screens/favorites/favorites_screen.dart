import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/song_provider.dart';
import '../../providers/settings_provider.dart';
import '../lyrics/lyrics_screen.dart';
import '../home/widgets/song_card.dart';
import '../../widgets/skeleton_loaders.dart';

class FavoritesScreen extends StatefulWidget {
  final FavoriteProvider favoriteProvider;
  final SongProvider songProvider;
  final SettingsProvider settingsProvider;

  const FavoritesScreen({
    super.key,
    required this.favoriteProvider,
    required this.songProvider,
    required this.settingsProvider,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.favoriteProvider.loadFavorites();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.favoriteProvider,
      builder: (context, _) {
        final favorites = widget.favoriteProvider.favorites;
        final isLoading = widget.favoriteProvider.isLoading;

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryDark,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Favourite',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'விருப்பமான பாடல்கள் • ${favorites.length} பாடல்கள்',
                  style: GoogleFonts.hindMadurai(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.amberGlow.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          body: RefreshIndicator(
            color: AppColors.sunriseGold,
            onRefresh: () => widget.favoriteProvider.loadFavorites(),
            child: isLoading && favorites.isEmpty
                ? const SongListSkeleton(
                    count: 6,
                    padding: EdgeInsets.only(top: 10, bottom: 90),
                  )
                : favorites.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.only(top: 10, bottom: 90),
                        itemCount: favorites.length,
                        itemBuilder: (context, index) {
                          final song = favorites[index];
                          return SongCard(
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
                              await widget.favoriteProvider.removeFavorite(song);
                              widget.songProvider.updateFavoriteStatus(song.id, false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Removed "${song.title}" from favorites'),
                                    duration: const Duration(seconds: 2),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      textColor: AppColors.amberGlow,
                                      onPressed: () async {
                                        await widget.favoriteProvider.toggleFavorite(song);
                                        widget.songProvider.updateFavoriteStatus(song.id, true);
                                      },
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.favoriteRed.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 56,
                        color: AppColors.favoriteRed,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'விருப்பமான பாடல்கள் இல்லை',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.hindMadurai(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'பாடல்களில் உள்ள இதய குறியீட்டை அழுத்தி உங்கள் விருப்பமான பாடல்களை இங்கே சேர்க்கலாம்.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.hindMadurai(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
