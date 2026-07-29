// Buffer A (buffer) — Font: Bitmap vs SDF by MichaelPohoreski
// https://www.shadertoy.com/view/llK3Wm

// Bitmap A - Nearest Neighbor

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;

/* Apple ][ 5x7 but shifted 1 px right since texture clamping

    "A"
     84210000
     00008421
    +--------+
    |...1....| 20 -> 10
    |..1.1...| 50 -> 28
    |.1...1..| 88 -> 44
    |.1...1..| 88 -> 44
    |.11111..| F8 -> 7C
    |.1...1..| 88 -> 44
    |.1...1..| 88 -> 44
    |........| 00 -> 00
    +--------+
*/   
    float p; 
    int   x, y;
    int   u, v;
    
    u = int( fragCoord.x );
    v = int( fragCoord.y );

    #define _ 1.0
    
    float c = 0.0; // Black or no background

    if (v == 0)
    {
        if (u == 3)
            c = _;
    }
    else
    if (v == 1)
    {
        if (u == 2 || u == 4)
            c = _;
    }
    else
    if (v == 2 || v == 3)
    {
        if (u == 1 || u == 5)
            c = _;
    }
    else
    if (v == 4)
    {
        if (u >= 1 && u <= 5)
            c = _;
    }
    else
    if (v >= 5 && v <= 6)
    {
        if (u == 1 || u == 5)
            c = _;
    }
        
    fragColor = vec4( c );
 }
