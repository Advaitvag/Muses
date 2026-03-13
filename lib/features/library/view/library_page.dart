import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muses/features/library/bloc/library_bloc.dart';
import 'package:muses/features/library/bloc/playlists_bloc.dart';
import 'package:muses/features/library/models/song.dart';
import 'package:muses/features/library/models/album.dart';
import 'package:muses/features/library/models/artist.dart';
import 'package:muses/features/library/models/playlist.dart';
import 'package:muses/features/library/widgets/album_art.dart';
import 'package:muses/features/library/widgets/song_options_bottom_sheet.dart';
import 'package:muses/features/library/widgets/sort_menu.dart';
import 'package:muses/features/player/bloc/player_bloc.dart';
import 'package:muses/features/theme/theme_bloc.dart';

enum LibraryViewType {
  main,
  songs,
  albums,
  artists,
  playlists,
  playlistDetails,
  albumDetails,
  artistDetails
}

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  static final GlobalKey<LibraryPageState> globalKey = GlobalKey<LibraryPageState>();

  static LibraryPageState? of(BuildContext context) =>
      context.findAncestorStateOfType<LibraryPageState>();

  @override
  State<LibraryPage> createState() => LibraryPageState();
}

class LibraryPageState extends State<LibraryPage> {
  LibraryPageState() : super();

  @override
  void initState() {
    super.initState();
  }
  LibraryViewType _currentView = LibraryViewType.main;
  Playlist? _selectedPlaylist;
  Album? _selectedAlbum;
  Artist? _selectedArtist;

  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  void goBack() {
    if (_isSearching) {
      _stopSearch();
      return;
    }
    switch (_currentView) {
      case LibraryViewType.playlistDetails:
        setView(LibraryViewType.playlists);
        break;
      case LibraryViewType.albumDetails:
        setView(LibraryViewType.albums);
        break;
      case LibraryViewType.artistDetails:
        setView(LibraryViewType.artists);
        break;
      case LibraryViewType.songs:
      case LibraryViewType.albums:
      case LibraryViewType.artists:
      case LibraryViewType.playlists:
        setView(LibraryViewType.main);
        break;
      case LibraryViewType.main:
        break;
    }
  }

  bool get canGoBack => _isSearching || _currentView != LibraryViewType.main;

