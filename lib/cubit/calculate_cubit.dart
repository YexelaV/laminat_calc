import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/room_kind.dart';
import 'package:floor_calculator/room_shape.dart';
import 'package:floor_calculator/utils/units.dart';
import 'calculate_state.dart';

/// Everything the two forms collect, from the first screen to the last.
///
/// One instance per run of the app, owned by the [BlocProvider] above the
/// router in `main.dart`. It has to outlive each screen because the form is
/// spread over three of them and none passes anything to the next: what the
/// user typed in the room screen is read again on the laying screen, and the
/// unit system is read again by the scheme and by the settings sheet.
class CalculateCubit extends Cubit<CalculateState> {
  /// [system] is the one answer that exists before the first frame — it comes
  /// off disk in `main` — so the state starts with it rather than being
  /// corrected by an emit nobody is listening to yet.
  CalculateCubit({MeasurementSystem system = MeasurementSystem.metric})
      : super(CalculateState(system: system));

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

  void setNotchLength2(int notchLength2) {
    emit(state.copyWith(notchLength2: notchLength2));
  }

  void setCutWall(RoomWall cutWall) {
    emit(state.copyWith(cutWall: cutWall));
  }

  /// A 45° layout in a room with a corner notched out of it is not supported,
  /// so choosing such a room un-chooses it.
  ///
  /// Here rather than on the laying screen. The direction is read by the row
  /// plan, by the field validators and by the drawing, and a screen that only
  /// greyed the button out would leave all three holding the old answer.
  ///
  /// A chamfered room is convex and keeps the 45° layout, so switching from an
  /// L to a chamfer leaves the direction alone — the user who had it turned off
  /// has to turn it back on, which is the quieter of the two surprises.
  void setRoomKind(RoomKind roomKind) {
    emit(state.copyWith(
      roomKind: roomKind,
      direction: roomKind.cutKind == CornerCut.notch &&
              state.direction == Direction.diagonal
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
