class Rectangle {
  boolean isCorrectNote;
  int note;
  float x, y, w, h;
  boolean isClicked = false;

  Rectangle(float x, float y, float w, float h) {

    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.isCorrectNote = isCorrectNote;
    this.note = note;
  }


  void display() {
    noStroke();
    if (isClicked) {
      fill(255, 0, 0);
    } else {
      fill(255, 255, 255);
    }
    rect(x, y, w, h);
  }

  void checkClick(boolean clickedState) {
    if (mouseX >x && mouseX < x+w && mouseY >y && mouseY<y+h) {
      isClicked = clickedState;
      if (isClicked) {
        sender.send("/test", 40);
      }
    }
  }
}