  void setView(LibraryViewType view,
      {Playlist? playlist, Album? album, Artist? artist}) {
    setState(() {
      _currentView = view;
      _selectedPlaylist = playlist;
      _selectedAlbum = album;
      _selectedArtist = artist;
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void enterSearch() {
    _startSearch();
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTopNav = context.read<ThemeBloc>().state.navigationBarPosition ==
        NavigationBarPosition.top;

    return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          toolbarHeight: isTopNav ? 48 : null,
          scrolledUnderElevation: 0,
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                )
              : Text(_getTitle()),
          backgroundColor: Colors.transparent,
          leading: _currentView != LibraryViewType.main || _isSearching
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: goBack,
                )
              : null,
          actions: [
            if (!_isSearching) ...[
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: _startSearch,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Rescan Library',
                onPressed: () {
                  context.read<LibraryBloc>().add(LoadLibrary());
                },
              ),
              const SortMenu(),
            ],
            if (_currentView == LibraryViewType.playlists && !_isSearching)
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showCreatePlaylistDialog(context),
              ),
          ],
        ),
        body: BlocBuilder<LibraryBloc, LibraryState>(
          builder: (context, libraryState) {
            if (libraryState is LibraryLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (libraryState is LibraryLoaded) {
              if (libraryState.songs.isEmpty) {
                return _buildEmptyState(context);
              }

              return BlocBuilder<PlaylistsBloc, PlaylistsState>(
                builder: (context, playlistsState) {
                  switch (_currentView) {
                    case LibraryViewType.main:
                      final filteredPlaylists = playlistsState.playlists
                          .where((p) => p.name.toLowerCase().contains(_searchQuery))
                          .toList();
                      final filteredAlbums = libraryState.albums
                          .where((a) => a.name.toLowerCase().contains(_searchQuery) || 
                                       a.artist.toLowerCase().contains(_searchQuery))
                          .toList();
                      final filteredArtists = libraryState.artists
                          .where((a) => a.name.toLowerCase().contains(_searchQuery))
                          .toList();
                      final filteredSongs = libraryState.sortedSongs
                          .where((s) => (s.title ?? '').toLowerCase().contains(_searchQuery) || 
                                       (s.artist ?? '').toLowerCase().contains(_searchQuery))
                          .toList();

                      return _LibraryMainView(
                        state: libraryState,
                        playlists: filteredPlaylists,
                        albums: filteredAlbums,
                        artists: filteredArtists,
                        songs: filteredSongs,
                        onViewAllSongs: () => setView(LibraryViewType.songs),
                        onViewAllAlbums: () => setView(LibraryViewType.albums),
                        onViewAllArtists: () => setView(LibraryViewType.artists),
                        onViewAllPlaylists: () =>
                            setView(LibraryViewType.playlists),
                        onPlaylistTap: (p) => setView(
                            LibraryViewType.playlistDetails,
                            playlist: p),
                        onAlbumTap: (a) =>
                            setView(LibraryViewType.albumDetails, album: a),
                        onArtistTap: (ar) => setView(
                            LibraryViewType.artistDetails,
                            artist: ar),
                        onCreatePlaylist: () => _showCreatePlaylistDialog(context),
                      );
                    case LibraryViewType.songs:
                      final filteredSongs = libraryState.sortedSongs
                          .where((s) => (s.title ?? '').toLowerCase().contains(_searchQuery) || 
                                       (s.artist ?? '').toLowerCase().contains(_searchQuery))
                          .toList();
                      return _SongsView(songs: filteredSongs);
                    case LibraryViewType.albums:
                      final filteredAlbums = libraryState.albums
                          .where((a) => a.name.toLowerCase().contains(_searchQuery) || 
                                       a.artist.toLowerCase().contains(_searchQuery))
                          .toList();
                      return _AlbumsView(
                        albums: filteredAlbums,
                        onAlbumTap: (a) =>
                            setView(LibraryViewType.albumDetails, album: a),
                      );
                    case LibraryViewType.artists:
                      final filteredArtists = libraryState.artists
                          .where((a) => a.name.toLowerCase().contains(_searchQuery))
                          .toList();
                      return _ArtistsView(
                        artists: filteredArtists,
                        onArtistTap: (ar) => setView(
                            LibraryViewType.artistDetails,
                            artist: ar),
                      );
                    case LibraryViewType.playlists:
                      final filteredPlaylists = playlistsState.playlists
                          .where((p) => p.name.toLowerCase().contains(_searchQuery))
                          .toList();
                      return _PlaylistsView(
                        playlists: filteredPlaylists,
                        onPlaylistTap: (p) => setView(
                            LibraryViewType.playlistDetails,
                            playlist: p),
                      );
                    case LibraryViewType.playlistDetails:
                      if (_selectedPlaylist == null) {
                        setView(LibraryViewType.main);
                        return const SizedBox.shrink();
                      }
                      final currentPlaylist =
                          playlistsState.playlists.firstWhere(
                        (p) => p.id == _selectedPlaylist!.id,
                        orElse: () => _selectedPlaylist!,
                      );
                      final playlistSongs = libraryState.songs
                          .where((s) => currentPlaylist.songPaths.contains(s.path))
                          .toList();
                      final filteredSongs = playlistSongs
                          .where((s) => (s.title ?? '').toLowerCase().contains(_searchQuery) || 
                                       (s.artist ?? '').toLowerCase().contains(_searchQuery))
                          .toList();

                      return _PlaylistDetailsView(
                        playlist: currentPlaylist,
                        librarySongs: filteredSongs,
                        sortType: libraryState.sortType,
                        ascending: libraryState.ascending,
                      );
                    case LibraryViewType.albumDetails:
                      if (_selectedAlbum == null) {
                        setView(LibraryViewType.main);
                        return const SizedBox.shrink();
                      }
                      // Look up the latest album data from libraryState
                      var currentAlbum = libraryState.albums.cast<Album?>().firstWhere(
                        (a) => a?.name == _selectedAlbum!.name && a?.artist == _selectedAlbum!.artist,
                        orElse: () => null,
                      );

                      // If not found (renamed?), try to find an album containing at least one song from the old album
                      if (currentAlbum == null && _selectedAlbum!.songs.isNotEmpty) {
                        final firstSongPath = _selectedAlbum!.songs.first.path;
                        currentAlbum = libraryState.albums.cast<Album?>().firstWhere(
                          (a) => a!.songs.any((s) => s.path == firstSongPath),
                          orElse: () => null,
                        );
                      }

                      currentAlbum ??= _selectedAlbum!;

                      // Update selection if it changed
                      if (currentAlbum != _selectedAlbum) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _currentView == LibraryViewType.albumDetails) {
                            setState(() { _selectedAlbum = currentAlbum; });
                          }
                        });
                      }

                      final filteredSongs = currentAlbum.songs
                          .where((s) => (s.title ?? '').toLowerCase().contains(_searchQuery) || 
                                       (s.artist ?? '').toLowerCase().contains(_searchQuery))
                          .toList();

                      final albumArtistNames = currentAlbum.songs
                          .expand((s) => s.artistList)
                          .toSet();
                      
                      final albumArtists = libraryState.artists
                          .where((a) => albumArtistNames.contains(a.name))
                          .toList();

                      return _AlbumDetailsView(
                        album: currentAlbum.copyWithSongs(filteredSongs),
                        sortType: libraryState.sortType,
                        ascending: libraryState.ascending,
                        artists: albumArtists,
                      );
                    case LibraryViewType.artistDetails:
                      if (_selectedArtist == null) {
                        setView(LibraryViewType.main);
                        return const SizedBox.shrink();
                      }
                      // Look up the latest artist data from libraryState
                      var currentArtist = libraryState.artists.cast<Artist?>().firstWhere(
                        (a) => a?.name == _selectedArtist!.name,
                        orElse: () => null,
                      );

                      // If not found (renamed?), try to find an artist containing at least one song from the old artist
                      if (currentArtist == null && _selectedArtist!.songs.isNotEmpty) {
                        final firstSongPath = _selectedArtist!.songs.first.path;
                        currentArtist = libraryState.artists.cast<Artist?>().firstWhere(
                          (a) => a!.songs.any((s) => s.path == firstSongPath),
                          orElse: () => null,
                        );
                      }

                      currentArtist ??= _selectedArtist!;

                      // Update selection if it changed
                      if (currentArtist != _selectedArtist) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _currentView == LibraryViewType.artistDetails) {
                            setState(() { _selectedArtist = currentArtist; });
                          }
                        });
                      }

                      final filteredSongs = currentArtist.songs
                          .where((s) => (s.title ?? '').toLowerCase().contains(_searchQuery) || 
                                       (s.artist ?? '').toLowerCase().contains(_searchQuery))
                          .toList();

                      final artistAlbums = libraryState.albums
                          .where((album) => album.songs.any((s) => s.artistList.contains(currentArtist!.name)))
                          .toList();

                      return _ArtistDetailsView(
                        artist: currentArtist.copyWithSongs(filteredSongs),
                        sortType: libraryState.sortType,
                        ascending: libraryState.ascending,
                        albums: artistAlbums,
                      );
                  }
                },
              );
            }
            if (libraryState is LibraryError) {
              return Center(child: Text(libraryState.message));
            }
            return const SizedBox.shrink();
          },
        ),
      );
  }

  String _getTitle() {
    switch (_currentView) {
      case LibraryViewType.main:
        return 'Library';
      case LibraryViewType.songs:
        return 'All Songs';
      case LibraryViewType.albums:
        return 'Albums';
      case LibraryViewType.artists:
        return 'Artists';
      case LibraryViewType.playlists:
        return 'Playlists';
      case LibraryViewType.playlistDetails:
        return _selectedPlaylist?.name ?? 'Playlist';
      case LibraryViewType.albumDetails:
        return _selectedAlbum?.name ?? 'Album';
      case LibraryViewType.artistDetails:
        return _selectedArtist?.name ?? 'Artist';
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No music found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Add a folder in Settings to get started.'),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Playlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Playlist name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context
                    .read<PlaylistsBloc>()
                    .add(CreatePlaylist(controller.text));
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _LibraryMainView extends StatelessWidget {
  const _LibraryMainView({
    required this.state,
    required this.playlists,
    required this.albums,
    required this.artists,
    required this.songs,
    required this.onViewAllSongs,
    required this.onViewAllAlbums,
    required this.onViewAllArtists,
    required this.onViewAllPlaylists,
    required this.onPlaylistTap,
    required this.onAlbumTap,
    required this.onArtistTap,
    required this.onCreatePlaylist,
  });

  final LibraryLoaded state;
  final List<Playlist> playlists;
  final List<Album> albums;
  final List<Artist> artists;
  final List<Song> songs;
  final VoidCallback onViewAllSongs;
  final VoidCallback onViewAllAlbums;
  final VoidCallback onViewAllArtists;
  final VoidCallback onViewAllPlaylists;
  final ValueChanged<Playlist> onPlaylistTap;
  final ValueChanged<Album> onAlbumTap;
  final ValueChanged<Artist> onArtistTap;
  final VoidCallback onCreatePlaylist;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('library_main_view'),
      padding: const EdgeInsets.only(bottom: 140),
      children: [
        if (playlists.isNotEmpty) ...[
          _SectionHeader(title: 'Playlists', onTap: onViewAllPlaylists),
          const SizedBox(height: 8),
          _HorizontalPlaylists(
            playlists: playlists,
            onPlaylistTap: onPlaylistTap,
            onCreatePlaylist: onCreatePlaylist,
          ),
        ],
        if (albums.isNotEmpty) ...[
          _SectionHeader(title: 'Albums', onTap: onViewAllAlbums),
          const SizedBox(height: 8),
          _HorizontalAlbums(albums: albums, onAlbumTap: onAlbumTap),
        ],
        if (artists.isNotEmpty) ...[
          _SectionHeader(title: 'Artists', onTap: onViewAllArtists),
          const SizedBox(height: 8),
          _HorizontalArtists(artists: artists, onArtistTap: onArtistTap),
        ],
        if (songs.isNotEmpty) ...[
          _SectionHeader(title: 'Songs', onTap: onViewAllSongs),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: songs.take(10).length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return _SongTile(song: song, songs: songs);
            },
          ),
          if (songs.length > 10)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: TextButton(
                onPressed: onViewAllSongs,
                child: const Text('View all songs'),
              ),
            ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _HorizontalAlbums extends StatelessWidget {
  const _HorizontalAlbums({required this.albums, required this.onAlbumTap});

  final List<Album> albums;
  final ValueChanged<Album> onAlbumTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: albums.length,
        itemBuilder: (context, index) {
          final album = albums[index];
          return _AlbumCard(album: album, onTap: () => onAlbumTap(album));
        },
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.album, required this.onTap});

  final Album album;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: AlbumArt(
                  path: album.artworkPath,
                  hasArtwork: album.artworkPath != null,
                  borderRadius: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    album.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalArtists extends StatelessWidget {
  const _HorizontalArtists({required this.artists, required this.onArtistTap});

  final List<Artist> artists;
  final ValueChanged<Artist> onArtistTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          return _ArtistCircle(artist: artist, onTap: () => onArtistTap(artist));
        },
      ),
    );
  }
}

