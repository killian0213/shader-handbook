// Buf A (buffer) — Wordtoy by poljere
// https://www.shadertoy.com/view/Xst3zX

// Created by Pol Jeremias - 2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0

/////////////////////////////////////////////////////////////
// INPUT AND MEMORY CODE 
//
// This pass reads the keyboard and stores every key in a 
// texture that later on is use to recreate the text
/////////////////////////////////////////////////////////////

// Keyboard constants definition
const float KEY_BSP   = 8.5/256.0;
const float KEY_SP    = 32.5/256.0;
const float KEY_LEFT  = 37.5/256.0;
const float KEY_UP    = 38.5/256.0;
const float KEY_RIGHT = 39.5/256.0;
const float KEY_DOWN  = 40.5/256.0;
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
const float KEY_COMMA = 188.5/256.0;
const float KEY_PER   = 190.5/256.0;

//Automatically generated from a sprite sheet.
float ch_sp = 0.0;
float ch_a = 712557.0;
float ch_b = 1760622.0;
float ch_c = 706858.0;
float ch_d = 1760110.0;
float ch_e = 2018607.0;
float ch_f = 2018596.0;
float ch_g = 706922.0;
float ch_h = 1498989.0;
float ch_i = 1909911.0;
float ch_j = 1872746.0;
float ch_k = 1498477.0;
float ch_l = 1198375.0;
float ch_m = 1571693.0;
float ch_n = 1760109.0;
float ch_o = 711530.0;
float ch_p = 711972.0;
float ch_q = 711675.0;
float ch_r = 1760621.0;
float ch_s = 2018927.0;
float ch_t = 1909906.0;
float ch_u = 1497963.0;
float ch_v = 1497938.0;
float ch_w = 1498109.0;
float ch_x = 1496429.0;
float ch_y = 1496210.0;
float ch_z = 2004271.0;
float ch_1 = 730263.0;
float ch_2 = 693543.0;
float ch_3 = 693354.0;
float ch_4 = 1496649.0;
float ch_5 = 1985614.0;
float ch_6 = 707946.0;
float ch_7 = 1873042.0;
float ch_8 = 709994.0;
float ch_9 = 710250.0;
float ch_0 = 711530.0;
float ch_per = 2.0;
float ch_que = 693378.0;
float ch_exc = 599170.0;
float ch_com = 10.0;
float ch_scl = 65556.0;
float ch_col = 65552.0;
float ch_usc = 7.0;
float ch_crs = 11904.0;
float ch_dsh = 3584.0;
float ch_ast = 21824.0;
float ch_fsl = 304292.0;
float ch_bsl = 1189001.0;
float ch_lpr = 346385.0;
float ch_rpr = 1118804.0;
float ch_lba = 862355.0;
float ch_rpa = 1647254.0;


/////////////////////////////////
// Memory Locations
/////////////////////////////////
vec2 fragCoordNumChars = vec2(0.0, 0.0);


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
// Store information
/////////////////////////////////
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Read the last mode selected
    int numChars = int( load(fragCoordNumChars).w );
    vec4  history= load( fragCoord.xy-0.5 );
    float char   = history.x + history.a;
    
    // Initialize variables
    if (iFrame == 0)
    {
        history = vec4(0.0);
        numChars = 0;
        char = 0.0;
    }
    
    // Check if the user has changed selection (Thanks Inigo)
    float ochar = char;
    char = mix( char, ch_q, step(0.5,isKeyPressed(KEY_Q)) );
    char = mix( char, ch_w, step(0.5,isKeyPressed(KEY_W)) );
    char = mix( char, ch_e, step(0.5,isKeyPressed(KEY_E)) );
    char = mix( char, ch_r, step(0.5,isKeyPressed(KEY_R)) );
    char = mix( char, ch_t, step(0.5,isKeyPressed(KEY_T)) );
    char = mix( char, ch_y, step(0.5,isKeyPressed(KEY_Y)) );
    char = mix( char, ch_u, step(0.5,isKeyPressed(KEY_U)) );
    char = mix( char, ch_i, step(0.5,isKeyPressed(KEY_I)) );
    char = mix( char, ch_o, step(0.5,isKeyPressed(KEY_O)) );
    char = mix( char, ch_p, step(0.5,isKeyPressed(KEY_P)) );

    char = mix( char, ch_a, step(0.5,isKeyPressed(KEY_A)) );
    char = mix( char, ch_s, step(0.5,isKeyPressed(KEY_S)) );
    char = mix( char, ch_d, step(0.5,isKeyPressed(KEY_D)) );
    char = mix( char, ch_f, step(0.5,isKeyPressed(KEY_F)) );
    char = mix( char, ch_g, step(0.5,isKeyPressed(KEY_G)) );
    char = mix( char, ch_h, step(0.5,isKeyPressed(KEY_H)) );
    char = mix( char, ch_j, step(0.5,isKeyPressed(KEY_J)) );
    char = mix( char, ch_k, step(0.5,isKeyPressed(KEY_K)) );
    char = mix( char, ch_l, step(0.5,isKeyPressed(KEY_L)) );

    char = mix( char, ch_z, step(0.5,isKeyPressed(KEY_Z)) );
    char = mix( char, ch_x, step(0.5,isKeyPressed(KEY_X)) );
    char = mix( char, ch_c, step(0.5,isKeyPressed(KEY_C)) );
    char = mix( char, ch_v, step(0.5,isKeyPressed(KEY_V)) );
    char = mix( char, ch_b, step(0.5,isKeyPressed(KEY_B)) );
    char = mix( char, ch_n, step(0.5,isKeyPressed(KEY_N)) );
    char = mix( char, ch_m, step(0.5,isKeyPressed(KEY_M)) );
	char = mix( char, ch_com, step(0.5,isKeyPressed(KEY_COMMA)) );
    char = mix( char, ch_per, step(0.5,isKeyPressed(KEY_PER)) );
    
    char = mix( char, ch_sp, step(0.5,isKeyPressed(KEY_SP)) );
    if( abs(ochar-char)>0.01 ) numChars++;
    
    // Store new data
    float numCharsf = float(numChars);
    vec2 fragCoordChar = vec2(  mod(numCharsf, iChannelResolution[0].x), 
                              floor(numCharsf / iChannelResolution[0].x));
    
    if(isKeyPressed(KEY_BSP)> 0.0){ char = 0.0; numCharsf = numCharsf - 1.0; } 
    
    fragColor = history;          
    store( fragCoordNumChars, vec4(0.0,0.0,0.0,numCharsf), fragColor, fragCoord );
    store( fragCoordChar,     vec4(char,0.0,0.0,0.0),      fragColor, fragCoord );
}
