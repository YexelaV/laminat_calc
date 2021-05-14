enum Direction { length, width }

class Plank {
  int number;
  int length;
  int width;
  Plank(this.number, this.length, this.width);
}

class Line {
  int number;
  List<Plank> planks;
  Line(this.number, this.planks);
}
