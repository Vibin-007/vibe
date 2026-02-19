import 'package:on_audio_query/on_audio_query.dart';

class AudioQueryService {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  Future<bool> checkAndRequestPermissions({bool retry = false}) async {
    return await _audioQuery.checkAndRequest(
      retryRequest: retry,
    );
  }

  Future<List<SongModel>> getSongs() async {
    return await _audioQuery.querySongs(
      sortType: SongSortType.DATE_ADDED,
      orderType: OrderType.DESC_OR_GREATER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
  }

  Future<List<AlbumModel>> getAlbums() async {
    return await _audioQuery.queryAlbums(
      sortType: AlbumSortType.ALBUM,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
  }

  Future<List<ArtistModel>> getArtists() async {
    return await _audioQuery.queryArtists(
      sortType: ArtistSortType.ARTIST,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
  }
}
