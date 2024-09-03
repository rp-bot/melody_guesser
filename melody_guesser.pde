import oscP5.*;
import netP5.*;
import java.util.HashMap;
OscP5 oscP5;
NetAddress maxAddress;
SendMessage sender;
int tile_width, tile_height, starting_x;
int numRectangles = 4;
Rectangle[] rectangles = new Rectangle[numRectangles];
HashMap<Integer, String> midiToNoteName = new HashMap<Integer, String>();

int[] melody = new int[8]; // Array to hold the generated melody
int[] guessedMelody = new int[8]; // Array to hold the guessed notes
int currentGuessIndex = 0; // Index for the current note to be guessed
int chances = 3; // Player's chances
boolean isGameOver = false;
boolean isMelodyPlayed = false;
boolean isMelodyGenerated = false;
// Button variables
Button[] lockInButtons = new Button[numRectangles];
Button playButton;
Button generateButton;
Button startGameButton;
boolean isPlaying = false; // State of the play/stop playButton
int playButtonClickCount = 0; // Counter for play button clicks
boolean isPlayButtonEnabled = true; // Flag to check if play button is enabled
boolean isGameStarted = false;
Button notesSoFarButton;
String statusMessage = "";

void setup() {
  size(720, 1080);
  tile_width = 140;
  tile_height = 250;
  starting_x = 20;
  
  initializeNoteDictionary();
  
  for (int i =0; i <numRectangles; i++) {
    rectangles[i] = new Rectangle(starting_x + (i * 180), height - 200, tile_width, tile_height, 0, false);

    lockInButtons[i] = new Button(starting_x + (i * 180), height - 300, 100, 30, "Lock In");
  }

  playButton = new Button(width-120, 20, 100, 100, "Play\nFull\nMelody");

  //generateButton = new Button(20, 20, 100, 50, "Generate");
  startGameButton = new Button(20, 20, 120, 50, "Start Game");
  notesSoFarButton = new Button(20, 80, 150, 50, "Notes So Far"); // New button

  sender = new SendMessage("127.0.0.1", 7400);
}
void draw() {
  background(34, 32, 32);



  if (!isGameOver) {
    for (int i=0; i<numRectangles; i++) {
      rectangles[i].display();
      lockInButtons[i].display();
    }


    textSize(24);
    startGameButton.display();
    fill(255);

    text("Plays: " + playButtonClickCount +"/5", width-200, 40);
    if (isGameStarted) {
      playButton.display();
      notesSoFarButton.display();
      fill(255,0,0);
      text("Lives: " + chances, 250, 40);
      textAlign(LEFT);
      fill(255);
      text(statusMessage, width/2, (height/2)-200);
      text(getCorrectGuessesText(), 20, height/2);
    }
  } else {
    text("Game Over!", width / 2 - 50, height / 2);
  }
}

void mousePressed() {
  if (isPlayButtonEnabled && playButton.isClicked(mouseX, mouseY)) {
    //isPlaying = !isPlaying; // Toggle the play state
    //playButton.label = isPlaying ? "Stop" : "Play"; // Update button label
    playButtonClickCount++; // Increment play button click count

    if (playButtonClickCount >= 5) {
      isPlayButtonEnabled = false; // Disable the play button after 5 clicks
      playButton.label = "Disabled";
    }
    playMelody();
  }
  if (notesSoFarButton.isClicked(mouseX, mouseY)) {
    sender.send("/notes_so_far", 1); // Send the message when the button is clicked
  }

  if (startGameButton.isClicked(mouseX, mouseY)) {
    generateMelody();
    startGame(); // Start the game
  }

  if (isGameStarted && !isGameOver) {
    for (int i = 0; i < numRectangles; i++) {
      if (lockInButtons[i].isClicked(mouseX, mouseY)) {
        checkGuess(i); // Check the guess for the current note
      }
    }
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

void startGame() {
  isGameStarted = true;
  isGameOver = false;
  chances = 3; // Reset chances
  currentGuessIndex = 0; // Start with the first note
  assignNotesToRectangles(); // Assign notes to rectangles

}

void assignNotesToRectangles() {
  int correctNoteIndex = (int) random(numRectangles);
  int correctNote = melody[currentGuessIndex];

  for (int i = 0; i < numRectangles; i++) {
    if (i == correctNoteIndex) {
      rectangles[i].note = correctNote;
      rectangles[i].isCorrectNote = true;
    } else {
      int randomNote;
      do {
        randomNote = generateNote();
      } while (randomNote == correctNote);

      rectangles[i].note = randomNote;
      rectangles[i].isCorrectNote = false;
    }
  }
}



void checkGuess(int rectIndex) {
  if (rectangles[rectIndex].note == melody[currentGuessIndex]) {
    statusMessage = "Correct guess!"; // Update the status message
    sender.send("/guessed_melody", melody[currentGuessIndex]);
    currentGuessIndex++;
    if (currentGuessIndex >= melody.length) {
      statusMessage = "You completed the melody!";
      isGameOver = true;
    } else {
      chances = 3; // Reset chances for the next note
      assignNotesToRectangles(); // Assign new notes to rectangles
    }
  } else {
    chances--;
    if (chances <= 0) {
      statusMessage = "Game Over!"; // Update the status message
      isGameOver = true;
    } else {
      statusMessage = "Wrong guess! " + chances + " chances left."; // Update message with remaining chances
    }
  }
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
  sender.send("/play_gen_m", 1);
}

void stopMelody() {
  // Implement the logic to stop the melody
  sender.send("/play_gen_m", 0);
  // Add your stopping logic here
}


String getCorrectGuessesText() {
  String guessesText = "";
  for (int i = 0; i < currentGuessIndex; i++) {
    guessesText += midiToNoteName.get(melody[i]) + " "; // Use the dictionary to get note names
  }
  return guessesText.trim(); // Return the string with trailing spaces removed
}

// Initialize the MIDI-to-note dictionary
void initializeNoteDictionary() {
  midiToNoteName.put(40, "E");
  midiToNoteName.put(42, "F#");
  midiToNoteName.put(44, "G#");
  midiToNoteName.put(45, "A");
  midiToNoteName.put(47, "B");
  midiToNoteName.put(49, "C#");
  midiToNoteName.put(51, "D#");
  midiToNoteName.put(52, "E");
  midiToNoteName.put(54, "F#");
  midiToNoteName.put(56, "G#");
  midiToNoteName.put(57, "A");
  midiToNoteName.put(59, "B");
  midiToNoteName.put(61, "C#");
  midiToNoteName.put(63, "D#");
  midiToNoteName.put(64, "E");
  midiToNoteName.put(66, "F#");
  midiToNoteName.put(68, "G#");
  midiToNoteName.put(69, "A");
  midiToNoteName.put(71, "B");
  midiToNoteName.put(73, "C#");
  midiToNoteName.put(75, "D#");
  midiToNoteName.put(76, "E");
}
