// Global array to store melody notes
[0] @=> int melody[];
[0] @=> int notes_so_far[];

// Declare a global integer variable to act as a boolean
0 => int estimateFrequencyActive;

// Global variable for tempo in beats per minute
90 => float globalTempo;

// Function to convert MIDI note number to frequency
fun float midiToFreq(int midiNote) {
    return 440.0 * Math.pow(2, (midiNote - 69) / 12.0);
}

// Function to play a sine wave with ADSR envelope
fun void playSawWithADSR(float freq) {
    // Create a saw oscillator and ADSR envelope
    SawOsc saw => ADSR e => LPF lpf => dac;
    
    // Set the frequency of the saw wave
    freq => saw.freq;
    
    // Set the cutoff frequency of the low-pass filter
    2000.0 => lpf.freq;
    
    // Set ADSR parameters: attack, decay, sustain level, release
    e.set(10::ms, 50::ms, 0.5, 300::ms);
    
    // Set gain
    0.5 => saw.gain;
    
    // Start the envelope (attack phase)
    e.keyOn();
    
    // Wait for the duration of attack + decay + sustain
    500::ms => now;
    
    // Release the envelope (release phase)
    e.keyOff();
    
    // Wait for the release phase to complete
    e.releaseTime() => now;
}

// Function to estimate frequency using FFT
fun void estimateFrequency() {
    // Set up audio input
    adc => FFT fft => blackhole;
    1024 => fft.size;
    UAnaBlob blob;
    
    // Set up OSC sender
    OscOut oscOut;
    oscOut.dest("localhost", 9001); // Correct method to set host and port
    
    while (true) {
        // Check if estimation is active
        if (estimateFrequencyActive) {
            1::second => now; // Wait for 1 second
            
            fft.upchuck();
            fft.upchuck() @=> blob;
            
            int maxIndex;
            float maxMagnitude;
            0.0 => maxMagnitude;
            for (0=>int i; i < blob.fvals().size(); i++) {
                if (blob.fvals()[i] > maxMagnitude) {
                    blob.fvals()[i] => maxMagnitude ;
                    i=>maxIndex ;
                }
            }
            
            float detectedFrequency;
            maxIndex * (44100.0 / 1024)=>detectedFrequency;
            
           
            // Start and send OSC message
            oscOut.start("/mic_freq");
            oscOut.add(detectedFrequency);
            oscOut.send();
            
            <<< "Detected Frequency:", detectedFrequency >>>;
        } else {
            100::ms => now; // Short wait when not active
        }
    }
}

    // Create an OSC receiver
    OscIn oin;
    OscMsg msg;
    
    // Set port number for OSC messages
    9000 => oin.port;
    
    // Add address patterns for incoming messages
    oin.addAddress("/play_n");
    oin.addAddress("/gen_melody");
    oin.addAddress("/play_gen_m");
    oin.addAddress("/guessed_melody");
    oin.addAddress("/notes_so_far");
    oin.addAddress("/mic");

    // Infinite loop to listen for OSC messages
    while (true) {
        // Wait for an OSC message to arrive
        oin => now;
        
        // Process the incoming message
        while (oin.recv(msg)) {
            if (msg.address == "/play_n") {
                int midiNote;
                msg.getInt(0) => midiNote;
                float freq;
                midiToFreq(midiNote) => freq;
                <<< "Received MIDI Note:", midiNote, "Frequency:", freq >>>;
                spork ~ playSawWithADSR(freq);
            } else if (msg.address == "/gen_melody") {
                melody.clear();
                for (0 => int i; i < msg.numArgs(); i++) {
                    int note;
                    msg.getInt(i) => note;
                    melody << note;
                    <<< "Melody Note", i, ":", note >>>;
                }
                <<< "Complete Melody:", melody >>>;
            } else if (msg.address == "/play_gen_m") {
                (60.0 / globalTempo * 1000.0) => float noteDurationMs;
                noteDurationMs::ms => dur noteDuration;

                for (0 => int i; i < melody.size(); i++) {
                    float freq;
                    midiToFreq(melody[i]) => freq;
                    spork ~ playSawWithADSR(freq);
                    noteDuration => now;
                }
            } else if (msg.address == "/guessed_melody") {
                for (0 => int i; i < msg.numArgs(); i++) {
                    int guessedNote;
                    msg.getInt(i) => guessedNote;
                    notes_so_far << guessedNote;
                    <<< "Guessed Note", i, ":", guessedNote >>>;
                }
                <<< "Notes So Far:", notes_so_far >>>;
            } else if (msg.address == "/notes_so_far") {
                (60.0 / globalTempo * 1000.0) => float noteDurationMs;
                noteDurationMs::ms => dur noteDuration;

                for (0 => int i; i < notes_so_far.size(); i++) {
                    float freq;
                    midiToFreq(notes_so_far[i]) => freq;
                    spork ~ playSawWithADSR(freq);
                    noteDuration => now;
                }
            } else if (msg.address == "/mic") {
                !estimateFrequencyActive => estimateFrequencyActive;
                <<< "Toggled Frequency Estimation:", estimateFrequencyActive >>>;
            }
        }
    }



spork ~ estimateFrequency();