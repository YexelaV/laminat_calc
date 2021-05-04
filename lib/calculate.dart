import 'package:flutter/material.dart';

import 'main.dart';
import 'dart:math';

class Result {
  final int totalPlanks;
  final List<Line> lines = [];
  final List<Plank> pieces = [];
  final List<Plank> trash = [];
  Result(this.totalPlanks, List<Line> lines, List<Plank> pieces, List<Plank> trash) {
    this.lines.addAll(lines);
    this.pieces.addAll(pieces);
    this.trash.addAll(trash);
  }
}

class Calculation {
  final double roomLength;
  final double roomWidth;
  final int plankLength;
  final int plankWidth;
  final int planksInPack;
  final double price;
  final int indent;
  final int minLength;
  final int rowOffset;
  final Direction direction;

  Calculation({
    this.roomLength,
    this.roomWidth,
    this.plankLength,
    this.plankWidth,
    this.planksInPack,
    this.price,
    this.indent,
    this.minLength,
    this.rowOffset,
    this.direction,
  });

  List<Plank> pieces = [];
  List<Plank> trash = [];
  List<Plank> planks = [];
  List<Line> lines = [];
  int numberOfRows;

  List<Line> calculate() {
    final actualLength = (roomLength * 1000 - indent * 2).toInt();
    final actualWidth = (roomWidth * 1000 - indent * 2).toInt();
    numberOfRows =
        (direction == Direction.length ? actualWidth / plankWidth : actualLength / plankWidth)
            .toInt();
    double numberRows =
        direction == Direction.length ? actualWidth / plankWidth : actualLength / plankWidth;
    if (numberOfRows.toDouble() < numberRows) {
      numberOfRows++;
    }

    final rowLength = direction == Direction.length ? actualLength : actualWidth;

    var planksInFirstRow = calculateFirstRow(rowLength);
    var totalPlanks = calculateRows(planksInFirstRow, rowLength, false);
    final variant1 = Result(totalPlanks, lines, pieces, trash);
    planks = [];
    trash = [];
    lines = [];
    pieces = [];
    planksInFirstRow = calculateFirstRow(rowLength);
    totalPlanks = calculateRows(planksInFirstRow, rowLength, true);
    final variant2 = Result(totalPlanks, lines, pieces, trash);
    return variant1.totalPlanks < variant2.totalPlanks ? variant1.lines : variant2.lines;
  }

  void addPlank(int number, int plankLength, int plankWidth) {
    planks.add(Plank(number, plankLength, plankWidth));
  }

  void cutPlank(int index, {int newLength = 0, int newWidth = 0}) {
    var oldLength = planks[index].length;
    var oldWidth = planks[index].width;
    planks[index].length = newLength;
    addPiece(planks[index].number, oldLength - newLength, oldWidth - newWidth);
  }

  void addPiece(int number, int pieceLength, int pieceWidth) {
    if (pieceLength >= minLength) {
      pieces.add(Plank(number, pieceLength, pieceWidth));
    } else {
      if (pieceLength > 0) {
        trash.add(Plank(number, pieceLength, pieceWidth));
      }
    }
  }

  int findPiece(int length, int width, int plankLength, bool exactMatch,
      {int rowOffset = 0, int prevFirstPlankLength = 0, bool cutPieces = false}) {
    int index = -1;
    int minDiff = plankLength;
    if (exactMatch) {
      for (int i = 0; i < pieces.length; i++) {
        if (pieces[i].length == length) {
          return i;
        }
      }
    } else {
      for (int i = 0; i < pieces.length; i++) {
        var canCutPiece = pieces[i].length > (prevFirstPlankLength - rowOffset) &&
            prevFirstPlankLength - rowOffset > minLength;
        var diff = pieces[i].length - length;
        var pieceMatchOffset = (prevFirstPlankLength - pieces[i].length).abs() > rowOffset;
        if (diff < minDiff && (pieceMatchOffset || (cutPieces && canCutPiece))) {
          minDiff = pieces[i].length - length;
          index = i;
        }
      }
    }
    return index;
  }

  int calculateFirstRow(int rowLength) {
    var currentLength = 0;
    int number = 0;
    while (currentLength + plankLength < rowLength) {
      currentLength += plankLength;
      number++;
      addPlank(number, plankLength, plankWidth);
    }
    var lastPlankLength = rowLength - currentLength;
    if (lastPlankLength > 0 && lastPlankLength < minLength) {
      number++;
      addPiece(number, plankLength - minLength, plankWidth);
      addPlank(number, minLength, plankWidth);
      currentLength = currentLength - plankLength + minLength;
      var firstPlankLength = rowLength - currentLength;
      cutPlank(0, newLength: firstPlankLength);

      /*   cutPlank(0, plankLength - minLength, plankWidth, minLength);
      lastPlankLength = lastPlankLength + minLength;
      number++;
      addPlank(number, lastPlankLength, plankWidth);
      addPiece(number, plankLength - lastPlankLength, plankWidth, minLength);*/
    } else {
      number++;
      addPiece(number, plankLength - lastPlankLength, plankWidth);
      addPlank(number, lastPlankLength, plankWidth);
    }
    lines.add(Line(0, planks));
    print("Row №0");
    var res = "";
    lines[0].planks.forEach((element) {
      res += '№${element.number}:${element.length} ';
    });
    print(res);
    return number;
  }

