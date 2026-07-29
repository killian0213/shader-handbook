// Image (image) — Fractal Computer by byt3_m3chanic
// https://www.shadertoy.com/view/sstXR8

/** 
    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    09/28/21 @byt3_m3chanic 
    Fractal Computer

    Buffer A / Fragment Shader
    Buffer B / Title and Text Overlay

*/

#define R iResolution

void mainImage( out vec4 O, in vec2 F )
{  
	vec2 uv = F.xy/R.xy;
    
    vec3 A = texture(iChannel0, uv).rgb;
    vec4 B = texture(iChannel1, uv);
    vec3 C = mix(A,vec3(B.rgb),B.w);
    
    // output
    C=pow(C, vec3(.4545));
    O = vec4(C,1.);
}