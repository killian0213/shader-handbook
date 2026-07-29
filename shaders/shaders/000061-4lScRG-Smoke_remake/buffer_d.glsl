// Buf D (buffer) — Smoke remake by Ultraviolet
// https://www.shadertoy.com/view/4lScRG

// Created by Robert Schuetze - trirop/2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Gradient subtraction

// Note: This allows the velocity field to be divergence-free

void mainImage( out vec4 fragColor, in vec2 C )
{
    vec2 r = iResolution.xy;   
    //float pl = texture(iChannel0,(C-vec2(-1, 0))/r).x;
    //float pr = texture(iChannel0,(C-vec2( 1, 0))/r).x;
    //float pt = texture(iChannel0,(C-vec2( 0,-1))/r).x;
    //float pb = texture(iChannel0,(C-vec2( 0, 1))/r).x;
    
	float pl = texelFetch(iChannel0,clamp(ivec2(C)-ivec2(-1,0), ivec2(0), ivec2(iResolution.xy)-1),0).x;
	float pr = texelFetch(iChannel0,clamp(ivec2(C)-ivec2( 1,0), ivec2(0), ivec2(iResolution.xy)-1),0).x;
	float pt = texelFetch(iChannel0,clamp(ivec2(C)-ivec2(0,-1), ivec2(0), ivec2(iResolution.xy)-1),0).x;
	float pb = texelFetch(iChannel0,clamp(ivec2(C)-ivec2(0, 1), ivec2(0), ivec2(iResolution.xy)-1),0).x;
    
    
    vec2 grad = vec2(pr-pl,pb-pt)/2.;
    float pres = texture(iChannel0,C/r).x;
    
    vec4 bufOld = texture(iChannel1,C/r);
    float d = bufOld.z;
    vec2 v = bufOld.xy;
    
    vec2 g = vec2(0.0, d)*0.01;
    
    v = v-grad-g;
    
    
    if(C.x<1.||C.x>r.x-1.){
    	v.x = .0;
    }
    if(r.y-1.<C.y||C.y<1.){
    	v.y = .0;
    }
    
    fragColor = vec4(v, d, 1.);
}