  int calculateRows(int number, int rowLength, bool cutPieces) {
    for (int i = 1; i < numberOfRows; i++) {
      planks = [];
      var currentLength = 0;
      final prevFirstPlankLength = lines[i - 1].planks.first.length;
      int firstPlankLength = prevFirstPlankLength - rowOffset;

      if (firstPlankLength < minLength) {
        //если длина первой доски меньше минимума
        firstPlankLength = plankLength;
        var pieceIndex = findPiece(
          firstPlankLength,
          plankWidth,
          plankLength,
          false,
          prevFirstPlankLength: prevFirstPlankLength,
          rowOffset: rowOffset,
          cutPieces: cutPieces,
        );
        if (pieceIndex != -1) {
          if (!cutPieces || pieces[pieceIndex].length < firstPlankLength) {
            firstPlankLength = pieces[pieceIndex].length;
          }
          addPlank(
            //кладем кусок
            pieces[pieceIndex].number,
            firstPlankLength,
            pieces[pieceIndex].width,
          );
          if (pieces[pieceIndex].length > firstPlankLength) {
            addPiece(
              //сохраняем остаток от куска
              pieces[pieceIndex].number,
              firstPlankLength - pieces[pieceIndex].length,
              pieces[pieceIndex].width,
              //          minLength,
            );
          }
          pieces.removeAt(pieceIndex);
        } else {
          firstPlankLength = plankLength;
          number++;
          addPlank(number, plankLength, plankWidth); //положить целую доску
        }
      } else {
        //длина первой доски не меньше минимума
        var pieceIndex = findPiece(
          firstPlankLength,
          plankWidth,
          plankLength,
          false,
          prevFirstPlankLength: prevFirstPlankLength,
          rowOffset: rowOffset,
          cutPieces: cutPieces,
        );
        if (pieceIndex != -1) {
          //если нашли подходящий кусок
          if (!cutPieces || pieces[pieceIndex].length < firstPlankLength) {
            firstPlankLength = pieces[pieceIndex].length;
          }
          addPlank(
            //кладем кусок
            pieces[pieceIndex].number,
            firstPlankLength,
            pieces[pieceIndex].width,
          );
          if (pieces[pieceIndex].length > firstPlankLength) {
            addPiece(
              //сохраняем остаток от куска
              pieces[pieceIndex].number,
              firstPlankLength - pieces[pieceIndex].length,
              pieces[pieceIndex].width,
            );
          }
          pieces.removeAt(pieceIndex); //удаляем из остатков
        } else {
          //нет подходящих кусков
          number++;
          addPlank(
            //вырезаем из целой доски
            number,
            firstPlankLength,
            plankWidth,
          );
          addPiece(
            //кладем кусок в остатки
            number,
            plankLength - firstPlankLength,
            plankWidth,
          );
        }
      }
      currentLength += firstPlankLength; //положили доску
      while (currentLength + plankLength < rowLength) {
        number++;
        addPlank(number, plankLength, plankWidth); //кладем очередную доску
        currentLength += plankLength;
      }
      var lastPlankLength = rowLength - currentLength;
      if (lastPlankLength > 0 && lastPlankLength < minLength) {
        //если до конца ряда меньше минимума
        //
        var diff = minLength - lastPlankLength;
        var pieceIndex =
            findPiece(minLength, plankLength, plankWidth, true); //ищем подходящий кусок
        if (pieceIndex != -1) {
          //нашли подходящий
          addPlank(
            pieces[pieceIndex].number,
            minLength,
            pieces[pieceIndex].width,
          );
          addPiece(
            pieces[pieceIndex].number,
            pieces[pieceIndex].length - minLength,
            pieces[pieceIndex].width,
          ); //берем кусок из остатка
          pieces.removeAt(pieceIndex);
          firstPlankLength = firstPlankLength - diff;
          cutPlank(0, newLength: firstPlankLength);
        } else {
          lastPlankLength = minLength;
          firstPlankLength = firstPlankLength - diff;
          cutPlank(0, newLength: firstPlankLength);
          number++;
          addPlank(number, lastPlankLength, plankWidth);
          addPiece(number, plankLength - lastPlankLength, plankWidth);
        }
      } else {
        var pieceIndex = findPiece(lastPlankLength, plankWidth, lastPlankLength, true);
        if (pieceIndex != -1) {
          addPlank(
            pieces[pieceIndex].number,
            lastPlankLength,
            pieces[pieceIndex].width,
          );
          addPiece(
            pieces[pieceIndex].number,
            pieces[pieceIndex].length - lastPlankLength,
            pieces[pieceIndex].width,
          );
          pieces.remove(pieces[pieceIndex]);
        } else {
          number++;
          planks.add(Plank(number, lastPlankLength, plankWidth));
          addPiece(
            number,
            plankLength - lastPlankLength,
            plankWidth,
          );
        }
      }
      lines.add(Line(i, planks));
      print("Row №$i");
      var res = "";
      lines[i].planks.forEach((element) {
        res += '№${element.number}:${element.length} ';
      });
      print(res);
    }
    return number;
  }
}
