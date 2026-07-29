// Buf A (buffer) — Photoshop Blends Branchless  by poljere
// https://www.shadertoy.com/view/Md3GzX

// Created by Pol Jeremias - 2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0


/////////////////////////////////////////////////////////////
// KEYBOARD PASS
// This pass will read from the keyboard which of the passes
// is the current active one and store that information 
// in the buffer
/////////////////////////////////////////////////////////////


// Keyboard constants definition
const float KEY_A     = 65.5/256.0;
const float KEY_B     = 66.5/256.0;
const float KEY_C     = 67.5/256.0;
const float KEY_D     = 68.5/256.0;
const float KEY_E     = 69.5/256.0;
const float KEY_F     = 70.5/256.0;
const float KEY_G     = 71.5/256.0;
const float KEY_H     = 72.5/256.0;
const float KEY_I     = 73.5/256.0;
const float KEY_J     = 74.5/256.0;
const float KEY_K     = 75.5/256.0;
const float KEY_L     = 76.5/256.0;
const float KEY_M     = 77.5/256.0;
const float KEY_N     = 78.5/256.0;
const float KEY_O     = 79.5/256.0;
const float KEY_P     = 80.5/256.0;
const float KEY_Q     = 81.5/256.0;
const float KEY_R     = 82.5/256.0;
const float KEY_S     = 83.5/256.0;
const float KEY_T     = 84.5/256.0;
const float KEY_U     = 85.5/256.0;
const float KEY_V     = 86.5/256.0;
const float KEY_W     = 87.5/256.0;
const float KEY_X     = 88.5/256.0;
const float KEY_Y     = 89.5/256.0;
const float KEY_Z     = 90.5/256.0;

// Memory locations
vec2 memLocMode = vec2(0.0, 0.0);


/////////////////////////////////
// Memory Management
/////////////////////////////////

vec4 load(in vec2 fragCoordRead)
{
    return texture(iChannel0, (0.5 + fragCoordRead) / iChannelResolution[0].xy, -100.0 );
}

float isInside( vec2 p, vec2 c ) 
{ 
    vec2 d = abs(p-0.5-c) - 0.5; return -max(d.x,d.y); 
}

void store( in vec2 fragCoordWrite, in vec4 value, inout vec4 fragColor, in vec2 fragCoord )
{
    fragColor = (isInside(fragCoord, fragCoordWrite) > 0.0) ? value : fragColor;
}

float isKeyPressed(float key)
{
	return texture( iChannel1, vec2(key, 0.5) ).x;
}


/////////////////////////////////
// Keyboard reads and stores
/////////////////////////////////

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Read the last mode selected
    float mode = load(memLocMode).x;
    
    // Initialize variables
    if (iFrame == 0)
    {
        mode = 0.0;
    }
    
    // Check if the user has changed selection
    if(isKeyPressed(KEY_Q) > 0.0) mode = 0.0;
    if(isKeyPressed(KEY_W) > 0.0) mode = 1.0;
	if(isKeyPressed(KEY_E) > 0.0) mode = 2.0;
	if(isKeyPressed(KEY_R) > 0.0) mode = 3.0;
    if(isKeyPressed(KEY_T) > 0.0) mode = 4.0;
    if(isKeyPressed(KEY_Y) > 0.0) mode = 5.0;
    if(isKeyPressed(KEY_U) > 0.0) mode = 6.0;
    if(isKeyPressed(KEY_I) > 0.0) mode = 7.0;
    if(isKeyPressed(KEY_O) > 0.0) mode = 8.0;
    if(isKeyPressed(KEY_P) > 0.0) mode = 9.0;
    if(isKeyPressed(KEY_A) > 0.0) mode = 10.0;
    if(isKeyPressed(KEY_S) > 0.0) mode = 11.0;
    if(isKeyPressed(KEY_D) > 0.0) mode = 12.0;
    if(isKeyPressed(KEY_F) > 0.0) mode = 13.0;
    if(isKeyPressed(KEY_G) > 0.0) mode = 14.0;
    if(isKeyPressed(KEY_H) > 0.0) mode = 15.0;
    if(isKeyPressed(KEY_J) > 0.0) mode = 16.0;
    if(isKeyPressed(KEY_K) > 0.0) mode = 17.0;
    if(isKeyPressed(KEY_L) > 0.0) mode = 18.0;
    if(isKeyPressed(KEY_Z) > 0.0) mode = 19.0;
    if(isKeyPressed(KEY_X) > 0.0) mode = 20.0;
    if(isKeyPressed(KEY_C) > 0.0) mode = 21.0;
    if(isKeyPressed(KEY_V) > 0.0) mode = 22.0;
    if(isKeyPressed(KEY_B) > 0.0) mode = 23.0;
    if(isKeyPressed(KEY_N) > 0.0) mode = 24.0;
    if(isKeyPressed(KEY_M) > 0.0) mode = 25.0;
    
    // Store key press in the texture
	store(memLocMode, vec4(mode), fragColor, fragCoord);
}