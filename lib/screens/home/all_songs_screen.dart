import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/song_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/settings_provider.dart';
import '../lyrics/lyrics_screen.dart';
import 'widgets/song_card.dart';
import '../../widgets/skeleton_loaders.dart';

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
            titleSpacing: (widget.showBackButton ?? Navigator.of(context).canPop()) ? 0 : 16,
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
              const SizedBox(width: 8),
            ],
          ),
          body: RefreshIndicator(
            color: AppColors.sunriseGold,
            onRefresh: () => widget.songProvider.loadSongs(
              query: _searchController.text.isNotEmpty
                  ? _searchController.text
                  : null,
              forceRefresh: true,
            ),
            child: isLoading && songs.isEmpty
                ? const SongListSkeleton(
                    count: 8,
                    padding: EdgeInsets.only(top: 10, bottom: 90),
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
    return Container(
      height: 42,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.sunriseGold.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: AppColors.amberGlow,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: GoogleFonts.poppins(color: Colors.black, fontSize: 14),
              cursorColor: AppColors.sunriseGold,
              decoration: InputDecoration(
                hintText: 'Search here...',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.black.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (val) {
                widget.songProvider.loadSongs(query: val);
              },
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                widget.songProvider.loadSongs(query: null);
                setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.cancel_rounded,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 18,
                ),
              ),
            ),
        ],
      ),
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
                padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 36.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.sunriseGold.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.search_off_rounded,
                        size: 54,
                        color: AppColors.sunriseAmber,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'பாடல்கள் எதுவும் கிடைக்கவில்லை',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.hindMadurai(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _searchController.text.trim().isNotEmpty
                          ? 'No songs found matching "${_searchController.text.trim()}"'
                          : 'No songs available in catalog',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        _searchController.clear();
                        widget.songProvider.loadSongs(query: null);
                        setState(() => _isSearchOpen = false);
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        // 'அனைத்து பாடல்களையும் காட்டு',
                        "Show all",
                        style: GoogleFonts.hindMadurai(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: AppColors.amberGlow,
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
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
    );
  }
}
