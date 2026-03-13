part of 'folders_bloc.dart';

class FoldersState extends Equatable {
  const FoldersState({this.folders = const []});

  final List<String> folders;

  @override
  List<Object> get props => [folders];

  FoldersState copyWith({
    List<String>? folders,
  }) {
    return FoldersState(
      folders: folders ?? this.folders,
    );
  }
}
