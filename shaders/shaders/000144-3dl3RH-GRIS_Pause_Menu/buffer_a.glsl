// Buffer A (buffer) — GRIS Pause Menu by glk7
// https://www.shadertoy.com/view/3dl3RH

// Created by genis sole 2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International.

const int KEY_LEFT  = 37;
const int KEY_UP  = 38;
const int KEY_RIGHT = 39;

float key_press(int k) 
{
   return step(0.5, texelFetch(iChannel1, ivec2(k, 1), 0).x); 
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    if (any(notEqual(ivec2(fragCoord), ivec2(0)))) return;
    
    fragColor = texelFetch(iChannel0, ivec2(0), 0);
    
    if (iFrame == 0) fragColor = vec4(-1.0);
    
    fragColor.x += (fragColor.y - fragColor.x) * iTimeDelta*10.0;
    fragColor.y += 2.0*(key_press(KEY_RIGHT) - key_press(KEY_LEFT)) 
        - key_press(KEY_UP)*fragColor.y;
    fragColor = clamp(fragColor, -1.0, 1.0);
}