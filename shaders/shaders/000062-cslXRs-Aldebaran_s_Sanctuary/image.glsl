// Image (image) — Aldebaran's Sanctuary by kishimisu
// https://www.shadertoy.com/view/cslXRs

/* "Aldebaran's Sanctuary" by @kishimisu (2022) - https://www.shadertoy.com/view/cslXRs

   Switch to day/night mode with the mouse !
   
   This is the completion of my recent quest for fast fbm terrain generation. 
   Using various techniques that I listed in my shader demonstration
   (https://www.shadertoy.com/view/msXSR2), I was able to get much better 
   performances that my previous realistic scene "Lost Monoliths" 
   (https://www.shadertoy.com/view/mdfSWr).
   
   However after finishing this scene I realized that I've made it more complex 
   than my previous one, so even if the terrain is calculated much faster it is
   a bit demanding on the performances. (Even if it still runs 3x faster than
   my previous one).
   
   I also tried to make reflective water, and it's one of these things that is really 
   beautiful for very few lines of code. Simply invert the ray y direction when it is 
   below a specific level, and add a bit of noise to its direction to simulate water 
   ripples. Terribly easy !
   To make the water stand out nicely, the terrain close to the water gets darker to 
   simulate being wet. Also the color gets tinted with dark blue if the ray has been 
   reflected by the water.
   
   The space is repeated around the y axis, so there is only one pillar and one distant 
   monolith that are being checked at each step, and the trees are simple cones with 
   various offset, height, and colors. Finally, the terrain is made with 3 rings of
   mountains that are more and more distance and high (see terrainH)
*/

void mainImage(out vec4 O, vec2 F) {    
    vec3 col = texelFetch(iChannel0, ivec2(F-0.5), 0).rgb;
    col *= pow(smoothstep(1., 0., length(F/iResolution.xy-.5)), .4);
    O = vec4(col, 1.);
}