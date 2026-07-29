// Image (image) — Smoke on the Water by piyushslayer
// https://www.shadertoy.com/view/Wd33Wn

/**

 A simple fluid simulation implementation based on the chapter
 "Simple and Fast Fluids" in GPU Pro 2 book. The main solver resides
 in the common tab. Buffers A, B & C blit each other to enhance the simulation.
 Finally, Buffer D draws colors onto the velocity field and this tab
 performs some interesting post effects like pixelization and color inversion.

 Drag around the cursor to see the magic happen. Works surprisingly well in
 fullscreen mode as well.

*/

// Uncomment this for a pixelated effect and play around with the
// two parameters to change the look.
// #define PIXELATED
#define PIXEL_SIZE 9.
#define BORDER_THICKNESS .51

// Uncomment this to invert the colors
// #define INVERT_COLORS

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;
#ifdef PIXELATED
    vec2 dxy = PIXEL_SIZE / iResolution.xy;
    uv = dxy * floor(uv / dxy) + 1. / iResolution.xy;
    vec4 col = textureLod(iChannel0, uv, 0.);
    vec2 fr = PIXEL_SIZE * (fract(fragCoord/PIXEL_SIZE) - .5);
    col *= step(max(fr.x, fr.y) + BORDER_THICKNESS - PIXEL_SIZE / 2., 0.);    
#else
	vec4 col = textureLod(iChannel0, uv, 0.);
#endif
    
    // Bottom row contain previous mouse data so don't display that.
   	if (fragCoord.y < 1. 
#ifdef PIXELATED 
            * PIXEL_SIZE 
#endif
       )
    {
        col = vec4(0.);
    }    
    
#ifndef INVERT_COLORS
    fragColor = vec4(sqrt(col.xyz), 1.);
#else
    fragColor = vec4(sqrt(1. - col.xyz), 1.);
#endif
}