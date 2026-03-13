import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'folders_event.dart';
part 'folders_state.dart';

class FoldersBloc extends HydratedBloc<FoldersEvent, FoldersState> {
  FoldersBloc() : super(const FoldersState()) {
    on<AddFolder>(_onAddFolder);
    on<RemoveFolder>(_onRemoveFolder);
  }

  void _onAddFolder(AddFolder event, Emitter<FoldersState> emit) {
    if (!state.folders.contains(event.path)) {
      emit(state.copyWith(folders: [...state.folders, event.path]));
    }
  }

  void _onRemoveFolder(RemoveFolder event, Emitter<FoldersState> emit) {
    emit(state.copyWith(
      folders: state.folders.where((path) => path != event.path).toList(),
    ));
  }

  @override
  FoldersState fromJson(Map<String, dynamic> json) {
    return FoldersState(
      folders: List<String>.from(json['folders'] as List),
    );
  }

  @override
  Map<String, dynamic> toJson(FoldersState state) {
    return {'folders': state.folders};
  }
}
