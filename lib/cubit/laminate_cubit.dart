import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What is written on the side of the carton: the plank, and how many are in a
/// pack.
///
/// Three numbers, and the only three the laying arithmetic wants of them. They
/// are typed on the same screen as the laying now and kept apart from it all
/// the same: a cubit answers for a part of the form, not for a page of it.
/// Sizes are in millimetres; the pack is a count.
class LaminateState extends Equatable {
  final int? laminateLength;
  final int? laminateWidth;
  final int? quantityPerPack;

  const LaminateState({
    this.laminateLength,
    this.laminateWidth,
    this.quantityPerPack,
  });

  LaminateState copyWith({
    final int? laminateLength,
    final int? laminateWidth,
    final int? quantityPerPack,
  }) =>
      LaminateState(
        laminateLength: laminateLength ?? this.laminateLength,
        laminateWidth: laminateWidth ?? this.laminateWidth,
        quantityPerPack: quantityPerPack ?? this.quantityPerPack,
      );

  @override
  List<Object?> get props => [laminateLength, laminateWidth, quantityPerPack];
}

/// The laminate form's answers, kept for as long as the app runs — see
/// [RoomCubit] for why none of these cubits belongs to its screen.
class LaminateCubit extends Cubit<LaminateState> {
  LaminateCubit() : super(const LaminateState());

  void setLaminateLength(int laminateLength) {
    emit(state.copyWith(laminateLength: laminateLength));
  }

  void setLaminateWidth(int laminateWidth) {
    emit(state.copyWith(laminateWidth: laminateWidth));
  }

  void setQuantityPerPack(int quantityPerPack) {
    emit(state.copyWith(quantityPerPack: quantityPerPack));
  }
}
