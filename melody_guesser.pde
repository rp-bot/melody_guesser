import oscP5.*;
import netP5.*;
import java.util.HashMap;

OscP5 oscP5;
NetAddress maxAddress;
SendMessage sender;

// UI-related variables
int tile_width = 140, tile_height = 250, starting_x = 20;
int numRectangles = 4;
Rectangle[] rectangles = new Rectangle[numRectangles];
Button[] lockInButtons = new Button[numRectangles];
Button playButton, startGameButton, notesSoFarButton;

// Game state variables
int[] melody = new int[8];
int[] guessedMelody = new int[8];
int currentGuessIndex = 0;
int chances = 3;
boolean isGameOver = false;
boolean isMelodyGenerated = false;
boolean isGameStarted = false;
boolean isPlaying = false;
boolean isPlayButtonEnabled = true;
int playButtonClickCount = 0;
String statusMessage = "";

// MIDI note mappings
HashMap<Integer, String> midiToNoteName = new HashMap<Integer, String>();

void setup() {
  // Set up the window size
  size(720, 1080);
  
  // Initialize the dictionary that maps MIDI numbers to note names
  initializeNoteDictionary();
  
  // Initialize rectangles and lock-in buttons for user input
  for (int i = 0; i < numRectangles; i++) {
    rectangles[i] = new Rectangle(starting_x + (i * 180), height - 200, tile_width, tile_height, 0, false);
    lockInButtons[i] = new Button(starting_x + (i * 180), height - 300, 100, 30, "Lock In");
  }

  // Create control buttons
  playButton = new Button(width - 120, 20, 100, 100, "Play\nFull\nMelody");
  startGameButton = new Button(20, 20, 120, 50, "Start Game");
  notesSoFarButton = new Button(20, 80, 150, 50, "Notes So Far");

  // Initialize the sender for OSC messages
  sender = new SendMessage("127.0.0.1", 7400);
}

void draw() {
  background(34, 32, 32); // Set the background color

  // Display game elements if the game is not over
  if (!isGameOver) {
    for (int i = 0; i < numRectangles; i++) {
      rectangles[i].display();
      lockInButtons[i].display();
    }
    
    textSize(24); // Set text size for the UI
    startGameButton.display();
    fill(255); // Set text color to white
    text("Plays: " + playButtonClickCount + "/5", width - 200, 40);

    // Show play and notes buttons, game status, and chances if the game has started
    if (isGameStarted) {
      playButton.display();
      notesSoFarButton.display();
      fill(255, 0, 0); // Set color for chances text
      text("Lives: " + chances, 250, 40);
      textAlign(LEFT);
      fill(255);
      text(statusMessage, width / 2, (height / 2) - 200);
      text(getCorrectGuessesText(), 20, height / 2);
    }
  } else {
    text("Game Over!", width / 2 - 50, height / 2); // Display game over message
  }
}

void startGame() {
  isGameStarted = true; // Set flag to indicate the game has started
  isGameOver = false; // Reset game over state
  chances = 3; // Reset player's chances to 3
  currentGuessIndex = 0; // Start with the first note in the melody
  assignNotesToRectangles(); // Assign notes to the rectangles for the guessing phase
}


void mousePressed() {
  // Check if the play button is clicked and enabled
  if (isPlayButtonEnabled && playButton.isClicked(mouseX, mouseY)) {
    playButtonClickCount++; // Increment play button click count

    // Disable the play button after 5 clicks
    if (playButtonClickCount >= 5) {
      isPlayButtonEnabled = false;
      playButton.label = "Disabled";
    }
    playMelody(); // Play the melody
  }

  // Check if the "Notes So Far" button is clicked
  if (notesSoFarButton.isClicked(mouseX, mouseY)) sender.send("/notes_so_far", 1);

  // Check if the start game button is clicked
  if (startGameButton.isClicked(mouseX, mouseY)) {
    generateMelody(); // Generate a new melody
    startGame(); // Start the game
  }

  // Process guesses if the game is ongoing
  if (isGameStarted && !isGameOver) {
    for (int i = 0; i < numRectangles; i++) {
      if (lockInButtons[i].isClicked(mouseX, mouseY)) checkGuess(i); // Check the guess for the clicked rectangle
    }
  }

  // Check clicks for each rectangle
  for (int i = 0; i < numRectangles; i++) rectangles[i].checkClick(true);
}
void mouseReleased() {
  // Check if mouse release affects any of the rectangles
  for (int i = 0; i < numRectangles; i++) {
    rectangles[i].checkClick(false); // Update each rectangle's click status to false
  }
}


