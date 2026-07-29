// Buf D (buffer) — Multistep Fluid Simulation by trirop
// https://www.shadertoy.com/view/MdSczK

// Created by Robert Schuetze - trirop/2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Gradient subtraction

void mainImage( out vec4 fragColor, in vec2 C )
{
    vec2 r = iResolution.xy;   
    float pl = texture(iChannel0,(C-vec2(-1, 0))/r).x;
    float pr = texture(iChannel0,(C-vec2( 1, 0))/r).x;
    float pt = texture(iChannel0,(C-vec2( 0,-1))/r).x;
    float pb = texture(iChannel0,(C-vec2( 0, 1))/r).x;
    vec2 grad = vec2(pr-pl,pb-pt)/2.;
    vec4 bufOld = texture(iChannel1,C/r);
    fragColor = vec4(bufOld.xy-grad,bufOld.z,1);
}