// Image (image) — Apple I Emulator by Flyguy
// https://www.shadertoy.com/view/tlX3W7

/*
See Common tab for emulator settings, visual settings can be found below.

--------------------------------

Debugging values on the right:
Program Counter, Opcode, Average Speed (% of max), Average Speed (instuctions/sec)

Accumulator, X Index, Y Index, Stack Pointer

Flags (NV1BDIZC)

--------------------------------

Buffers:
A - "Microcode" lookup table
B - RAM/IO
C - 6502 Emulator

--------------------------------

Some details on using Wozmon:
https://www.sbprojects.net/projects/apple1/wozmon.php

Some basic commands in Wozmon (# = hex digit)
#### <enter> -> Examine specifed address. (ex. FF00)
####.#### <enter> -> Examine address range. (ex. FF00.FFFF)
####:## ## ... <enter> -> Deposit values at specified address. (ex. 0010:00 01 02 ..)
####R <enter> -> Start execution at specified address (ex. E000R)

--------------------------------

Apple I Integer BASIC Manual:
https://archive.org/stream/apple1_basic_manual/apple1_basic_manual_djvu.txt

"Hello World" example:
10 PRINT"HELLO, WORLD!"
20 GOTO 10
RUN

--------------------------------

FAQ:
Why doesn't backspace work?
> Backspace is supported by Wozmon/Basic, they print "_"s to indicate deleted characters.
  The Apple 1's terminal hardware didn't support deleting characters, the emulator reflects this behavior.

The text on screen doesn't match what I'm typing.
> The keyboard texture only provides the keycode, which doesn't have a direct relation to the character typed.
  There's a mapping table for US QWERTY and AZERTY, each different layout would need it's own mapping table.

How fast is it?
> By default, it's set to 600 instructions per frame, at 60fps this is roughly equivalent to a 6502 at 0.072MHz.
  If your GPU can handle it, increasing CYCLES to 8333 would be roughly equivalent to a 6502 at 1MHz.
  CACHE_SIZE will need to be increased as well otherwise it will bottleneck the CPU, reducing speed as a result.
  
> The emulated terminal is set to handle 40 chars/frame, whereas the Apple 1's terminal could only handle 1 char/frame.
  This can be adjusted by changing DSPBUF_SIZE.
*/

//Display settings
#define CHAR_SIZE vec2(2.0/3.0,1.0)     //Terminal character size
#define TERM_TCOL vec4(0.0,1.0,0.5,0.0) //Terminal text color
#define TERM_BCOL (TERM_TCOL*0.1)       //Terminal background color
#define TERM_SCANVIS 0.75               //Scanline visibility (0 = off)
#define TEXT_SCALE vec2(0.03,0.05)      //Text size for debug prints

vec2 gUV = vec2(0);
vec4 gFrag = vec4(0);

//Print a hexadecimal value 'v' at point 'p' with 'n' digits
void PrintHex(vec2 p, float v, float n)
{
    vec2 uv = gUV;
    uv -= p;
    v = abs(floor(v));
    vec2 t = floor(uv / TEXT_SCALE);
    float ox = (1.0 - (TEXT_SCALE.x/TEXT_SCALE.y))/2.;
    uv = mod(uv, TEXT_SCALE) / TEXT_SCALE.y;
    uv.x += ox;
    if(t.y == 0.0 && t.x >= 0.0 && t.x < n)
    {
        float d = mod(floor(v / pow(16.0, n - 1.0 - t.x)), 16.0);
        vec2 choff = (d < 10.0) ? vec2(d, 12.0) : vec2(d - 9.0, 11.0);
        gFrag += texture(iChannel2, ((uv + choff)/16.0), -100.0).r;
    }
}

//Print a decimal value 'v' at point 'p'
void PrintDec(vec2 p, float v)
{
    vec2 uv = gUV;
    uv -= p;
    v = abs(floor(v));
    vec2 t = floor(uv / TEXT_SCALE);
    float ox = (1.0 - (TEXT_SCALE.x/TEXT_SCALE.y))/2.;
    uv = mod(uv, TEXT_SCALE) / TEXT_SCALE.y;
    uv.x += ox;
    float dl = max(1.0,1.0+floor(0.001+log(v)/log(10.0)));
    if(t.y == 0.0 && t.x >= 0.0 && t.x < dl)
    {
        float d = mod(floor(v / pow(10.0, dl - t.x - 1.0)), 10.0);
        
        gFrag += texture(iChannel2, ((uv + vec2(d,12))/16.0), -100.0).r;
    }
}

