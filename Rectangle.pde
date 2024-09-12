class Rectangle {
  boolean isCorrectNote;  // Flag to indicate if this rectangle holds the correct note
  int note;  // The note assigned to this rectangle
  float x, y, w, h;  // Position and size of the rectangle
  boolean isClicked = false;  // State to check if the rectangle is clicked

  // Constructor to initialize the rectangle with position, size, note, and correctness
  Rectangle(float x, float y, float w, float h, int note, boolean isCorrectNote) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.note = note;  // Assign the note to the rectangle
    this.isCorrectNote = isCorrectNote;  // Set whether this is the correct note
  }

  // Method to display the rectangle
  void display() {
    noStroke();
    // Change color based on click state
    if (isClicked) {
      fill(255, 0, 0);  // Red color if clicked
    } else {
      fill(255, 255, 255);  // White color if not clicked
    }
    rect(x, y, w, h);  // Draw the rectangle
  }

  // Method to check if the rectangle is clicked
  void checkClick(boolean clickedState) {
    // Check if the mouse is within the bounds of the rectangle
    if (mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h) {
      isClicked = clickedState;  // Update the clicked state
      if (isClicked) {
        sendOscMessage("/play_n", note);  // Send OSC message to play the note
      
      }
    }
  }
}
