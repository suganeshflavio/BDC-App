import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../providers/song_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/settings_provider.dart';
import 'home/home_screen.dart';
import 'home/all_songs_screen.dart';
import 'favorites/favorites_screen.dart';
import 'notifications/notifications_screen.dart';
import 'settings/about_us_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  late final SongProvider _songProvider;
  late final FavoriteProvider _favoriteProvider;
  late final NotificationProvider _notificationProvider;
  late final SettingsProvider _settingsProvider;

  @override
  void initState() {
    super.initState();
    _songProvider = SongProvider();
    _favoriteProvider = FavoriteProvider();
    _notificationProvider = NotificationProvider();
    _settingsProvider = SettingsProvider();

    // Initial load deferred to after first build frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _songProvider.loadSongs();
        _favoriteProvider.loadFavorites();
        _notificationProvider.loadNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        songProvider: _songProvider,
        favoriteProvider: _favoriteProvider,
        settingsProvider: _settingsProvider,
      ),
      AllSongsScreen(
        songProvider: _songProvider,
        favoriteProvider: _favoriteProvider,
        settingsProvider: _settingsProvider,
        showBackButton: false,
      ),
      FavoritesScreen(
        favoriteProvider: _favoriteProvider,
        songProvider: _songProvider,
        settingsProvider: _settingsProvider,
      ),
      NotificationsScreen(
        notificationProvider: _notificationProvider,
      ),
      AboutUsScreen(
        showBackButton: false,
        settingsProvider: _settingsProvider,
      ),
    ];

    return ListenableBuilder(
      listenable: _notificationProvider,
      builder: (context, _) {
        final unreadCount = _notificationProvider.unreadCount;

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              backgroundColor: AppColors.primaryDark,
              selectedItemColor: AppColors.activeNav,
              unselectedItemColor: AppColors.inactiveNav,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              onTap: (index) {
                setState(() => _currentIndex = index);
                if (index == 1) {
                  _songProvider.loadSongs();
                } else if (index == 2) {
                  _favoriteProvider.loadFavorites();
                } else if (index == 3) {
                  _notificationProvider.loadNotifications();
                }
              },
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.menu_book_outlined),
                  activeIcon: Icon(Icons.menu_book_rounded),
                  label: 'Songs',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.favorite_outline_rounded),
                  activeIcon: Icon(Icons.favorite_rounded),
                  label: 'Favourite',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: AppColors.favoriteBadge,
                    child: const Icon(Icons.notifications_none_rounded),
                  ),
                  activeIcon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: AppColors.favoriteBadge,
                    child: const Icon(Icons.notifications_rounded),
                  ),
                  label: 'Notification',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.info_outline_rounded),
                  activeIcon: Icon(Icons.info_rounded),
                  label: 'About',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