//Print a binary value 'v' at point 'p' with 'n' digits
void PrintBin(vec2 p, float v, float n)
{
    vec2 uv = gUV;
    uv -= p;
    v = abs(floor(v));
    vec2 t = floor(uv / TEXT_SCALE);
    float ox = (1.0 - (TEXT_SCALE.x/TEXT_SCALE.y))/2.;
    uv = mod(uv, TEXT_SCALE) / TEXT_SCALE.y;
    uv.x += ox;
    if(t.y == 0.0 && t.x >= 0.0 && t.x < n)
    {
        float d = mod(floor(v / exp2(n - t.x - 1.0)), 2.0);
        gFrag += texture(iChannel2, ((uv + vec2(d,12))/16.0), -100.0).r;
    }
}

//Convert ASCII code to UV coords in the font texture.
vec2 AsciiToUv(int ascii)
{
    if(ascii < 0x20){ascii = 0x20;} //Don't print control chars
    return vec2(fract(float(ascii)/16.0), (15.0-floor(float(ascii)/16.0))/16.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    gUV = fragCoord.xy / iResolution.y;
    
    vec2 cursor = texelFetch(iChannel0, CURSOR_BASE,0).zw;
    vec2 charUv = fragCoord/iResolution.xy * vec2(TERM_SIZE) / CHAR_SIZE;
    vec2 charPos = floor(charUv);
    charPos.y = float(TERM_SIZE.y) - charPos.y - 1.0;
    
    //Scale & Center the character UVs.
    charUv = CHAR_SIZE*fract(charUv)/16.0 + (1.0-CHAR_SIZE)/2.0/16.0;
	
    //Calculate scroll offset and read the charater to print.
    float scroll = max(0.0, cursor.y - float(TERM_SIZE.y)+1.0);
    charPos.y = mod(charPos.y + scroll, float(TERM_SIZE.y));
    int char = int(texelFetch(iChannel0, ivec2(charPos),0).y);

    //Blink cursor
    if(charPos == mod(cursor,vec2(TERM_SIZE)) )
    {
        char = (fract(iTime)<0.5) ? 0x40 : 0x20; //0x40 = @, 0x20 = Space
    }
    
    //Draw terminal
    gFrag = mix(TERM_BCOL, TERM_TCOL,
                textureLod(iChannel2, charUv + AsciiToUv(char), 1.).x); //Draw chars
    gFrag *= TERM_SCANVIS * mod(fragCoord.y,2.0) + (1.0-TERM_SCANVIS); //Scan lines
	gFrag *= float(IN_RECT(charPos, vec2(0), vec2(TERM_SIZE))); //Clip edges of terminal.
    
    //Draw debug values
    //Top row
    vec4 debug = READ_VAR4(0, iChannel1);
    PrintHex(vec2(1.20,0.95), debug.x, 4.0); //Current PC
    PrintHex(vec2(1.35,0.95), debug.y, 2.0); //Current opcode
    PrintDec(vec2(1.45,0.95), debug.z); //Percent of max speed
    PrintDec(vec2(1.55,0.95), debug.w); //Cycles per second
    
    //Middle row
    debug = READ_VAR4(1, iChannel1);
    PrintHex(vec2(1.20,0.85), debug.x, 2.0); //A
    PrintHex(vec2(1.30,0.85), debug.y, 2.0); //X
    PrintHex(vec2(1.40,0.85), debug.z, 2.0); //Y
    PrintHex(vec2(1.50,0.85), debug.w, 2.0); //SP
    
    //Bottom row
    debug = READ_VAR4(2, iChannel1);
    PrintBin(vec2(1.20,0.75), debug.x, 8.0); //PSW/Flags (NV1BDIZC)
    
    fragColor = gFrag;
}