// Buf B (buffer) — Smoke remake by Ultraviolet
// https://www.shadertoy.com/view/4lScRG

// Created by Robert Schuetze - trirop/2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Compute divergence

// Note : Divergence is the right hand side of the Poisson equation:
//   ∇²P = ∇.U*

void mainImage( out vec4 fragColor, in vec2 C )
{
    vec2 r = iResolution.xy;
    //float vxl = texture(iChannel0,(C-vec2(-1, 0))/r).x;
    //float vxr = texture(iChannel0,(C-vec2( 1, 0))/r).x;
    //float vyt = texture(iChannel0,(C-vec2( 0,-1))/r).y;
    //float vyb = texture(iChannel0,(C-vec2( 0, 1))/r).y;
	float vxl = texelFetch(iChannel0,clamp(ivec2(C)-ivec2(-1,0), ivec2(0), ivec2(iResolution.xy)-1),0).x;
	float vxr = texelFetch(iChannel0,clamp(ivec2(C)-ivec2( 1,0), ivec2(0), ivec2(iResolution.xy)-1),0).x;
	float vyt = texelFetch(iChannel0,clamp(ivec2(C)-ivec2(0,-1), ivec2(0), ivec2(iResolution.xy)-1),0).y;
	float vyb = texelFetch(iChannel0,clamp(ivec2(C)-ivec2(0, 1), ivec2(0), ivec2(iResolution.xy)-1),0).y;
    float div = (vxl-vxr+vyt-vyb)/2.;
    fragColor = vec4(div,0,0,1);
}