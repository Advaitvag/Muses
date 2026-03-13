part of 'playlists_bloc.dart';

class PlaylistsState extends Equatable {
  const PlaylistsState({this.playlists = const []});

  final List<Playlist> playlists;

  PlaylistsState copyWith({
    List<Playlist>? playlists,
  }) {
    return PlaylistsState(
      playlists: playlists ?? this.playlists,
    );
  }

  @override
  List<Object> get props => [playlists];
}
