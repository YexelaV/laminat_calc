import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:floor_calculator/models.dart';
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

  void setUnevenWalls(bool unevenWalls) {
    emit(state.copyWith(unevenWalls: unevenWalls));
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
