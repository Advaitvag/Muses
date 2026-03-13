import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muses/features/library/bloc/library_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:muses/core/utils/artwork_manager.dart';
import 'package:muses/features/library/models/song.dart';

class EditMetadataDialog extends StatefulWidget {
  const EditMetadataDialog({required this.song, super.key});

  final Song song;

  @override
  State<EditMetadataDialog> createState() => _EditMetadataDialogState();
}

class _EditMetadataDialogState extends State<EditMetadataDialog> {
  late Future<Metadata> _metadataFuture;

  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _albumController = TextEditingController();
  final _albumArtistController = TextEditingController();
  final _yearController = TextEditingController();
  final _trackNumberController = TextEditingController();
  final _discNumberController = TextEditingController();
  final _genreController = TextEditingController();

  Picture? _artwork;
  bool _artworkChanged = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _metadataFuture = MetadataGod.readMetadata(file: widget.song.path);
    _metadataFuture.then((metadata) {
      _titleController.text = metadata.title ?? widget.song.title ?? '';
      _artistController.text = metadata.artist ?? widget.song.artist ?? '';
      _albumController.text = metadata.album ?? widget.song.album ?? '';
      _albumArtistController.text = metadata.albumArtist ?? '';
      _yearController.text = metadata.year?.toString() ?? '';
      _trackNumberController.text = metadata.trackNumber?.toString() ?? '';
      _discNumberController.text = metadata.discNumber?.toString() ?? '';
      _genreController.text = metadata.genre ?? '';
      if (mounted) {
        setState(() {
          _artwork = metadata.picture;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _albumArtistController.dispose();
    _yearController.dispose();
    _trackNumberController.dispose();
    _discNumberController.dispose();
    _genreController.dispose();
    super.dispose();
  }

  Future<void> _pickArtwork() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      setState(() {
        _artwork = Picture(
          data: bytes,
          mimeType: 'image/${result.files.single.extension ?? "jpeg"}',
        );
        _artworkChanged = true;
      });
    }
  }

  void _removeArtwork() {
    setState(() {
      _artwork = null;
      _artworkChanged = true;
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    try {
      final metadata = Metadata(
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        artist: _artistController.text.trim().isEmpty
            ? null
            : _artistController.text.trim(),
        album: _albumController.text.trim().isEmpty
            ? null
            : _albumController.text.trim(),
        albumArtist: _albumArtistController.text.trim().isEmpty
            ? null
            : _albumArtistController.text.trim(),
        year: int.tryParse(_yearController.text.trim()),
        trackNumber: int.tryParse(_trackNumberController.text.trim()),
        discNumber: int.tryParse(_discNumberController.text.trim()),
        genre: _genreController.text.trim().isEmpty
            ? null
            : _genreController.text.trim(),
        picture: _artwork,
      );

      await MetadataGod.writeMetadata(
        file: widget.song.path,
        metadata: metadata,
      );

      // Force update the file's modification time on disk
      try {
        await File(widget.song.path).setLastModified(DateTime.now());
      } catch (e) {
        debugPrint('Failed to set last modified time: $e');
      }

      // Invalidate artwork cache if artwork changed
      if (_artworkChanged) {
        final artworkManager = ArtworkManager();
        final fileId = widget.song.path.hashCode;
        final cacheFile = artworkManager.getCacheFile(widget.song.path, fileId);
        if (await cacheFile.exists()) {
          await cacheFile.delete();
        }
      }

      // Return the updated song object
      if (mounted) {
        final updatedSong = widget.song.copyWith(
          title: metadata.title,
          artist: metadata.artist,
          album: metadata.album,
          year: metadata.year,
          trackNumber: metadata.trackNumber,
          discNumber: metadata.discNumber,
          hasArtwork: _artwork != null,
          dateModified: DateTime.now(),
        );
        context.read<LibraryBloc>().add(LoadLibrary());
        Navigator.of(context).pop(updatedSong);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving metadata: $e')));
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return AlertDialog(
      title: const Text('Edit Metadata'),
      scrollable: true,
      content: SizedBox(
        width: isMobile ? screenWidth : 500,
        child: FutureBuilder(
          future: _metadataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Artwork Section
                Wrap(
                  spacing: 20,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _artwork != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _artwork!.data,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.music_note, size: 64),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 180),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: isMobile
                            ? CrossAxisAlignment.center
                            : CrossAxisAlignment.start,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: _pickArtwork,
                            icon: const Icon(Icons.image, size: 18),
                            label: const Text('Pick Artwork'),
                          ),
                          if (_artwork != null) ...[
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _removeArtwork,
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text('Remove'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTextField('Title', _titleController),
                _buildTextField('Artist', _artistController),
                _buildTextField('Album', _albumController),
                _buildTextField('Album Artist', _albumArtistController),

                // Numeric fields with Wrap for responsiveness
                Wrap(
                  spacing: 16,
                  runSpacing: 0,
                  children: [
                    SizedBox(
                      width: 100,
                      child: _buildTextField(
                        'Year',
                        _yearController,
                        isNumber: true,
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: _buildTextField(
                        'Track #',
                        _trackNumberController,
                        isNumber: true,
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: _buildTextField(
                        'Disc #',
                        _discNumberController,
                        isNumber: true,
                      ),
                    ),
                  ],
                ),
                _buildTextField('Genre', _genreController),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
