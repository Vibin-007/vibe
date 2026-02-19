import 'package:on_audio_query/on_audio_query.dart';

enum SongMood { energize, relax, focus, party, sad, unknown }

class MoodService {
  static SongMood getMood(SongModel song) {
    final genre = (song.genre ?? '').toLowerCase();
    final title = song.title.toLowerCase();
    
    // Party
    if (genre.contains('dance') || genre.contains('pop') || genre.contains('edm') || genre.contains('house') || genre.contains('club') || title.contains('party')) {
      return SongMood.party;
    }

    // Energize / Power
    if (genre.contains('rock') || genre.contains('metal') || genre.contains('workout') || genre.contains('hip-hop') || genre.contains('rap') || title.contains('power')) {
      return SongMood.energize;
    }

    // Sad
    if (genre.contains('blues') || genre.contains('sad') || genre.contains('melancholy') || title.contains('sad') || title.contains('lonely')) {
      return SongMood.sad;
    }

    // Focus
    if (genre.contains('classical') || genre.contains('piano') || genre.contains('instrumental') || genre.contains('jazz') || title.contains('focus') || title.contains('study')) {
      return SongMood.focus;
    }

    // Relax / Chill
    if (genre.contains('lofi') || genre.contains('chill') || genre.contains('ambient') || genre.contains('soul') || genre.contains('acoustic') || genre.contains('reggae')) {
      return SongMood.relax;
    }
    
    return SongMood.unknown;
  }

  static Map<SongMood, List<SongModel>> categorize(List<SongModel> songs) {
    final Map<SongMood, List<SongModel>> categories = {
      SongMood.energize: [],
      SongMood.relax: [],
      SongMood.focus: [],
      SongMood.party: [],
      SongMood.sad: [],
    };

    for (var song in songs) {
      final mood = getMood(song);
      if (mood != SongMood.unknown) {
        categories[mood]?.add(song);
      }
    }
    
    return categories;
  }
}
