import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:floor_calculator/models.dart';

/// How the floor is laid rather than what it is laid in: the gap left round the
/// walls, how far the joints step from row to row, the shortest offcut worth
/// laying, and which way the rows run.
///
/// Nothing reads these but the screen that collects them and the [Calculation]
/// it builds at the end, which is why this is the last cubit and nothing is
/// downstream of it.
class LayingState extends Equatable {
  /// All in millimetres.
  final int? indentFromWall;
  final int? rowOffset;
  final int? minimumLaminateLength;

  /// Which way the rows run, as the user chose it.
  ///
  /// As they *chose* it, which is not always as it will be laid: 45° is not
  /// possible in a room with a corner notched out of it, and a user who picked
  /// it in a rectangle and then went back and notched the room still has it
  /// stored here. The laying screen reads the direction through the room's own
  /// [RoomOutline.takesDiagonal] and so never offers or uses an impossible one —
  /// see `_Inputs.direction` there. Kept rather than corrected, so that
  /// notching a room and unnotching it again gives the user back the answer
  /// they gave.
  final Direction direction;

  final OffsetMode offsetMode;

  const LayingState({
    this.indentFromWall,
    this.rowOffset,
    this.minimumLaminateLength,
    this.direction = Direction.length,
    this.offsetMode = OffsetMode.half,
  });

  LayingState copyWith({
    final int? indentFromWall,
    final int? rowOffset,
    final int? minimumLaminateLength,
    final Direction? direction,
    final OffsetMode? offsetMode,
  }) =>
      LayingState(
        indentFromWall: indentFromWall ?? this.indentFromWall,
        rowOffset: rowOffset ?? this.rowOffset,
        minimumLaminateLength: minimumLaminateLength ?? this.minimumLaminateLength,
        direction: direction ?? this.direction,
        offsetMode: offsetMode ?? this.offsetMode,
      );

  @override
  List<Object?> get props => [
        indentFromWall,
        rowOffset,
        minimumLaminateLength,
        direction,
        offsetMode,
      ];
}

/// The laying form's answers, kept for as long as the app runs — see
/// [RoomCubit] for why none of these cubits belongs to its screen.
class LayingCubit extends Cubit<LayingState> {
  LayingCubit() : super(const LayingState());

  void setIndentFromWall(int indentFromWall) {
    emit(state.copyWith(indentFromWall: indentFromWall));
  }

  void setRowOffset(int rowOffset) {
    emit(state.copyWith(rowOffset: rowOffset));
  }

  void setMinimumLaminateLength(int minimumLaminateLength) {
    emit(state.copyWith(minimumLaminateLength: minimumLaminateLength));
  }

  void setDirection(Direction direction) {
    emit(state.copyWith(direction: direction));
  }

  void setOffsetMode(OffsetMode offsetMode) {
    emit(state.copyWith(offsetMode: offsetMode));
  }
}
