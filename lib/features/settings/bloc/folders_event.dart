part of 'folders_bloc.dart';

abstract class FoldersEvent extends Equatable {
  const FoldersEvent();

  @override
  List<Object> get props => [];
}

class AddFolder extends FoldersEvent {
  const AddFolder(this.path);

  final String path;

  @override
  List<Object> get props => [path];
}

class RemoveFolder extends FoldersEvent {
  const RemoveFolder(this.path);

  final String path;

  @override
  List<Object> get props => [path];
}
