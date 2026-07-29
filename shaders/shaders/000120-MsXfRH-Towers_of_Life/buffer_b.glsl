// Buffer B (buffer) — Towers of Life by Polygon
// https://www.shadertoy.com/view/MsXfRH

//This buffer keeps track of how fast the game runs, and handles restarting.


//Ticks per second. If it is higher than your framerate, it will just run at your framerate.
//The game will slowly accelerate until it meets that speed for effect.
#define speed 20.

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float next = texelFetch(iChannel0, ivec2(0),0).x;
    float startTime = texelFetch(iChannel0, ivec2(0),0).w;
    
    if (iFrame == 0 || texelFetch(iChannel1, ivec2(13, 1), 0).x == 1.0) {
        next = 1.;
        startTime = (iFrame == 0) ? 0.0 : iTime;
    }
    
    if (iTime - startTime >= next) {
        fragColor.y = 1.0;
        next += 1.0 / min(float(speed), iTime - startTime);
    }
    fragColor.x = next;
    fragColor.z = min(float(speed), iTime - startTime);
    fragColor.w = startTime;
}