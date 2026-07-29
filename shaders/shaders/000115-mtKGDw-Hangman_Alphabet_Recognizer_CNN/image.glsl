// Image (image) — Hangman+Alphabet Recognizer CNN by kishimisu
// https://www.shadertoy.com/view/mtKGDw

/* Handwritten Alphabet Recognizer CNN + Hangman - https://www.shadertoy.com/view/mtKGDw
   (Can take several seconds to compile) 
   
   This shader implements a Convolutional Neural Network trained on uppercase 
   handwritten characters, combined with a hangman game for even more fun!
   
   /// HOW TO PLAY / INFOS ///
   
   - Draw *uppercase* letters in the right area
   - Click on "Try" to submit the current letter
   - Click on "Clear" to reset the draw area
   - Click "Show Neural Network" to visualize the prediction in real time!
   
   - You have a maximum of 7 failed attempts before losing the game!
     (You can change the difficulty in the "Common" tab)
     
   - There are 40 different words that can be guessed
   
   - The model struggles for the letter "I", be sure to add the two horizontal bars.
   - You can also click on individual characters in the bottom-right alphabet if
     it really struggles to recognize a letter
   
   /// Technical Details ///
   
   Python Notebook created for this project: https://colab.research.google.com/drive/18_2SZPejs1BaZH1EofFgEiA9HG2fBR7u
   
   This implementation is a bigger version of my previous Handwritten Digit Recognizer.
   Here's a comparision between the two models:
   
                        Digit CNN          Alphabet CNN
   # of parameters      2,023              6,490
   # of convolutions    2                  4
   # of feature maps    8-5                8-8-10-10
     per layer
   output size          10                 26
   
   I trained the model on two datasets for a total of 445250 training examples: 
       - EMNIST (https://arxiv.org/pdf/1702.05373.pdf)
       - A-Z Handwritten Alphabets (Available on Kaggle)
   I first used a combination of lowercase and uppercase letters, but finally ended up
   keeping only uppercase letters to increase accuracy, while constraining the case.
   The accuracy on the testing set is around 96%, however there are some disparities
   within the letters, the model struggles the most on the I, D and V letters.
   
   /// Network Architecture ///
   
   - All convolutions have a kernel size of 3x3 and a stride of 1.
   The Buffer  A handles the input
   The buffers C and D handles all the convolution and max pooling layers
   The Buffer  D handles the fully connected layer and output
   
   - (Buffer A) Input Layer     : 28x28    = 784 inputs
   - (Buffer B) Convolution     : 28x28    => 8x26x26   
   - (Buffer C) Convolution     : 8x26x26  => 8x24x24
   - (Buffer B) Max Pooling     : 8x24x24  => 8x12x12   
   - (Buffer C) Convolution     : 8x12x12  => 10x10x10   
   - (Buffer B) Convolution     : 10x10x10 => 10x8x8   
   - (Buffer C) Max Pooling     : 10x8x8   => 10x4x4
   - (Buffer D) Fully Connected : 10x4x4   => 26
   - (Buffer D) Softmax         : 26       => 1
   
   I alternated the layers between buffers B and C in order to be able
   to calculate multpiple layers in a single frame. This way, the prediction
   happens on a total of 4 frames instead of 8.
   
   - When you click on "Show Neural Network", only the Convolution feature
   maps are displayed, not the max pooling ones.
   
   /// Hangman Game ///
   
   - This is the first time I try to make game logic within shaders. 
   Everything related to the hangman game state (word selection, update, game over) 
   happens inside the Buffer A. It's hard to test all cases and all side effects,
   please let me know if you encounter something weird!
   
   - I split the 40 words into 10 arrays of 4 words (40 chars) because having a single 
   array of 40 words (400 chars) would alter the performances drastically. 
   It seems way more efficient to have 10 if/else rather than one big array lookup
*/

