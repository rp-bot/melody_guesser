import oscP5.*;
import netP5.*;
OscP5 oscP5;
NetAddress maxAddress;
SendMessage sender;
int tile_width, tile_height, starting_x;
int numRectangles = 4;
Rectangle[] rectangles = new Rectangle[numRectangles];

int[] melody = new int[8]; // Array to hold the generated melody
int[] guessedMelody = new int[8]; // Array to hold the guessed notes
int currentGuessIndex = 0; // Index for the current note to be guessed
int chances = 3; // Player's chances
boolean isGameOver = false;
boolean isMelodyPlayed = false;
boolean isMelodyGenerated = false;
// Button variables
Button playButton;
Button generateButton;
boolean isPlaying = false; // State of the play/stop playButton

void setup() {
  size(720, 1080);
  tile_width = 140;
  tile_height = 250;
  starting_x = 20;
  for (int i =0; i <numRectangles; i++) {
    rectangles[i] = new Rectangle(starting_x+(i*180), (height-200), tile_width, tile_height);
  }

  playButton = new Button(20, 20, 100, 50, "Play");
  generateButton = new Button(140, 20, 100, 50, "Generate");

  sender = new SendMessage("127.0.0.1", 7400);
}
void draw() {
  background(34, 32, 32);

  for (int i=0; i<numRectangles; i++) {
    rectangles[i].display();
  }

  playButton.display();
  generateButton.display();
}

void mousePressed() {
  if (playButton.isClicked(mouseX, mouseY)) {
    isPlaying = !isPlaying; // Toggle the play state
    playButton.label = isPlaying ? "Stop" : "Play"; // Update playButton label
    if (isPlaying) {
      playMelody(); // Start playing the melody
    } else {
      stopMelody(); // Stop playing the melody
    }
  }
  
  if (generateButton.isClicked(mouseX, mouseY)) {
    generateMelody(); // Generate a new melody
  }
  
  for (int i=0; i<numRectangles; i++) {
    rectangles[i].checkClick(true);
  }
}

void mouseReleased() {
  for (int i=0; i<numRectangles; i++) {
    rectangles[i].checkClick(false);
  }
}

void generateMelody() {
  for (int i = 0; i < 8; i++) {
    melody[i] = generateNote(); // Generate random notes in the E major scale
    sender.send("/gen_melody", melody[i]);
  }
  // Send melody once over UDP
  isMelodyGenerated = true;
}

int generateNote() {
  int[] scaleNotes = {
  40, 42, 44, 45, 47, 49, 51, 52, // One octave below
  52, 54, 56, 57, 59, 61, 63, 64, // Original octave
  64, 66, 68, 69, 71, 73, 75, 76  // One octave above
};
  return scaleNotes[(int)random(scaleNotes.length)];
}

void playMelody() {
  println("Melody played.");
}

void stopMelody() {
  // Implement the logic to stop the melody
  println("Melody stopped.");
  // Add your stopping logic here
}