void generateMelody() {
  // Loop to generate an 8-note melody
  for (int i = 0; i < 8; i++) {
    melody[i] = generateNote(); // Generate a random note in the E major scale
    sender.send("/gen_melody", melody[i]); // Send each note to the receiver via OSC
  }
  isMelodyGenerated = true; // Mark that the melody has been generated
}


void assignNotesToRectangles() {
  int correctNoteIndex = (int) random(numRectangles); // Randomly select one rectangle to display the correct note
  int correctNote = melody[currentGuessIndex]; // Get the current note to guess

  // Assign notes to rectangles, ensuring only one is correct
  for (int i = 0; i < numRectangles; i++) {
    if (i == correctNoteIndex) {
      rectangles[i].note = correctNote; // Assign the correct note to the chosen rectangle
      rectangles[i].isCorrectNote = true;
    } else {
      int randomNote;
      do {
        randomNote = generateNote(); // Generate a random note
      } while (randomNote == correctNote); // Ensure it is not the correct note

      rectangles[i].note = randomNote; // Assign a random incorrect note
      rectangles[i].isCorrectNote = false;
    }
  }
}

void checkGuess(int rectIndex) {
  // Check if the guessed note is correct
  if (rectangles[rectIndex].note == melody[currentGuessIndex]) {
    statusMessage = "Correct guess!"; // Update the status message
    sender.send("/guessed_melody", melody[currentGuessIndex]); // Send guessed note via OSC
    currentGuessIndex++; // Move to the next note

    // Check if the player has guessed all notes
    if (currentGuessIndex >= melody.length) {
      statusMessage = "You completed the melody!";
      isGameOver = true; // End the game
    } else {
      chances = 3; // Reset chances for the next note
      assignNotesToRectangles(); // Assign new notes to rectangles
    }
  } else {
    chances--; // Decrease chances for a wrong guess
    if (chances <= 0) {
      statusMessage = "Game Over!"; // Update the status message
      isGameOver = true; // End the game
    } else {
      statusMessage = "Wrong guess! " + chances + " chances left."; // Show remaining chances
    }
  }
}

int generateNote() {
  int[] scaleNotes = {
    64, 66, 68, 69, 71, 73, 75, 76, // Two octaves above original
    76, 78, 80, 81, 83, 85, 87, 88, 
    88, 90, 92, 93, 95, 97, 99, 100 
  };
  return scaleNotes[(int)random(scaleNotes.length)]; // Randomly return a note from the scale
}

void playMelody() {
  sender.send("/play_gen_m", 1); // Send OSC message to play the generated melody
}

String getCorrectGuessesText() {
  String guessesText = "";
  for (int i = 0; i < currentGuessIndex; i++) {
    guessesText += midiToNoteName.get(melody[i]) + " "; // Build a string with the correct guesses so far
  }
  return guessesText.trim(); // Return the formatted string
}

void initializeNoteDictionary() {
  // Map MIDI numbers to their corresponding note names
  midiToNoteName.put(64, "E");
  midiToNoteName.put(66, "F#");
  midiToNoteName.put(68, "G#");
  midiToNoteName.put(69, "A");
  midiToNoteName.put(71, "B");
  midiToNoteName.put(73, "C#");
  midiToNoteName.put(75, "D#");
  midiToNoteName.put(76, "E");
  midiToNoteName.put(78, "F#");
  midiToNoteName.put(80, "G#");
  midiToNoteName.put(81, "A");
  midiToNoteName.put(83, "B");
  midiToNoteName.put(85, "C#");
  midiToNoteName.put(87, "D#");
  midiToNoteName.put(88, "E");
  midiToNoteName.put(90, "F#");
  midiToNoteName.put(92, "G#");
  midiToNoteName.put(93, "A");
  midiToNoteName.put(95, "B");
  midiToNoteName.put(97, "C#");
  midiToNoteName.put(99, "D#");
  midiToNoteName.put(100, "E");
}
