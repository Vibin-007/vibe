import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'dart:math';

class CoverFlowAlbumList extends StatefulWidget {
  final List<AlbumModel> albums;
  final Function(AlbumModel) onAlbumTap;

  const CoverFlowAlbumList({
    super.key,
    required this.albums,
    required this.onAlbumTap,
  });

  @override
  State<CoverFlowAlbumList> createState() => _CoverFlowAlbumListState();
}

class _CoverFlowAlbumListState extends State<CoverFlowAlbumList> {
  late PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.6);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.albums.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final double dist = (_currentPage - index).abs();
        final double scale = (1 - (dist * 0.3)).clamp(0.0, 1.0);
        final double rotation = (dist * 0.5).clamp(0.0, 1.0) * pi / 12; // Max 15 degrees
        
        // Orientation of rotation depends on side
        final double actualRotation = index < _currentPage ? rotation : -rotation;
        
        // Z-Index translation (push back)
        final double translateZ = dist * -50; 

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective
            ..rotateY(actualRotation)
            ..translate(0.0, 0.0, translateZ)
            ..scale(scale),
          child: GestureDetector(
            onTap: () => widget.onAlbumTap(widget.albums[index]),
            child: _buildAlbumCard(widget.albums[index]),
          ),
        );
      },
    );
  }

  Widget _buildAlbumCard(AlbumModel album) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: QueryArtworkWidget(
                id: album.id,
                type: ArtworkType.ALBUM,
                artworkHeight: double.infinity,
                artworkWidth: double.infinity,
                keepOldArtwork: true,
                nullArtworkWidget: Container(
                  color: Colors.grey[900],
                  child: const Icon(Icons.album_rounded, size: 80, color: Colors.white24),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            album.album,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            "${album.numOfSongs} Songs",
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
