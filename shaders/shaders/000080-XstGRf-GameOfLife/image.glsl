// Image (image) — GameOfLife by iq
// https://www.shadertoy.com/view/XstGRf

// I implemented three variants of Conway's Game of Life with
// three different interpretations: the regular one, as low
// pass filter and as a high pass filter. Tweak line 11 in
// Bufer A to see them all. More info here:
// https://iquilezles.org/articles/gameoflife/


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = vec4( texelFetch( iChannel0, ivec2(fragCoord), 0 ).xxx, 1.0 );
}