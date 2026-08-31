import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:muses/core/utils/artwork_manager.dart';

class AlbumArt extends StatelessWidget {
  const AlbumArt({
    super.key,
    this.artwork,
    this.path,
    this.hasArtwork = false,
    this.size,
    this.borderRadius = 0,
  });

  final Uint8List? artwork;
  final String? path;
  final bool hasArtwork;
  final double? size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    // Decode at display resolution: width/height only affect layout, so
    // without a decode-size cap Flutter decodes the FULL artwork
    // (often 2000-3000px) for every 48px thumbnail - the main source of
    // scroll lag in the library and queue lists.
    //
    // Use ResizeImagePolicy.fit, NOT the default `exact` (which is what
    // Image's cacheWidth/cacheHeight produce). `exact` rescales the decode
    // to precisely cacheWidth x cacheHeight - like BoxFit.fill - so
    // non-square album art (e.g. 500x512) is stretched at the pixel level
    // and BoxFit.cover then has nothing left to crop. That showed up as
    // squished art in the queue page and mini player.
    final int? cacheSize = size != null
        ? (size! * MediaQuery.devicePixelRatioOf(context)).round()
        : null;

    ImageProvider<Object> decodeAt(ImageProvider<Object> provider) =>
        cacheSize == null
            ? provider
            : ResizeImage(
                provider,
                width: cacheSize,
                height: cacheSize,
                policy: ResizeImagePolicy.fit,
              );

    if (artwork != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image(
          image: decodeAt(MemoryImage(artwork!)),
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    }

    if (path != null) {
      final String p = path!;
      if (p.toLowerCase().endsWith('.jpg') || 
          p.toLowerCase().endsWith('.jpeg') || 
          p.toLowerCase().endsWith('.png') ||
          p.toLowerCase().endsWith('.webp')) {
         return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image(
              image: decodeAt(FileImage(File(p))),
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
            ),
         );
      }
    
      if (hasArtwork) {
        return FutureBuilder<File?>(
          future: ArtworkManager().getArtworkFile(p),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: Image(
                  image: decodeAt(FileImage(snapshot.data!)),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              );
            }
            return _buildPlaceholder(context);
          },
        );
      }
    }

    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(Icons.music_note, size: size != null ? size! / 2 : 24),
    );
  }
}
