// Buf B (buffer) — Wordtoy by poljere
// https://www.shadertoy.com/view/Xst3zX

// Created by Pol Jeremias - 2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0

/////////////////////////////////////////////////////////////
// UI CODE 
//
// This pass reads the data stored by the first buffer
// and writes the characters that are required.
//
// SPECIAL THANKS to Flyguy for the font rendering
//     (https://www.shadertoy.com/view/XtsGRl)
/////////////////////////////////////////////////////////////


/////////////////////////////////
// Chars rendering
/////////////////////////////////
#define CHAR_SIZE vec2(3, 7)
#define CHAR_SPACING vec2(16, 24)

#define STRWIDTH(c) (c * CHAR_SPACING.x)
#define STRHEIGHT(c) (c * CHAR_SPACING.y)

/*
Top left pixel is the most significant bit.
Bottom right pixel is the least significant bit.

 â–ˆ     010    
â–ˆ â–ˆ    101    
â–ˆ â–ˆ    101    
â–ˆâ–ˆâ–ˆ -> 111 -> 010 101 101 111 101 101 101 -> 712557
â–ˆ â–ˆ    101    
â–ˆ â–ˆ    101    
â–ˆ â–ˆ    101    
*/

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

// Extracts bit b from the given number.
float extract_bit(float n, float b)
{
	return floor(mod(floor(n / pow(2.0,floor(b))),2.0));   
}

// Returns the pixel at uv in the given bit-packed sprite.
float sprite(float spr, vec2 size, vec2 uv)
{
    uv = floor(uv);
    //Calculate the bit to extract (x + y * width) (flipped on x-axis)
    float bit = (size.x-uv.x-1.0) + uv.y * size.x;
    
    //Clipping bound to remove garbage outside the sprite's boundaries.
    bool bounds = all(greaterThanEqual(uv,vec2(0)));
    bounds = bounds && all(lessThan(uv,size));
    
    return bounds ? extract_bit(spr, bit) : 0.0;
}

// Prints a character.
float char(float ch, vec2 uv, inout vec2 cursor)
{
    float c = sprite(ch, CHAR_SIZE, 0.5 * (uv - cursor));
    cursor += vec2(CHAR_SPACING.x, 0.0);
    return c;
}

vec3 ui(in vec2 fragCoord, inout vec2 cursor)
{
	// Draw UI
    return vec3(char(ch_w, fragCoord, cursor) + char(ch_o, fragCoord, cursor) +
           char(ch_r, fragCoord, cursor) + char(ch_d, fragCoord, cursor) +
           char(ch_t, fragCoord, cursor) + char(ch_o, fragCoord, cursor)+
           char(ch_y, fragCoord, cursor) + char(ch_sp, fragCoord, cursor)+
           char(ch_v, fragCoord, cursor) + char(ch_1, fragCoord, cursor));
}


/////////////////////////////////
// Memory Management
/////////////////////////////////
vec4 load(in vec2 fragCoordRead)
{
    return texture(iChannel0, (0.5 + fragCoordRead) / iChannelResolution[0].xy, -100.0 );
}


/////////////////////////////////
// Utils
/////////////////////////////////
float hash1( float n ) 
{ 
    return fract(sin(n)*138.5453123); 
}


/////////////////////////////////
// Draw letters!
/////////////////////////////////
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{   
    // Read the character from the image buffer
    vec2 bucket = floor(vec2(fragCoord.x / CHAR_SPACING.x,
                             ((iResolution.y - fragCoord.y) / CHAR_SPACING.y)));
    
    float numCharsRow = floor(iResolution.x / CHAR_SPACING.x);
    
    float texelIdBuffA = bucket.y * numCharsRow + bucket.x;
    
    vec2  fragCoordBuffA= vec2(  mod(texelIdBuffA, iChannelResolution[0].x),
    							 floor(texelIdBuffA / iChannelResolution[0].x));
    
    vec4 charId = load( fragCoordBuffA );
    
    
    // Draw the chars
    vec4 c = vec4(0.0); 
    vec2 cursor = floor(vec2(fragCoord.x / CHAR_SPACING.x, fragCoord.y / CHAR_SPACING.y)) * CHAR_SPACING;
    c += vec4(0.1, 1.0, 0.1, 0.0) * char(charId.x, fragCoord, cursor);
    
    
    // Draw the selection - Read the number of chars and calculate the last char
    float lastChar = 1.0 + load(vec2(0.0)).w;
    c.xyz += (1.0 - step(0.5, abs(lastChar - texelIdBuffA))) * vec3(0.1, 1.0, 0.1) *
             (0.5 + 0.5 *sin(iTime * 15.0));

    
    // Draw the UI
    cursor = 0.5 * vec2(iResolution.x - STRWIDTH(20.0), STRHEIGHT(1.0));
    c.xyz += vec3(0.2, 0.1, 0.1) * ui(floor(fragCoord/2.0), cursor);
    
    
    // Draw the background color
    c.xyz += vec3(0.15,0.15,0.15);
        
    //c += vec4(hash1(charId.x));
    
    fragColor = c;
}