class _ArtistCircle extends StatelessWidget {
  const _ArtistCircle({required this.artist, required this.onTap});

  final Artist artist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: artist.artworkPath != null
                  ? AlbumArt(
                      path: artist.artworkPath,
                      size: 80,
                      borderRadius: 40,
                    )
                  : const Icon(Icons.person, size: 40),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                artist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalPlaylists extends StatelessWidget {
  const _HorizontalPlaylists({
    required this.playlists,
    required this.onPlaylistTap,
    required this.onCreatePlaylist,
  });

  final List<Playlist> playlists;
  final ValueChanged<Playlist> onPlaylistTap;
  final VoidCallback onCreatePlaylist;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        // +1 for the Create button
        itemCount: playlists.length + 1,
        itemBuilder: (context, index) {
          if (index == playlists.length) {
            return _CreatePlaylistCard(onTap: onCreatePlaylist);
          }
          final playlist = playlists[index];
          return _PlaylistCard(
              playlist: playlist, onTap: () => onPlaylistTap(playlist));
        },
      ),
    );
  }
}

class _CreatePlaylistCard extends StatelessWidget {
  const _CreatePlaylistCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Icon(Icons.add, size: 48),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'New Playlist',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Create custom mix',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({required this.playlist, required this.onTap});

  final Playlist playlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                ),
                child: playlist.artworkPath != null
                    ? AlbumArt(
                        path: playlist.artworkPath,
                        borderRadius: 12,
                      )
                    : Icon(
                        playlist.name == 'Favourites' ? Icons.favorite : Icons.playlist_play,
                        size: 48,
                        color: playlist.name == 'Favourites' ? Colors.red : null,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${playlist.songPaths.length} songs',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SongsView extends StatelessWidget {
  const _SongsView({required this.songs});

  final List<Song> songs;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const PageStorageKey('library_songs_view'),
      padding: const EdgeInsets.only(bottom: 140),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return _SongTile(song: song, songs: songs);
      },
    );
  }
}

