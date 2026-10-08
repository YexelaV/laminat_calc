import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:floor_calculator/room_kind.dart';
import 'package:floor_calculator/room_shape.dart';

/// What the user measured of the room, and what shape they say it is.
///
/// Every dimension is in millimetres. Nothing about the laminate or the laying
/// is here: the only thing anything downstream wants of this screen is [shape],
/// and that is the whole of what the laying screen reads.
class RoomState extends Equatable {
  /// The wall the rows are laid along, and the one they start against. These
  /// two are the room every user types, and on their own they describe a
  /// rectangle.
  final int? roomLength;
  final int? roomWidth;

  /// The walls opposite those two, and the diagonal between the corners they do
  /// not share — asked for only when the user says the room is not square.
  ///
  /// Four wall lengths are one measurement short of a shape, and the diagonal
  /// is the one that closes it; see [RoomShape].
  final int? roomLength2;
  final int? roomWidth2;
  final int? roomDiagonal;

  /// How far the missing corner reaches along the length and along the width,
  /// and which corner it is — asked for only when the room has a cut in it.
  ///
  /// A chamfer is cut at 45°, so it uses [notchLength] alone and [notchWidth]
  /// sits unread until the user picks a square cut again. Left in place rather
  /// than cleared: a user trying the shapes on for size gets their L back
  /// where they left it.
  final int? notchLength;
  final int? notchWidth;
  final RoomCorner notchCorner;

  /// The second cut of a pair, and the wall the pair stands on — asked for only
  /// when the room has two corners taken off it.
  ///
  /// For a pair standing on one wall, [notchLength] is the first shoulder and
  /// [notchLength2] the second, both measured along [cutWall] from its two
  /// ends, and [notchWidth]/[notchWidth2] are how deep each of them goes; a
  /// chamfer's depth is its shoulder and leaves both widths unread. For a pair
  /// across the room there is no shared wall to measure from, and the two
  /// pairs are the two cuts' own length and width, the first in [notchCorner]
  /// and the second in the corner opposite it.
  ///
  /// A second measurement left blank is the first one again, so a symmetrical
  /// pair is typed once — see [RoomKind.outlineFor].
  final int? notchLength2;
  final int? notchWidth2;
  final RoomWall cutWall;

  /// A room measured by the piece in the middle of [cutWall] rather than by
  /// what is cut from either side of it, which is how it comes off a tape: a T's
  /// stem and a П's notch are things in the room, and the shoulders and offsets
  /// beside them are what is not.
  ///
  /// On by default, and what is cut either side is then equal — [midSpan] is
  /// how far the middle piece runs along [cutWall] and [notchWidth] how deep it
  /// is. Turned off, the pair of boxes come back and these are left where they
  /// were: a user trying the one against the other finds each as they left it,
  /// the same courtesy switching shape pays.
  final bool symmetricCut;
  final int? midSpan;

  /// What the user says the room is. Off is not the same as four equal walls
  /// or a notch of nothing: it means the extra fields are not on screen and
  /// the room is the rectangle it has always been.
  final RoomKind roomKind;

  const RoomState({
    this.roomLength,
    this.roomWidth,
    this.roomLength2,
    this.roomWidth2,
    this.roomDiagonal,
    this.notchLength,
    this.notchWidth,
    this.notchCorner = RoomCorner.farRight,
    this.notchLength2,
    this.notchWidth2,
    this.cutWall = RoomWall.near,
    this.symmetricCut = true,
    this.midSpan,
    this.roomKind = RoomKind.rectangle,
  });

  /// The form reads the shape it is in far more often than it sets it, and
  /// most of what it asks is one of these two.
  bool get unevenWalls => roomKind == RoomKind.uneven;

  /// Whether the room has any corner taken off it, however.
  bool get cutCorners => roomKind.isCut;

  /// The room the calculation and the drawing both work from, or null until the
  /// two sizes every room needs have been typed.
  ///
  /// What the shape is made of is the shape's own business — see
  /// [RoomKind.outlineFor]. All this knows is that no room is anything until
  /// those two sizes are.
  ///
  /// The one thing any other screen asks of this one. Everything above is the
  /// measurements it was built from, and nobody outside the room screen has a
  /// use for them.
  RoomOutline? get shape {
    final length = roomLength;
    final width = roomWidth;
    if (length == null || width == null) return null;
    return roomKind.outlineFor(this, length, width);
  }

  RoomState copyWith({
    final int? roomLength,
    final int? roomWidth,
    final int? roomLength2,
    final int? roomWidth2,
    final int? roomDiagonal,
    final int? notchLength,
    final int? notchWidth,
    final RoomCorner? notchCorner,
    final int? notchLength2,
    final int? notchWidth2,
    final RoomWall? cutWall,
    final bool? symmetricCut,
    final int? midSpan,
    final RoomKind? roomKind,
  }) {
    return RoomState(
      roomLength: roomLength ?? this.roomLength,
      roomWidth: roomWidth ?? this.roomWidth,
      roomLength2: roomLength2 ?? this.roomLength2,
      roomWidth2: roomWidth2 ?? this.roomWidth2,
      roomDiagonal: roomDiagonal ?? this.roomDiagonal,
      notchLength: notchLength ?? this.notchLength,
      notchWidth: notchWidth ?? this.notchWidth,
      notchCorner: notchCorner ?? this.notchCorner,
      notchLength2: notchLength2 ?? this.notchLength2,
      notchWidth2: notchWidth2 ?? this.notchWidth2,
      cutWall: cutWall ?? this.cutWall,
      symmetricCut: symmetricCut ?? this.symmetricCut,
      midSpan: midSpan ?? this.midSpan,
      roomKind: roomKind ?? this.roomKind,
    );
  }

  @override
  List<Object?> get props => [
        roomLength,
        roomWidth,
        roomLength2,
        roomWidth2,
        roomDiagonal,
        notchLength,
        notchWidth,
        notchCorner,
        notchLength2,
        notchWidth2,
        cutWall,
        symmetricCut,
        midSpan,
        roomKind,
      ];
}

/// The room form's answers, kept for as long as the app runs.
///
/// Above the router rather than owned by the screen, like the three cubits
/// beside it. The screens are pushed on top of each other and a step back
/// destroys the route, its [State] and the text controllers in it — the boxes
/// are filled again from here when the screen comes round a second time. A
/// cubit that lived and died with the screen would turn every step back into a
/// form to retype.
class RoomCubit extends Cubit<RoomState> {
  RoomCubit() : super(const RoomState());

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

  void setNotchWidth2(int notchWidth2) {
    emit(state.copyWith(notchWidth2: notchWidth2));
  }

  void setCutWall(RoomWall cutWall) {
    emit(state.copyWith(cutWall: cutWall));
  }

  void setMidSpan(int midSpan) {
    emit(state.copyWith(midSpan: midSpan));
  }

  void setSymmetricCut(bool symmetricCut) {
    emit(state.copyWith(symmetricCut: symmetricCut));
  }

  /// The shape of the room, and nothing else.
  ///
  /// It used to also put the laying direction back to "along the room" when the
  /// room became one with a corner notched out of it, because a 45° row crosses
  /// such an outline twice. That was this cubit reaching across the form to
  /// correct an answer given on a later screen, and it cannot reach any more.
  /// It does not need to: the laying screen reads the direction *through* the
  /// shape ([RoomOutline.takesDiagonal]), so a combination that cannot be laid
  /// is never arrived at rather than repaired afterwards.
  void setRoomKind(RoomKind roomKind) {
    emit(state.copyWith(roomKind: roomKind));
  }
}
