import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/room_shape.dart';
import 'package:floor_calculator/utils/units.dart';
import 'calculate_state.dart';

@lazySingleton
class CalculateCubit extends Cubit<CalculateState> {
  CalculateCubit() : super(CalculateState());

  void setRoomLength(int roomLength) {
    emit(state.copyWith(roomLength: roomLength));
  }

  void setRoomWidth(int roomWidth) {
    emit(state.copyWith(roomWidth: roomWidth));
  }

  void setRoomLength2(int roomLength2) {
    emit(state.copyWith(roomLength2: roomLength2));
  }

  void setRoomWidth2(int roomWidth2) {
    emit(state.copyWith(roomWidth2: roomWidth2));
  }

  void setRoomDiagonal(int roomDiagonal) {
    emit(state.copyWith(roomDiagonal: roomDiagonal));
  }

  void setNotchLength(int notchLength) {
    emit(state.copyWith(notchLength: notchLength));
  }

  void setNotchWidth(int notchWidth) {
    emit(state.copyWith(notchWidth: notchWidth));
  }

  void setNotchCorner(RoomCorner notchCorner) {
    emit(state.copyWith(notchCorner: notchCorner));
  }

  /// A 45° layout in a room with a corner cut away is not supported, so
  /// choosing that room un-chooses it.
  ///
  /// Here rather than on the laying screen. The direction is read by the row
  /// plan, by the field validators and by the drawing, and a screen that only
  /// greyed the button out would leave all three holding the old answer.
  void setRoomKind(RoomKind roomKind) {
    emit(state.copyWith(
      roomKind: roomKind,
      direction: roomKind == RoomKind.lShaped && state.direction == Direction.diagonal
          ? Direction.length
          : state.direction,
    ));
  }

  void setLaminateLength(int laminateLength) {
    emit(state.copyWith(laminateLength: laminateLength));
  }

  void setLaminateWidth(int laminateWidth) {
    emit(state.copyWith(laminateWidth: laminateWidth));
  }

  void setQuantityPerPack(int quantityPerPack) {
    emit(state.copyWith(quantityPerPack: quantityPerPack));
  }

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

  void setMeasurementSystem(MeasurementSystem system) {
    emit(state.copyWith(system: system));
  }
}
