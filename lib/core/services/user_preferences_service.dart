import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesService {
  static const String _keyUserName = 'user_name';
  static const String _keyProfileImage = 'profile_image';
  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyFavorites = 'favorites';
  static const String _keyRecentlyPlayed = 'recently_played';
  static const String _keyPlaylists = 'playlists';
  static const String _keyPlayCounts = 'play_counts';
  static const String _keyArtistCounts = 'artist_counts';
  static const String _keyEqEnabled = 'eq_enabled';
  static const String _keyEqBands = 'eq_bands';
  static const String _keyExcludedFolders = 'excluded_folders'; // Existing key, reusing
  static const String _keyMinDuration = 'min_song_duration'; // New key
  static const _keyPocketMode = 'pocket_mode';
  static const _keyJackInAutoplay = 'jack_in_autoplay';
  static const _keySmartDarkMode = 'smart_dark_mode';
  static const _keyAnalogVolumeTilt = 'analog_volume_tilt';
  static const String _keySearchHistory = 'search_history';
  static const String _keyEnableProfileBackground = 'enable_profile_background';


  final SharedPreferences _prefs;
  
  // Stats Debouncing
  String? _lastSongId;
  DateTime? _lastRecordTime;

  UserPreferencesService(this._prefs);

  final _dataStream = StreamController<void>.broadcast();
  Stream<void> get dataStream => _dataStream.stream;

  Future<void> setUserName(String name) async {
    await _prefs.setString(_keyUserName, name);
  }

  String? getUserName() {
    return _prefs.getString(_keyUserName);
  }

  Future<void> setProfileImagePath(String path) async {
    await _prefs.setString(_keyProfileImage, path);
    _dataStream.add(null);
  }

  String? getProfileImagePath() {
    return _prefs.getString(_keyProfileImage);
  }

  Future<void> setOnboardingComplete(bool complete) async {
    await _prefs.setBool(_keyOnboardingComplete, complete);
  }

  bool isOnboardingComplete() {
    return _prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  // Theme
  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_keyThemeMode, mode);
  }

  String getThemeMode() {
    return _prefs.getString(_keyThemeMode) ?? 'system';
  }

  static const String _keyAccentColor = 'accent_color';
  
  Future<void> setAccentColor(int colorValue) async {
    await _prefs.setInt(_keyAccentColor, colorValue);
    _dataStream.add(null);
  }

  int? getAccentColor() {
    return _prefs.getInt(_keyAccentColor);
  }

  // Favorites
  List<String> getFavorites() {
    final list = _prefs.getStringList(_keyFavorites) ?? [];
    return list.toSet().toList(); // Remove duplicates
  }

  Future<void> toggleFavorite(String songId) async {
    final favs = getFavorites(); // Already deduped
    if (favs.contains(songId)) {
      favs.remove(songId);
    } else {
      favs.add(songId);
    }
    await _prefs.setStringList(_keyFavorites, favs);
    _dataStream.add(null);
  }

  // Recently Played
  List<String> getRecentlyPlayed() {
    return _prefs.getStringList(_keyRecentlyPlayed) ?? [];
  }

  Future<void> addRecentlyPlayed(String songId, String? artist) async {
    if (isGuestMode()) return;

    final now = DateTime.now();
    
    // Check if we should increment play count (Debounce: 30 seconds for same song, or any time for new song)
    bool shouldIncrement = false;
    if (_lastSongId != songId) {
      shouldIncrement = true;
    } else if (_lastRecordTime != null && now.difference(_lastRecordTime!) > const Duration(seconds: 30)) {
      // If it's the same song, only count again if 30s have passed (e.g. it finished and replayed)
      shouldIncrement = true;
    }

    _lastSongId = songId;
    if (shouldIncrement) {
      _lastRecordTime = now;
    }

    final recent = getRecentlyPlayed();
    recent.remove(songId);
    recent.insert(0, songId);
    if (recent.length > 20) recent.removeLast();
    await _prefs.setStringList(_keyRecentlyPlayed, recent);
    
    // Increment play count only if debounce check passed
    if (shouldIncrement) {
      final counts = getPlayCounts();
      counts[songId] = (counts[songId] ?? 0) + 1;
      await _prefs.setString(_keyPlayCounts, jsonEncode(counts));
      
      if (artist != null) {
        final aCounts = getArtistCounts();
        aCounts[artist] = (aCounts[artist] ?? 0) + 1;
        await _prefs.setString(_keyArtistCounts, jsonEncode(aCounts));
      }
      _dataStream.add(null);
    }
  }

  // Profile Background
  Future<void> setEnableProfileBackground(bool enable) async {
    await _prefs.setBool(_keyEnableProfileBackground, enable);
    _dataStream.add(null);
  }

  bool getEnableProfileBackground() {
    return _prefs.getBool(_keyEnableProfileBackground) ?? false;
  }

  // Recently Played View Mode (grid/list)
  static const String _keyRecentlyPlayedViewMode = 'recently_played_view_mode';
  
  String getRecentlyPlayedViewMode() {
    return _prefs.getString(_keyRecentlyPlayedViewMode) ?? 'grid';
  }

  Future<void> setRecentlyPlayedViewMode(String mode) async {
    await _prefs.setString(_keyRecentlyPlayedViewMode, mode);
    _dataStream.add(null);
  }

  // Songs View Mode (list/grid)
  static const String _keySongsViewMode = 'songs_view_mode';
  String getSongsViewMode() => _prefs.getString(_keySongsViewMode) ?? 'list';
  Future<void> setSongsViewMode(String mode) async {
    await _prefs.setString(_keySongsViewMode, mode);
    _dataStream.add(null);
  }

  // Playlists View Mode (list/grid)
  static const String _keyPlaylistsViewMode = 'playlists_view_mode';
  String getPlaylistsViewMode() => _prefs.getString(_keyPlaylistsViewMode) ?? 'list';
  Future<void> setPlaylistsViewMode(String mode) async {
    await _prefs.setString(_keyPlaylistsViewMode, mode);
    _dataStream.add(null);
  }

  Map<String, int> getPlayCounts() {
    final raw = _prefs.getString(_keyPlayCounts);
    if (raw == null) return {};
    return Map<String, int>.from(jsonDecode(raw));
  }

  Map<String, int> getArtistCounts() {
    final raw = _prefs.getString(_keyArtistCounts);
    if (raw == null) return {};
    return Map<String, int>.from(jsonDecode(raw));
  }

  Future<void> clearPlayCounts() async {
    await _prefs.remove(_keyPlayCounts);
    await _prefs.remove(_keyArtistCounts);
    _dataStream.add(null);
  }



  // Player Settings (Shuffle/Repeat)
  static const String _keyShuffleMode = 'shuffle_mode';
  static const String _keyRepeatMode = 'repeat_mode'; // 0: off, 1: all, 2: one

  bool getShuffleMode() => _prefs.getBool(_keyShuffleMode) ?? false;
  Future<void> setShuffleMode(bool enabled) => _prefs.setBool(_keyShuffleMode, enabled);

  int getRepeatMode() => _prefs.getInt(_keyRepeatMode) ?? 0; // 0: none, 1: all, 2: one
  Future<void> setRepeatMode(int mode) => _prefs.setInt(_keyRepeatMode, mode);

  // Playlists (Simple implementation)
  Map<String, List<String>> getPlaylists() {
    final data = _prefs.getString(_keyPlaylists);
    if (data == null) return {};
    return {}; // Placeholder for interface, actual parsing done in Bloc or via getPlaylistsRaw
  }

  String? getPlaylistsRaw() {
    return _prefs.getString(_keyPlaylists);
  }

  Future<void> savePlaylists(String json) async {
    await _prefs.setString(_keyPlaylists, json);
  }
  
  // Recent Playlists context
  static const String _keyRecentPlaylists = 'recent_playlist_names';

  List<String> getRecentPlaylists() {
    return _prefs.getStringList(_keyRecentPlaylists) ?? [];
  }

  Future<void> addRecentPlaylist(String name) async {
    final list = getRecentPlaylists();
    list.remove(name);
    list.insert(0, name);
    if (list.length > 5) list.removeLast(); // Keep last 5
    await _prefs.setStringList(_keyRecentPlaylists, list);
    _dataStream.add(null);
  }

  // Folder Inclusion (Whitelist)
  static const String _keyIncludedFolders = 'included_folders';
  
  List<String> getIncludedFolders() => _prefs.getStringList(_keyIncludedFolders) ?? [];
  Future<void> setIncludedFolders(List<String> folders) async {
    await _prefs.setStringList(_keyIncludedFolders, folders);
    _dataStream.add(null);
  }

  // Backup & Restore
  Future<File?> createBackupFile() async {
    try {
      final json = exportBackup();
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/vibe_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(json);
      return file;
    } catch (e) {
      debugPrint('Backup creation failed: $e');
      return null;
    }
  }

  String exportBackup() {
    final data = {
      'user_name': getUserName(),
      'favorites': getFavorites(),
      'recently_played': getRecentlyPlayed(),
      'playlists': getPlaylistsRaw(),
      'play_counts': getPlayCounts(),
      'artist_counts': getArtistCounts(),
      'theme_mode': getThemeMode(),
      
      // New fields
      'accent_color': getAccentColor(),
      'shake_to_skip': getShakeToSkip(),
      'flip_to_pause': getFlipToPause(),
      'pocket_mode': getPocketMode(),
      'analog_volume_tilt': getAnalogVolumeTilt(),
      'guest_mode': isGuestMode(),
      'smart_dark_mode': getSmartDarkMode(),
      'jack_in_autoplay': getJackInAutoplay(),
      
      'excluded_folders': getExcludedFolders(),
      'min_song_duration': getBlacklistMinDuration(),
      'bluetooth_whitelist': getBluetoothWhitelist(),
      
      'dashboard_layout': getDashboardLayout(),
      'dashboard_hidden': getDashboardHiddenSections(),
      'navigation_layout': getNavigationLayout(),
      

    };
    return jsonEncode(data);
  }

  Future<void> importBackup(String json) async {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      
      // Core
      if (data.containsKey('user_name')) await setUserName(data['user_name']);
      if (data.containsKey('favorites')) await _prefs.setStringList(_keyFavorites, List<String>.from(data['favorites']));
      if (data.containsKey('recently_played')) await _prefs.setStringList(_keyRecentlyPlayed, List<String>.from(data['recently_played']));
      if (data.containsKey('playlists') && data['playlists'] != null) await savePlaylists(data['playlists']);
      if (data.containsKey('play_counts')) await _prefs.setString(_keyPlayCounts, jsonEncode(data['play_counts']));
      if (data.containsKey('artist_counts')) await _prefs.setString(_keyArtistCounts, jsonEncode(data['artist_counts']));
      if (data.containsKey('theme_mode')) await setThemeMode(data['theme_mode']);

      // Settings
      if (data.containsKey('accent_color') && data['accent_color'] != null) await setAccentColor(data['accent_color']);
      if (data.containsKey('shake_to_skip')) await setShakeToSkip(data['shake_to_skip']);
      if (data.containsKey('flip_to_pause')) await setFlipToPause(data['flip_to_pause']);
      if (data.containsKey('pocket_mode')) await setPocketMode(data['pocket_mode']);
      if (data.containsKey('analog_volume_tilt')) await setAnalogVolumeTilt(data['analog_volume_tilt']);
      if (data.containsKey('guest_mode')) await setGuestMode(data['guest_mode']);
      if (data.containsKey('smart_dark_mode')) await setSmartDarkMode(data['smart_dark_mode']);
      if (data.containsKey('jack_in_autoplay')) await setJackInAutoplay(data['jack_in_autoplay']);

      // Library
      if (data.containsKey('excluded_folders')) await setExcludedFolders(List<String>.from(data['excluded_folders']));
      if (data.containsKey('min_song_duration')) await setBlacklistMinDuration(data['min_song_duration']);
      if (data.containsKey('bluetooth_whitelist')) {
        await _prefs.setStringList(_keyBluetoothWhitelist, List<String>.from(data['bluetooth_whitelist']));
        _dataStream.add(null);
      }

      // UI Layouts
      if (data.containsKey('dashboard_layout')) await setDashboardLayout(List<String>.from(data['dashboard_layout']));
      if (data.containsKey('dashboard_hidden')) await setDashboardHiddenSections(List<String>.from(data['dashboard_hidden']));
      if (data.containsKey('navigation_layout')) await setNavigationLayout(List<String>.from(data['navigation_layout']));

      // Memories


    } catch (e) {
      debugPrint('Import backup failed: $e');
      rethrow;
    }
  }

  // Folder Exclusion
  List<String> getExcludedFolders() => _prefs.getStringList(_keyExcludedFolders) ?? [];
  Future<void> setExcludedFolders(List<String> folders) async {
    await _prefs.setStringList(_keyExcludedFolders, folders);
    _dataStream.add(null); // Notify filtering to update
  }

  // Blacklist Duration
  int getBlacklistMinDuration() => _prefs.getInt(_keyMinDuration) ?? 30; // Default 30 seconds
  Future<void> setBlacklistMinDuration(int seconds) async {
    await _prefs.setInt(_keyMinDuration, seconds);
    _dataStream.add(null);
  }

  // Search History
  List<String> getSearchHistory() => _prefs.getStringList(_keySearchHistory) ?? [];
  Future<void> addSearchTerm(String term) async {
    if (term.isEmpty) return;
    final history = getSearchHistory();
    history.remove(term);
    history.insert(0, term);
    if (history.length > 10) history.removeLast();
    await _prefs.setStringList(_keySearchHistory, history);
  }
  Future<void> clearSearchHistory() => _prefs.remove(_keySearchHistory);

  // Dashboard Layout
  static const String _keyDashboardLayout = 'dashboard_layout';
  static const String _keyDashboardHidden = 'dashboard_hidden';

  List<String> getDashboardLayout() {
    var layout = _prefs.getStringList(_keyDashboardLayout);
    if (layout == null) {
      return ['center_player', 'playlists', 'favorites', 'recent'];
    }
    // Migration: Ensure center_player exists if not present (for existing users)
    if (!layout.contains('center_player')) {
      layout = ['center_player', ...layout];
      setDashboardLayout(layout); // Save the migration
    }
    return layout;
  }

  Future<void> setDashboardLayout(List<String> layout) async {
    await _prefs.setStringList(_keyDashboardLayout, layout);
    _dataStream.add(null);
  }

  List<String> getDashboardHiddenSections() {
    return _prefs.getStringList(_keyDashboardHidden) ?? [];
  }

  Future<void> setDashboardHiddenSections(List<String> hidden) async {
    await _prefs.setStringList(_keyDashboardHidden, hidden);
    _dataStream.add(null);
  }

  // Navigation Layout
  static const String _keyNavigationLayout = 'navigation_layout';

  List<String> getNavigationLayout() {
    return _prefs.getStringList(_keyNavigationLayout) ?? ['home', 'songs', 'playlists', 'account'];
  }

  Future<void> setNavigationLayout(List<String> layout) async {
    await _prefs.setStringList(_keyNavigationLayout, layout);
    _dataStream.add(null);
  }

  // Bluetooth Auto-Play
  static const String _keyBluetoothWhitelist = 'bluetooth_whitelist';

  List<String> getBluetoothWhitelist() {
    return _prefs.getStringList(_keyBluetoothWhitelist) ?? [];
  }

  Future<void> addBluetoothDevice(String name) async {
    final list = getBluetoothWhitelist();
    if (!list.contains(name)) {
      list.add(name);
      await _prefs.setStringList(_keyBluetoothWhitelist, list);
      _dataStream.add(null);
    }
  }

  Future<void> removeBluetoothDevice(String name) async {
    final list = getBluetoothWhitelist();
    if (list.contains(name)) {
      list.remove(name);
      await _prefs.setStringList(_keyBluetoothWhitelist, list);
      _dataStream.add(null);
    }
  }

  // Default Songs View (Songs vs Folders)
  static const String _keyDefaultSongsViewFolders = 'default_songs_view_folders';
  bool isFoldersDefault() => _prefs.getBool(_keyDefaultSongsViewFolders) ?? true;
  Future<void> setFoldersDefault(bool isFolders) => _prefs.setBool(_keyDefaultSongsViewFolders, isFolders);

  // Guest Mode
  static const String _keyGuestMode = 'guest_mode';
  bool isGuestMode() => _prefs.getBool(_keyGuestMode) ?? false;
  Future<void> setGuestMode(bool enabled) async {
    await _prefs.setBool(_keyGuestMode, enabled);
    _dataStream.add(null);
  }

  // Shake to Skip
  static const String _keyShakeToSkip = 'shake_to_skip';
  bool getShakeToSkip() => _prefs.getBool(_keyShakeToSkip) ?? false;
  Future<void> setShakeToSkip(bool enabled) async {
    await _prefs.setBool(_keyShakeToSkip, enabled);
    _dataStream.add(null);
  }

  // Flip to Pause
  static const String _keyFlipToPause = 'flip_to_pause';
  bool getFlipToPause() => _prefs.getBool(_keyFlipToPause) ?? false;
  Future<void> setFlipToPause(bool enabled) async {
    await _prefs.setBool(_keyFlipToPause, enabled);
    _dataStream.add(null);
  }

  // Pocket Mode
  bool getPocketMode() => _prefs.getBool(_keyPocketMode) ?? false;
  Future<void> setPocketMode(bool enabled) async {
    await _prefs.setBool(_keyPocketMode, enabled);
    _dataStream.add(null);
  }

  bool getJackInAutoplay() => _prefs.getBool(_keyJackInAutoplay) ?? true;
  Future<void> setJackInAutoplay(bool enabled) async {
    await _prefs.setBool(_keyJackInAutoplay, enabled);
    _dataStream.add(null);
  }

  bool getSmartDarkMode() => _prefs.getBool(_keySmartDarkMode) ?? true;
  Future<void> setSmartDarkMode(bool enabled) async {
    await _prefs.setBool(_keySmartDarkMode, enabled);
    _dataStream.add(null);
  }
  
  bool getAnalogVolumeTilt() => _prefs.getBool(_keyAnalogVolumeTilt) ?? false;
  Future<void> setAnalogVolumeTilt(bool enabled) async {
    await _prefs.setBool(_keyAnalogVolumeTilt, enabled);
    _dataStream.add(null);
  }

  // Letters to Myself (Memories)

}
