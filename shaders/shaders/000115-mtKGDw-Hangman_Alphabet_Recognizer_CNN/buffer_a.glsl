// Buffer A (buffer) — Hangman+Alphabet Recognizer CNN by kishimisu
// https://www.shadertoy.com/view/mtKGDw

/* This buffers handles the hangman game data and the input layer */

// Is a character at a specific index in the hidden word ?
bool isCharAtPos(float char, int pos) {
    float charAtPos = texelFetch(iChannel0, ivec2(pos, R.y-2.), 0).r;
    return charAtPos-65. == char;
}

// Is a character part of the hidden word ?
bool isCharInWord(float char) {    
    for (int i = 0; i < word_size; i++)
        if (isCharAtPos(char, i)) 
            return true;     
    return false;
}

// Is the hidden word fully discoverd ?
bool isGameWon(float wordLength) {
    float charsFound = 0.;
    for (int i = 0; i < word_size; i++) {
        charsFound += min(1., texelFetch(iChannel0, ivec2(i, R.y-2.), 0).g);
    }
    return charsFound >= wordLength;
}

// Get the hidden word's total length
float getCurrentWordLength() {
    for (int i = 0; i < word_size; i++) {
        if (texelFetch(iChannel0, ivec2(i, R.y-2.), 0).r == 0.) 
            return float(i);
    }
    return float(word_size);
}

