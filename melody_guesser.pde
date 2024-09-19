import oscP5.*;
import netP5.*;
import java.util.HashMap;

OscP5 oscP5;
NetAddress maxAddress;


// UI-related variables
int tile_width = 140, tile_height = 250, starting_x = 20;
int numRectangles = 4;
Rectangle[] rectangles = new Rectangle[numRectangles];
Button[] lockInButtons = new Button[numRectangles];
Button playButton, startGameButton, notesSoFarButton, micButton;

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
boolean isMicOn = false;
boolean isBackgroundGreen = false;

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
  micButton = new Button(width - 120, 150, 100, 50, "Mic Off");

  // Initialize the sender for OSC messages
  oscP5 = new OscP5(this, 9001); // Listen on port 12000
  maxAddress = new NetAddress("127.0.0.1", 9000);
}

void draw() {
  //oscEvent();
  if (isBackgroundGreen) {
    background(0, 255, 0); // Green background
  } else {
    background(34, 32, 32); // Default background
  }

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
      micButton.display();
      notesSoFarButton.display();
      fill(255, 0, 0); // Set color for chances text
      text("Lives: " + chances, 250, 40);
      textAlign(LEFT);
      fill(255);
      text("Use Mic to\nguess the\ncorrect note", width - 120, 250);
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
  if (notesSoFarButton.isClicked(mouseX, mouseY)) sendOscMessage("/notes_so_far", 1);

  // Check if the start game button is clicked
  if (startGameButton.isClicked(mouseX, mouseY)) {
    generateMelody(); // Generate a new melody
    startGame(); // Start the game
  }
  
  if (micButton.isClicked(mouseX, mouseY)) {
    isMicOn = !isMicOn; // Toggle the mic state
    micButton.label = isMicOn ? "Mic On" : "Mic Off"; // Update button label
    sendOscMessage("/mic", isMicOn ? 1 : 0); // Send 1 if mic is on, 0 if off
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
    //sendOscMessage("/gen_melody", melody[i]); // Send each note to the receiver via OSC
  }
  
  OscMessage melody_message = new OscMessage("/gen_melody");
  for (int note : melody) {
    melody_message.add(note);
  }
  
  oscP5.send(melody_message, maxAddress);
  
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
    sendOscMessage("/guessed_melody", melody[currentGuessIndex]); // Send guessed note via OSC
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
    52, 54, 56, 57, 59, 61, 63, 64,
    64, 66, 68, 69, 71, 73, 75, 76, // Two octaves above original
  };
  return scaleNotes[(int)random(scaleNotes.length)]; // Randomly return a note from the scale
}

void playMelody() {
  sendOscMessage("/play_gen_m", 1); // Send OSC message to play the generated melody
}

String getCorrectGuessesText() {
  String guessesText = "";
  for (int i = 0; i < currentGuessIndex; i++) {
    guessesText += midiToNoteName.get(melody[i]) + " "; // Build a string with the correct guesses so far
  }
  return guessesText.trim(); // Return the formatted string
}

void initializeNoteDictionary() {
  // Map MIDI numbers to their corresponding note names with octave numbers
  midiToNoteName.put(52, "E3");
  midiToNoteName.put(54, "F#3");
  midiToNoteName.put(56, "G#3");
  midiToNoteName.put(57, "A3");
  midiToNoteName.put(59, "B3");
  midiToNoteName.put(61, "C#4");
  midiToNoteName.put(63, "D#4");
  midiToNoteName.put(64, "E4"); // Start of original octave (E4)
  midiToNoteName.put(66, "F#4");
  midiToNoteName.put(68, "G#4");
  midiToNoteName.put(69, "A4");
  midiToNoteName.put(71, "B4");
  midiToNoteName.put(73, "C#5");
  midiToNoteName.put(75, "D#5");
  midiToNoteName.put(76, "E5"); // Start of the next octave (E5)
  midiToNoteName.put(78, "F#5");
  midiToNoteName.put(80, "G#5");
  midiToNoteName.put(81, "A5");
  midiToNoteName.put(83, "B5");
  midiToNoteName.put(85, "C#6");
  midiToNoteName.put(87, "D#6");
  midiToNoteName.put(88, "E6"); // Start of the next octave (E6)
  midiToNoteName.put(90, "F#6");
  midiToNoteName.put(92, "G#6");
  midiToNoteName.put(93, "A6");
  midiToNoteName.put(95, "B6");
  midiToNoteName.put(97, "C#7");
  midiToNoteName.put(99, "D#7");
  midiToNoteName.put(100, "E7");
}


void sendOscMessage(String messageAddress, int value) {
  OscMessage msg = new OscMessage(messageAddress);
  msg.add(value);
  oscP5.send(msg, maxAddress);
}

void oscEvent(OscMessage theOscMessage) {
  // Check the address pattern of the received message
  if (theOscMessage.checkAddrPattern("/mic_freq")) {
    
    println("recieved");
    // Assuming the message from Max is a float
    float receivedValue = theOscMessage.get(0).floatValue();
 

    // Convert the correct MIDI note to frequency
    int correctMidiNote = melody[currentGuessIndex]; 
    float correctFrequency = midiToFrequency(correctMidiNote); // Convert to frequency

    // Check if the received value is within +/-1 of the correct frequency
    if (receivedValue >= correctFrequency - 5 && receivedValue <= correctFrequency + 5 && isGameStarted) {
      isBackgroundGreen = true; // Set background to green
    } else {
      isBackgroundGreen = false; // Set background to default color
    }
  }
}

// Function to convert MIDI note number to frequency in Hertz
float midiToFrequency(int midiNote) {
  return 440 * pow(2, (midiNote - 69) / 12.0);
}
