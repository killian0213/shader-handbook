// Buf C (buffer) — Photoshop Blends Branchless  by poljere
// https://www.shadertoy.com/view/Md3GzX

// Created by Pol Jeremias - 2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0


/////////////////////////////////////////////////////////////
// DST PASS
// This pass will output the frame to be blended as DST
/////////////////////////////////////////////////////////////


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
	fragColor = vec4(texture(iChannel0, uv).xyz, 1.0);
}