import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'calculate_state.dart';

@lazySingleton
class CalculateCubit extends Cubit<CalculateState> {
  CalculateCubit() : super(CalculateState());

  void setRoomLength(double roomLength) {
    emit(state.copyWith(roomLength: roomLength));
  }

  void setRoomWidth(double roomWidth) {
    emit(state.copyWith(roomWidth: roomWidth));
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
}