class _AlbumsView extends StatelessWidget {
  const _AlbumsView({required this.albums, required this.onAlbumTap});

  final List<Album> albums;
  final ValueChanged<Album> onAlbumTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: const PageStorageKey('library_albums_view'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return _AlbumCard(album: album, onTap: () => onAlbumTap(album));
      },
    );
  }
}

class _ArtistsView extends StatelessWidget {
  const _ArtistsView({required this.artists, required this.onArtistTap});

  final List<Artist> artists;
  final ValueChanged<Artist> onArtistTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: const PageStorageKey('library_artists_view'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return _ArtistCircle(artist: artist, onTap: () => onArtistTap(artist));
      },
    );
  }
}

class _PlaylistsView extends StatelessWidget {
  const _PlaylistsView({
    required this.playlists,
    required this.onPlaylistTap,
  });

  final List<Playlist> playlists;
  final ValueChanged<Playlist> onPlaylistTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: const PageStorageKey('library_playlists_view'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return _PlaylistCard(
            playlist: playlist, onTap: () => onPlaylistTap(playlist));
      },
    );
  }
}

class _AlbumDetailsView extends StatelessWidget {
  const _AlbumDetailsView({
    required this.album,
    required this.sortType,
    required this.ascending,
    required this.artists,
  });

  final Album album;
  final SortType sortType;
  final bool ascending;
  final List<Artist> artists;