// Random value - https://www.shadertoy.com/view/4djSRW
float hash11(float p) {
    p = fract(p * .1031);
    p *= p + 33.33;
    return fract(p*p*2.);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord / R;
    vec2  m = iMouse.xy / R;
    ivec2 F = ivec2(fragCoord - .5);

    vec4 hangData = texelFetch(iChannel0, ivec2(0, R.y-1.), 0);
    vec4 predData = texelFetch(iChannel0, ivec2(1, R.y-1.), 0);
    vec4 col = texture(iChannel0, uv);
    
    bool clickOnTry = iMouse.z > 0. && m.y < .1 && m.x > iR/2.+.5 && hangData.g == 0.;
    bool resetGame  = iFrame == 0 ||                                // Reset game on the first frame
              predData.a != iResolution.x ||                        // Or if the resolution has changed
              iMouse.z > 0. && hangData.r > 0. && hangData.g == 0.; // Or on the first click after a game over
    
    if (resetGame) col *= 0.;
    
    // 2 frames after a new game started, fake a click on "Try"
    if (iFrame == int(predData.g)+2) {
        // Set the prediction to the first letter of the hidden word
        predData.r = texelFetch(iChannel0, ivec2(0, R.y-2.), 0).r-65.;
        clickOnTry = true;
    }
    
    // On manual character selection (direct click), fake "Try"
    vec2 id = floor((m  / vec2(iR, 1) - vec2(0, .2))*13.);
    if (iMouse.z > 0. && abs(id.y+.5) < 1. && id.x < 13. && hangData.g == 0. && !resetGame && float(iFrame)-predData.g > 2.) {
        // Set the prediction to the character located at the mouse position
        predData.r = id.x - 13.*id.y;
        clickOnTry = true;
    }

    // Game state management 1
    // r: game state   (0: playing,  1: win, 2: lose), 
    // g: click memory (0: no click, 1: click on last frame + reset canvas flag, 2: click on last frame), 
    // b: missed char count, 
    // a: left panel state (0: game, 1: neural network)
    if (F.x == 0 && F.y == int(R.y)-1) {        
        // Wait for mouse release
        if (col.g >= 1.) {
            if (iMouse.z <= 0.) col.g = 0.;
        }
        // Clicked on "Try" button
        else if (clickOnTry) {
            // Get current network prediction
            float char = predData.r;
            
            // Is the character in the hidden word ?
            bool isInWord = isCharInWord(char); 
            // Has the character been already tried ?
            bool alreadyTried = texelFetch(iChannel0, ivec2(int(char), R.y-3.), 0).r > 0.;
            
            // On a new failed attempt, increase the missed character count
            if (!isInWord && !alreadyTried) col.b++;                    

            // Remember that mouse is clicked
            col.g = 1.;   
        }
        // Clicked on "Show Game/Neural Network" button
        else if (iMouse.z > 0. && m.y < .1 && m.x < iR) {
            // Invert the left panel state
            col.a = 1. - col.a;
            // Remember that mouse is clicked
            col.g = 2.;
        }
        else if (iMouse.z > 0.)
            col.g = 2.;
          
        // Game win
        if (isGameWon(predData.b) && !resetGame && predData.b > 0. && hangData.r == 0.)
            col.r = 1.;
        // Game over
        else if (col.b >= MAX_ATTEMPTS)
            col.r = 2.;  
    }
    // Game state management 2
    // r: current prediction 
    // g: frame at game start 
    // b: current word length
    // a: current resolution x
    else if (F.x == 1 && F.y == int(R.y)-1) { 
        // Upon starting a new game, store the current frame number
        if (resetGame) {
            col.g = float(iFrame);
        }
        
        // 1 frame after starting a new game, store the current word length
        if (iFrame == int(predData.g)+1) {
            col.b = getCurrentWordLength();
        } 
        // On every other frame, retrieve the prediction from Buffer D
        else {
            col.r = texelFetch(iChannel1, ivec2(int(num_classes), 1), 0).r;
        }
        
        // Store the current width to detect canvas resize
        col.a = iResolution.x;
    }
    // Hidden word management
    // [0, word_size-1], 
    // r: char ID, 
    // g: char state (0: undiscovered, >=1: discovered)
    else if (F.x < word_size && F.y == int(R.y)-2) {
        // Upon starting a new game, select a new random word from the dictionary
        if (resetGame) {
            float rng = hash11(iDate.w) * 10.;
            float id = floor(rng);
            int[40] words;
            
            if      (id == 0.) words = words0;
            else if (id == 1.) words = words1;
            else if (id == 2.) words = words2;
            else if (id == 3.) words = words3;
            else if (id == 4.) words = words4;
            else if (id == 5.) words = words5;
            else if (id == 6.) words = words6;
            else if (id == 7.) words = words7;
            else if (id == 8.) words = words8;
            else               words = words9;

            id = floor(hash11(rng+iTime+iDate.w) * 4.);
            int charIndex = int(id) * word_size + F.x;
            col.r = float(words[charIndex]);
        }
        
        // Update when click "Try"
        if (clickOnTry) {
            // Increment the current character state upon a click if the
            // character is valid regarding the current prediction
            col.g += float(isCharAtPos(predData.r, F.x));
        }
        
        // Force show hidden word on game over
        if (hangData.b >= MAX_ATTEMPTS && !resetGame) col.g = 1.;
    }
    // Alphabet management
    // for pixels x in [0, 26], 0: not tried, 1: success, 2: failed
    else if (F.x < 26 && F.y == int(R.y)-3) {
        // Update only the corresponding character when click "Try"
        if (clickOnTry && float(F.x) == predData.r) {
            col.r = isCharInWord(predData.r) ? 1. : 2.;
        }
    }
    // Drawing
    else {
        bool clickOnClear = iMouse.z > 0. && m.y < .1 && m.x > iR && m.x < iR/2.+.5 && hangData.g == 0.;
        vec2  m = (iMouse.xy - fragCoord) / R.y;
        float d = smoothstep(.06, 0., length(m)); // "Pen" intensity
        d *= step(0., iMouse.z);                  // Only draw on mouse press
        col = clamp(col + d, 0., 1.);             // Clamp in [0-1] range
                
        // Clear canvas conditions
        if (resetGame || clickOnClear || clickOnTry || hangData.g == 1.) col *= 0.;
    }
            
    fragColor = col;
}