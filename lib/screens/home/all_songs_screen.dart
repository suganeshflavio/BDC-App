import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/song_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/settings_provider.dart';
import '../lyrics/lyrics_screen.dart';
import 'widgets/song_card.dart';

class AllSongsScreen extends StatefulWidget {
  final SongProvider songProvider;
  final FavoriteProvider favoriteProvider;
  final SettingsProvider settingsProvider;
  final bool autoFocusSearch;
  final bool? showBackButton;

  const AllSongsScreen({
    super.key,
    required this.songProvider,
    required this.favoriteProvider,
    required this.settingsProvider,
    this.autoFocusSearch = false,
    this.showBackButton,
  });

  @override
  State<AllSongsScreen> createState() => _AllSongsScreenState();
}

class _AllSongsScreenState extends State<AllSongsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSearchOpen = false;
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _isSearchOpen = widget.autoFocusSearch;
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.songProvider.songs.isEmpty) {
        widget.songProvider.loadSongs();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.offset > 300 && !_showScrollToTop) {
      setState(() => _showScrollToTop = true);
    } else if (_scrollController.offset <= 300 && _showScrollToTop) {
      setState(() => _showScrollToTop = false);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.songProvider,
      builder: (context, _) {
        final songs = widget.songProvider.songs;
        final isLoading = widget.songProvider.isLoading;

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryDark,
            elevation: 0,
            leading: (widget.showBackButton ?? Navigator.of(context).canPop())
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                : null,
            titleSpacing: 0,
            title: _isSearchOpen
                ? _buildSearchField()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Songs Catalog',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'அனைத்து பாடல்கள் • ${songs.length} பாடல்கள்',
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
                icon: Icon(
                  _isSearchOpen ? Icons.close_rounded : Icons.search_rounded,
                  color: Colors.white,
                ),
                tooltip: _isSearchOpen ? 'Close Search' : 'Search Songs',
                onPressed: () {
                  setState(() {
                    _isSearchOpen = !_isSearchOpen;
                    if (!_isSearchOpen) {
                      _searchController.clear();
                      widget.songProvider.loadSongs(query: null);
                    }
                  });
                },
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: RefreshIndicator(
            color: AppColors.sunriseGold,
            onRefresh: () => widget.songProvider.loadSongs(
              query: _searchController.text.isNotEmpty
                  ? _searchController.text
                  : null,
            ),
            child: isLoading && songs.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.sunriseGold,
                    ),
                  )
                : songs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.only(top: 10, bottom: 90),
                        itemCount: songs.length,
                        itemBuilder: (context, index) {
                          final song = songs[index];
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
                              await widget.songProvider.toggleFavorite(song);
                              await widget.favoriteProvider.loadFavorites();
                            },
                          );
                        },
                      ),
          ),
          floatingActionButton: _showScrollToTop
              ? FloatingActionButton.small(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: AppColors.sunriseGold,
                  elevation: 4,
                  tooltip: 'Scroll to Top',
                  onPressed: _scrollToTop,
                  child: const Icon(Icons.arrow_upward_rounded),
                )
              : null,
        );
      },
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
      cursorColor: AppColors.sunriseGold,
      decoration: InputDecoration(
        hintText: 'Search Tamil (அக்கினி) or Thanglish...',
        hintStyle: GoogleFonts.poppins(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 13,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        filled: false,
      ),
      onChanged: (val) {
        widget.songProvider.loadSongs(query: val);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'பாடல்கள் எதுவும் கிடைக்கவில்லை',
              style: GoogleFonts.hindMadurai(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No songs found matching "${_searchController.text}"',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                widget.songProvider.loadSongs(query: null);
                setState(() => _isSearchOpen = false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: AppColors.amberGlow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('அனைத்து பாடல்களையும் காட்டு'),
            ),
          ],
        ),
      ),
    );
  }
}
