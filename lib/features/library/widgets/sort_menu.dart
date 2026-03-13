import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muses/features/library/bloc/library_bloc.dart';

class SortMenu extends StatelessWidget {
  const SortMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryState>(
      builder: (context, state) {
        return PopupMenuButton<SortType>(
          icon: const Icon(Icons.sort),
          tooltip: 'Sort by',
          onSelected: (SortType type) {
            if (type == state.sortType) {
              // Toggle ascending if same type selected again
              context.read<LibraryBloc>().add(ChangeSort(type, !state.ascending));
            } else {
              context.read<LibraryBloc>().add(ChangeSort(type, true));
            }
          },
          itemBuilder: (context) => [
            _buildItem(context, SortType.name, 'Name', state),
            _buildItem(context, SortType.dateReleased, 'Date Released', state),
            _buildItem(context, SortType.dateModified, 'Date Modified', state),
            _buildItem(context, SortType.duration, 'Duration', state),
            _buildItem(context, SortType.trackNumber, 'Track Number', state),
          ],
        );
      },
    );
  }

  PopupMenuItem<SortType> _buildItem(
    BuildContext context,
    SortType type,
    String label,
    LibraryState state,
  ) {
    final isSelected = state.sortType == type;
    return PopupMenuItem<SortType>(
      value: type,
      child: Row(
        children: [
          if (isSelected)
            Icon(
              state.ascending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
            )
          else
            const SizedBox(width: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