// Create text strings
makeString (printShowNN)      _S _h _o _w __ _N _e _u _r _a _l __ _N _e _t _w _o _r _k _end
makeString (printClickAny)    _bl __ _C _l _i _c _k __ _A _n _y _w _h _e _r _e __ _br _end
makeString (printShowGame)    _S _h _o _w __ _G _a _m _e __ _S _c _r _e _e _n _end
makeString (printFC)          _F _u _l _l _y __ _C _o _n _n _e _c _t _e _d _end
makeString (printCongrats)    _C _o _n _g _r _a _t _u _l _a _t _i _o _n _s _end
makeString (printOutputLayer) _O _u _t _p _u _t __ _L _a _y _e _r _end
makeString (printPrediction)  _P _r _e _d _i _c _t _i _o _n _dd _end
makeString (printInputLayer)  _D _r _a _w __ _A _r _e _a _end
makeString (printGameOver)    _G _a _m _e __ _O _v _e _r _end
makeString (printClear)       _C _l _e _a _r _end
makeStringI(printConv)        _C _o _n _v _o _l _u _t _i _o _n __ _dig(i) _end
makeStringI(printTry)         _T _r _y __ _qt _ch(i) _qt _end

// Drawing
float rect(vec2 p, vec2 b) {
    vec2 d = abs(p)-b;
    return length(max(d,0.)) + min(max(d.x,d.y),0.);
}
float seg(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p-a, ba = b-a;
    return .05/length(pa - ba*(clamp(dot(pa,ba)/dot(ba,ba), 0., 1.)));
}
vec3 drawHangman(vec2 uv, float missed) {
    vec2 d = vec2(0);
    missed *= max(1., 11./MAX_ATTEMPTS);
    
    d += seg(uv,-vec2(1, 0  ), vec2(1,   0  )) * vec2(step(1. , missed), 1);     
    d += seg(uv, vec2(0, 0  ), vec2(0,   10 )) * vec2(step(1.5, missed), 1);
    d += seg(uv, vec2(0, 10 ), vec2(7,   10 )) * vec2(step(3. , missed), 1);
    d += seg(uv, vec2(0, 8  ), vec2(2,   10 )) * vec2(step(4. , missed), 1);
    d += seg(uv, vec2(5, 10 ), vec2(5,   7.3)) * vec2(step(5. , missed), 1);
    d += .07/abs(length(uv - vec2(5,6.5))-.75) * vec2(step(6. , missed), 1);
    d += seg(uv, vec2(5, 5.7), vec2(5  , 3.5)) * vec2(step(7. , missed), 1);
    d += seg(uv, vec2(5, 3.5), vec2(4.3, 1.5)) * vec2(step(8. , missed), 1);
    d += seg(uv, vec2(5, 3.5), vec2(5.5, 1.5)) * vec2(step(9. , missed), 1);
    d += seg(uv, vec2(5, 4.5), vec2(3.5, 6  )) * vec2(step(10., missed), 1);
    d += seg(uv, vec2(5, 4.5), vec2(6.5, 6  )) * vec2(step(11., missed), 1);
   
    return vec3(d.y*.25 + d.x*1.25);
}
// Color palette
vec3 pal(float x) {
    return cos(6.28318*(vec3(1.18)*x*.1-vec3(2.642, 2.392, 2.322)))*.5+.5;
}