  Future<void> _pickArtwork(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null && context.mounted) {
      context.read<LibraryBloc>().add(SetAlbumArtwork(album, result.files.single.path!));
    }
  }

  void _showPreview(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => _ArtworkPreviewDialog(
        path: album.artworkPath,
        hasArtwork: album.artworkPath != null,
        onEdit: () => _pickArtwork(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedSongs = _sortSongs(album.songs, sortType, ascending);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 500;

        return ListView(
          padding: const EdgeInsets.only(bottom: 140),
          children: [
            Padding(
              padding: EdgeInsets.all(isSmall ? 16.0 : 24.0),
              child: isSmall
                  ? Column(
                      children: [
                        _buildArtwork(context, 200),
                        const SizedBox(height: 24),
                        _buildInfo(context, isSmall, sortedSongs),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildArtwork(context, 160),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildInfo(context, isSmall, sortedSongs),
                        ),
                      ],
                    ),
            ),
            ...sortedSongs.map((song) => _SongTile(song: song, songs: sortedSongs)),
            if (artists.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Divider(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Artists',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              _HorizontalArtists(
                artists: artists,
                onArtistTap: (artist) {
                  LibraryPage.of(context)?.setView(
                    LibraryViewType.artistDetails,
                    artist: artist,
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildArtwork(BuildContext context, double size) {
    return InkWell(
      onTap: () => _showPreview(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: AlbumArt(
                path: album.artworkPath,
                hasArtwork: album.artworkPath != null,
                borderRadius: 16,
              ),
            ),
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context, bool isSmall, List<Song> sortedSongs) {
    return Column(
      crossAxisAlignment:
          isSmall ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          album.name,
          textAlign: isSmall ? TextAlign.center : TextAlign.start,
          style: (isSmall
                  ? Theme.of(context).textTheme.headlineSmall
                  : Theme.of(context).textTheme.headlineMedium)
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          album.artist,
          textAlign: isSmall ? TextAlign.center : TextAlign.start,
          style: (isSmall
                  ? Theme.of(context).textTheme.titleMedium
                  : Theme.of(context).textTheme.titleLarge)
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: isSmall ? WrapAlignment.center : WrapAlignment.start,
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                context.read<PlayerBloc>().add(
                      PlayerPlay(sortedSongs.first, queue: sortedSongs),
                    );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play'),
            ),
            OutlinedButton.icon(
              onPressed: () => _pickArtwork(context),
              icon: const Icon(Icons.image_outlined),
              label: const Text('Change Cover'),
            ),
            _AddToPlaylistIconButton(
              songPaths: album.songs.map((s) => s.path).toList(),
            ),
          ],
        ),
      ],
    );
  }
}

class _ArtistDetailsView extends StatelessWidget {
  const _ArtistDetailsView({
    required this.artist,
    required this.sortType,
    required this.ascending,
    required this.albums,
  });

  final Artist artist;
  final SortType sortType;
  final bool ascending;
  final List<Album> albums;

  Future<void> _pickArtwork(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null && context.mounted) {
      context.read<LibraryBloc>().add(SetArtistArtwork(artist, result.files.single.path!));
    }
  }

  void _showPreview(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => _ArtworkPreviewDialog(
        path: artist.artworkPath,
        hasArtwork: artist.artworkPath != null,
        onEdit: () => _pickArtwork(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedSongs = _sortSongs(artist.songs, sortType, ascending);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 500;

        return ListView(
          padding: const EdgeInsets.only(bottom: 140),
          children: [
            Padding(
              padding: EdgeInsets.all(isSmall ? 16.0 : 24.0),
              child: isSmall
                  ? Column(
                      children: [
                        _buildArtwork(context, 160),
                        const SizedBox(height: 24),
                        _buildInfo(context, isSmall, sortedSongs),
                      ],
                    )
                  : Row(
                      children: [
                        _buildArtwork(context, 120),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildInfo(context, isSmall, sortedSongs),
                        ),
                      ],
                    ),
            ),
            ...sortedSongs.map((song) => _SongTile(song: song, songs: sortedSongs)),
            if (albums.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Divider(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Albums',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              _HorizontalAlbums(
                albums: albums,
                onAlbumTap: (album) {
                  LibraryPage.of(context)?.setView(
                    LibraryViewType.albumDetails,
                    album: album,
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildArtwork(BuildContext context, double size) {
    return InkWell(
      onTap: () => _showPreview(context),
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            artist.artworkPath != null
                ? AlbumArt(
                    path: artist.artworkPath,
                    size: size,
                    borderRadius: size / 2,
                  )
                : Icon(Icons.person, size: size * 0.5),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context, bool isSmall, List<Song> sortedSongs) {
    return Column(
      crossAxisAlignment:
          isSmall ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          artist.name,
          textAlign: isSmall ? TextAlign.center : TextAlign.start,
          style: (isSmall
                  ? Theme.of(context).textTheme.headlineSmall
                  : Theme.of(context).textTheme.headlineMedium)
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          '${artist.songs.length} songs',
          textAlign: isSmall ? TextAlign.center : TextAlign.start,
          style: (isSmall
                  ? Theme.of(context).textTheme.titleSmall
                  : Theme.of(context).textTheme.titleMedium)
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: isSmall ? WrapAlignment.center : WrapAlignment.start,
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                context.read<PlayerBloc>().add(
                      PlayerPlay(sortedSongs.first, queue: sortedSongs),
                    );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play All'),
            ),
            OutlinedButton.icon(
              onPressed: () => _pickArtwork(context),
              icon: const Icon(Icons.image_outlined),
              label: const Text('Change Image'),
            ),
            _AddToPlaylistIconButton(
              songPaths: artist.songs.map((s) => s.path).toList(),
            ),
          ],
        ),
      ],
    );
  }
}

class _AddToPlaylistIconButton extends StatelessWidget {
  const _AddToPlaylistIconButton({required this.songPaths});

  final List<String> songPaths;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Add to Playlist',
      child: OutlinedButton.icon(
        onPressed: null, // Handled by PopupMenuButton
        icon: const Icon(Icons.playlist_add),
        label: const Text('Add to Playlist'),
      ),
      onSelected: (pId) {
        context.read<PlaylistsBloc>().add(AddSongsToPlaylist(
              playlistId: pId,
              songPaths: songPaths,
            ));
      },
      itemBuilder: (context) {
        final playlists = context.read<PlaylistsBloc>().state.playlists;
        return [
          ...playlists.map((p) => PopupMenuItem<String>(
                value: p.id,
                child: ListTile(
                  leading: const Icon(Icons.playlist_add),
                  title: Text(p.name),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              )),
        ];
      },
    );
  }
}

class _PlaylistDetailsView extends StatelessWidget {
  const _PlaylistDetailsView({
    required this.playlist,
    required this.librarySongs,
    required this.sortType,
    required this.ascending,
  });

  final Playlist playlist;
  final List<Song> librarySongs;
  final SortType sortType;
  final bool ascending;

  Future<void> _pickArtwork(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null && context.mounted) {
      context.read<PlaylistsBloc>().add(SetPlaylistArtwork(playlist.id, result.files.single.path!));
    }
  }

  void _showPreview(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => _ArtworkPreviewDialog(
        path: playlist.artworkPath,
        hasArtwork: playlist.artworkPath != null,
        onEdit: () => _pickArtwork(context),
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    if (playlist.name == 'Favourites') return;

    final libraryPageState = LibraryPage.of(context);
    final controller = TextEditingController(text: playlist.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Playlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Playlist name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != playlist.name) {
                context.read<PlaylistsBloc>().add(RenamePlaylist(playlist.id, newName));
                
                // Update selection in parent to avoid stale data
                libraryPageState?.setView(
                  LibraryViewType.playlistDetails,
                  playlist: playlist.copyWith(id: newName, name: newName),
                );
                
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final songs = librarySongs
        .where((s) => playlist.songPaths.contains(s.path))
        .toList();
    
    // Maintain the order from playlist.songPaths
    final orderedSongs = <Song>[];
    for (final path in playlist.songPaths) {
      final song = songs.cast<Song?>().firstWhere((s) => s?.path == path, orElse: () => null);
      if (song != null) {
        orderedSongs.add(song);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 500;

        return ReorderableListView(
          padding: const EdgeInsets.only(bottom: 140),
          header: Padding(
            padding: EdgeInsets.all(isSmall ? 16.0 : 24.0),
            child: isSmall
                ? Column(
                    children: [
                      _buildArtwork(context, 200),
                      const SizedBox(height: 24),
                      _buildInfo(context, isSmall, orderedSongs),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildArtwork(context, 160),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildInfo(context, isSmall, orderedSongs),
                      ),
                    ],
                  ),
          ),
          onReorder: (oldIndex, newIndex) {
            context.read<PlaylistsBloc>().add(ReorderPlaylistSongs(
                  playlistId: playlist.id,
                  oldIndex: oldIndex,
                  newIndex: newIndex,
                ));
          },
          buildDefaultDragHandles: false,
          children: [
            ...orderedSongs.asMap().entries.map((entry) {
              final index = entry.key;
              final song = entry.value;
              return _SongTile(
                key: ValueKey('playlist_${playlist.id}_${song.path}_$index'),
                song: song,
                songs: orderedSongs,
                playlistId: playlist.id,
                isReorderable: true,
                index: index,
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildArtwork(BuildContext context, double size) {
    return InkWell(
      onTap: () => _showPreview(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (playlist.artworkPath != null)
              Positioned.fill(
                child: AlbumArt(
                  path: playlist.artworkPath,
                  borderRadius: 16,
                ),
              )
            else
              Center(
                child: Icon(
                  playlist.name == 'Favourites' ? Icons.favorite : Icons.playlist_play,
                  size: size * 0.4,
                  color: playlist.name == 'Favourites' ? Colors.red : null,
                ),
              ),
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context, bool isSmall, List<Song> sortedSongs) {
    return Column(
      crossAxisAlignment:
          isSmall ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              isSmall ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                playlist.name,
                textAlign: isSmall ? TextAlign.center : TextAlign.start,
                style: (isSmall
                        ? Theme.of(context).textTheme.headlineSmall
                        : Theme.of(context).textTheme.headlineMedium)
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (playlist.name != 'Favourites')
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => _showRenameDialog(context),
                tooltip: 'Rename Playlist',
              ),
          ],
        ),
        Text(
          '${sortedSongs.length} songs',
          textAlign: isSmall ? TextAlign.center : TextAlign.start,
          style: (isSmall
                  ? Theme.of(context).textTheme.titleSmall
                  : Theme.of(context).textTheme.titleLarge)
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: isSmall ? WrapAlignment.center : WrapAlignment.start,
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: sortedSongs.isEmpty
                  ? null
                  : () {
                      context.read<PlayerBloc>().add(
                            PlayerPlay(sortedSongs.first, queue: sortedSongs),
                          );
                    },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play'),
            ),
            OutlinedButton.icon(
              onPressed: () => _pickArtwork(context),
              icon: const Icon(Icons.image_outlined),
              label: const Text('Change Image'),
            ),
            if (playlist.name != 'Favourites')
              OutlinedButton.icon(
                onPressed: () => _showDeletePlaylistDialog(context, playlist),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _showDeletePlaylistDialog(BuildContext context, Playlist playlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text('Are you sure you want to delete "${playlist.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<PlaylistsBloc>().add(DeletePlaylist(playlist.id));
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

List<Song> _sortSongs(List<Song> songs, SortType sortType, bool ascending) {
  final sorted = List<Song>.from(songs);
  sorted.sort((a, b) {
    int cmp;
    switch (sortType) {
      case SortType.name:
        cmp = (a.title ?? '').compareTo(b.title ?? '');
        break;
      case SortType.dateReleased:
        cmp = (a.year ?? 0).compareTo(b.year ?? 0);
        break;
      case SortType.dateModified:
        cmp = (a.dateModified ?? DateTime(0)).compareTo(b.dateModified ?? DateTime(0));
        break;
      case SortType.duration:
        cmp = (a.duration ?? Duration.zero).compareTo(b.duration ?? Duration.zero);
        break;
      case SortType.trackNumber:
        int discCmp = (a.discNumber ?? 1).compareTo(b.discNumber ?? 1);
        if (discCmp != 0) {
          cmp = discCmp;
        } else {
          cmp = (a.trackNumber ?? 0).compareTo(b.trackNumber ?? 0);
        }
        break;
    }
    return ascending ? cmp : -cmp;
  });
  return sorted;
}

class _SongTile extends StatelessWidget {
  const _SongTile({
    super.key,
    required this.song,
    required this.songs,
    this.playlistId,
    this.isReorderable = false,
    this.index,
  });

  final Song song;
  final List<Song> songs;
  final String? playlistId;
  final bool isReorderable;
  final int? index;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (previous, current) =>
          (previous.currentSong?.path == song.path) !=
          (current.currentSong?.path == song.path),
      builder: (context, state) {
        final isCurrent = state.currentSong?.path == song.path;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Stack(
            children: [
              if (isCurrent)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                selected: isCurrent,
                selectedColor: Theme.of(context).colorScheme.onPrimaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Hero(
                  tag: 'artwork_${song.path}',
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                                      child: AlbumArt(
                                        artwork: song.artwork,
                                        path: song.path,
                                        hasArtwork: song.hasArtwork == true,
                                        borderRadius: 12,
                                      ),                  ),
                ),
                title: Text(
                  song.title ?? 'Unknown Title',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  song.artist ?? 'Unknown Artist',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        SongOptionsBottomSheet.show(
                          context,
                          song: song,
                          playlistId: playlistId,
                        );
                      },
                    ),
                    if (isReorderable && index != null)
                      ReorderableDragStartListener(
                        index: index!,
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.drag_handle,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  context.read<PlayerBloc>().add(
                        PlayerPlay(song, queue: songs),
                      );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ArtworkPreviewDialog extends StatelessWidget {
  const _ArtworkPreviewDialog({
    required this.path,
    required this.hasArtwork,
    required this.onEdit,
  });

  final String? path;
  final bool hasArtwork;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            color: Colors.black.withValues(alpha: 0.8),
            alignment: Alignment.center,
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               GestureDetector(
                 onTap: () {
                    Navigator.of(context).pop();
                    onEdit();
                 },
                 child: Container(
                   constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
                   decoration: BoxDecoration(
                     borderRadius: BorderRadius.circular(24),
                     boxShadow: [
                       BoxShadow(
                         color: Colors.black.withValues(alpha: 0.5),
                         blurRadius: 30,
                         offset: const Offset(0, 10),
                       ),
                     ],
                   ),
                   child: Stack(
                     alignment: Alignment.center,
                     children: [
                        AlbumArt(
                          path: path,
                          hasArtwork: hasArtwork,
                          borderRadius: 24,
                          size: 400,
                        ),
                        Positioned(
                          bottom: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit, color: Colors.white, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'Tap to Edit',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                     ],
                   ),
                 ),
               ),
               const SizedBox(height: 24),
               Material(
                 color: Colors.transparent,
                 child: IconButton(
                   onPressed: () => Navigator.of(context).pop(),
                   icon: const Icon(Icons.close, color: Colors.white, size: 32),
                   style: IconButton.styleFrom(
                     backgroundColor: Colors.white.withValues(alpha: 0.1),
                     hoverColor: Colors.white.withValues(alpha: 0.2),
                   ),
                 ),
               ),
            ],
          ),
        ),
      ],
    );
  }
}