// Displays a portion of a texture containing feature map data
// p : normalized uv coordinates (0-1)
// s : scaling factor
// r.xy : x/y start (in pixels)
// r.zw : x/y end   (in pixels)
vec3 displayFeatureMaps(vec2 p, vec2 s, vec4 r, float feature_maps_count, sampler2D smp) { 
    p = p*s + vec2(1.-s.x,0)/2.; // scale and center uvs
    
    float fp = 1./feature_maps_count;
    float id = floor(p.x*feature_maps_count); // current feature map id
    float m = 1.1; // border width
    
    // check bounds
    if (min(p.x,p.y) < 0. || max(p.x,p.y) > 1. || abs(mod(p.x, fp) - fp*.5) > fp/m/2. || abs(p.y-.5) > 1./m/2.) 
        return vec3(0);
    
    m *= .999;               // fix overflow issue
    p *= m;                  // scale down
    p.x -= (m-1.) * id * fp; // offset x from id
    p.x -= (m-1.) * .5 * fp; // re-center x
    p.y -= (m-1.) * .5;      // re-center y
    p *= r.zw / R;           // crop
    p.xy += r.xy/R;          // offset origin
    
    float val = texture(smp, p).r; // Get value
    return pal(val); // Return mapped color
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord / R;
    vec3 col;
    
    vec4 hangData = texelFetch(iChannel0, ivec2(0, R.y-1.), 0);
    vec2 predData = texelFetch(iChannel2, ivec2(num_classes, 1), 0).rg; // r: index, g: confidence
        
    uv.x *= iAspect;

    // Left part of the screen (visualizations)
    if (uv.x < iAspect - 1.) {
        // Display Game Screen
        if (hangData.a == 0.) {
            // "Show Neural Network" button
            if (uv.y < .11) {      
                col += printShowNN(uv*11.5 - vec2(0,.1));
            }
            else {
                // Draw hangman
                float highlightAmount = hangData.b / MAX_ATTEMPTS;
                vec3 highlightColor = mix(vec3(0,1,0), vec3(1,.4,.1), abs(hangData.r-1.));
                vec3 hangmanColor = mix(vec3(1), highlightColor*(1.2+sin(iTime*(1.+highlightAmount*3.))*.25), highlightAmount);
                col += drawHangman(uv*20. - vec2(4,8.5), hangData.b) * hangmanColor;

                uv = fragCoord / R / vec2(iR, 1) - vec2(0, .2);
                vec2 id = floor(uv*13.);
                
                // Draw alphabet
                if (abs(id.y+.5) < 1.) {
                    float char_state = texelFetch(iChannel0, ivec2(id.x - id.y*13., R.y-3.), 0).r;
                    col += char(iChannel3, uv*vec2(13.,13.5) - id, 65 + int(id.x) - int(id.y)*13) *
                           mix(mix(vec3(1), vec3(0,1,0), char_state), vec3(1,0,0), clamp(char_state-1., 0., 1.));
                }
                else {
                    uv.x -= .13;
                    uv *= vec2(1.12, .8);
                    id = floor(uv*13.);
                    
                    float current_word_size = texelFetch(iChannel0, ivec2(1, R.y-1.), 0).b;
                    
                    // Draw current word
                    if (id.x >= 0. && id.x < current_word_size && id.y == 1.) {
                        vec2 char_state = texelFetch(iChannel0, ivec2(id.x, R.y-2.), 0).rg;
                        vec3 char_color = hangData.r == 1. ? vec3(0,1,0) : hangData.r == 2. ? vec3(1,0,0) : vec3(1);
                        col += char(iChannel3, (uv*13. - id + vec2(.5,0))*vec2(.55,1), char_state.y == 0. ? 95 : int(char_state.x)) * char_color;
                    }
                }
            }
        }
        // Display Neural Network Screen
        else {
            // "Show Game Screen" button
            if (uv.y < .11) {      
                col += printShowGame(uv*11.5 - vec2(.6,.1));
            }
            // Prediction panel
            else if (uv.y < .22) { 
                uv = vec2(uv.x - .1, uv.y - .12) * 12.;
                col += vec3(1,0,0) * char(iChannel3, uv*.7 - vec2(3.5,-.15), 65 + int(predData.x));
                col = mix(pal(predData.y*3.), col, length(col));
                col = mix(col, 1.-col, printPrediction(uv));
            }
            // Output panel
            else if (uv.y < .47) {
                // Transform to upper right area
                vec2 tuv = vec2(uv.x / (iAspect - 1.), (uv.y-.22) / (.43-.22));
                // Current output index
                float idx = floor(tuv.x * num_classes);

                // Output value for the current index
                float val = texelFetch(iChannel2, ivec2(int(idx), 1), 0).r;
                // Apply the softmax function
                val = val; 

                // Draw bars
                col = mix(vec3(1,0,0), vec3(0,1,0), val) * smoothstep(0., .01, val - tuv.y);   
                col = pal(val*2.5) * smoothstep(0., .01, val - tuv.y);

                // Draw "output" text
                uv = vec2(uv.x, uv.y-.41) * 22.;
                col += printOutputLayer(uv);

                // Draw digits
                tuv = vec2(fract(tuv.x*num_classes), tuv.y*4.);
                col += vec3(char(iChannel3, tuv, 65 + int(idx))); 
            }
            // Fully connected layer
            else if (uv.y < .5) {
                vec2 tuv = vec2(uv.x / (iAspect - 1.), (uv.y-.47) / (.48-.47));
                float id = floor(tuv.x * 16. * f6);
                float x = mod(id, 4.*f6);
                float y = floor(id / (4.*f6));

                col = pal(texelFetch(iChannel1, ivec2(x,y+24.+10.), 0).r);
            }
            // Feature maps
            else {
                // Display texts
                uv = (uv - vec2(0,.96)) * 24.;
                col += printConv(uv, 1);

                uv.y += 3.;
                col += printConv(uv, 2);

                uv.y += 2.85;
                col += printConv(uv, 3);

                uv.y += 2.5;
                col += printConv(uv, 4);

                uv.y += 2.4;
                col += printFC(uv);

                // Display feature maps
                uv  = fragCoord / R;
                uv.x = uv.x / iR;

                uv.y -= .88;
                col += displayFeatureMaps(uv, 1.4*vec2(10./f1,12), vec4(0, 0, 26.*f1, 26), f1, iChannel0);
                uv.y += .115;
                col += displayFeatureMaps(uv, 1.44*vec2(10./f2,12.), vec4(0, 0, 24.*f2, 24), f2, iChannel1);

                uv.y += .11;
                col += displayFeatureMaps(uv, 1.48*vec2(10./f4,12.), vec4(0, 24, 10.*f4, 10), f4, iChannel1);

                uv.y += .1;
                col += displayFeatureMaps(uv, 1.52*vec2(10./f5,12.), vec4(0, 26+12, 8.*f5, 8), f5, iChannel0);

            }
        }
    }
    // Right part of the screen
    else {
        // Display input layer
        uv.x = uv.x - iAspect + 1.;
        col += printInputLayer((uv-vec2(0,.9))*15.);
        col += texture(iChannel0, fragCoord / R).r;
        
        // "Clear" button
        uv *= 10.;
        uv.x -= 1.;
        col += printClear(uv);
        col += vec3(1,.8,0.2) * .1 / abs(rect(uv - vec2(1.75,0), vec2(2,1)))*.25;
        
        // "Try" button
        uv.x -= 4.2;
        col += printTry(uv, int(predData.x));
        col += vec3(0.14,1,0.31) * .1 / abs(rect(uv - vec2(2,0), vec2(2,1)))*.25; 
    }
    
    // Switch screen button (contour only)
    uv = fragCoord / R;
    col += vec3(0.14,1,1.) * .002 / abs(rect(uv-vec2(iR/2.,0), vec2(.95*iR/2.,.1)));

    // Game over messages
    if (hangData.r > 0.) {
        vec3 tint = mix(vec3(0,.9,0), vec3(.9,0,0), hangData.r-1.);
        
        // WIP: I need to redo all this to properly center
        // the game over messages
        uv = fragCoord / R;
        uv.y -= .5;
        uv.y *= 4.;
        uv.y += .5 ;
        
        uv.x -= .7 - mix(.22, .15, hangData.r-1.);
        uv.x *= 3.;
        uv.y -= .33;
        uv.x *= iAspect;
        uv *= 3.;
        col += (hangData.r == 1. ? printCongrats(uv) : printGameOver(uv)) * tint;
        
        uv += vec2(.5, 2.1);
        uv *= 1.4;
        col += printClickAny(uv);
        
        uv = fragCoord / R;
        col += .002 / abs(rect(uv - vec2(.7, .5), vec2(.24, .1))) * tint;
    }
    
    col += .001 / abs(uv.x - iR); // Vertical Separator
         
    fragColor = vec4(col, 1);    
}