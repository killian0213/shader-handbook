// Buf C (buffer) — pinball game by public_int_i
// https://www.shadertoy.com/view/MdyGDz

//Ethan Shulman/public_int_i 2015
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

//Buf C - Motion blur

//#define enabled

const float blur = .3;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    vec3 c = texture(iChannel0, uv).xyz*(1.+9.*(1.-blur));
    #ifndef enabled
    fragColor = texture(iChannel0,uv);
    return;
    #endif
    vec2 oneDivRes = 1./iResolution.xy;
    for (int i = 0; i < 4; i++) {
        #define fi float(i)
        #define ff float(iFrame)
        c += texture(iChannel1, uv+vec2(sin(fi*1.942+ff*.749+ff*.09823+.9234),
                                          cos(fi*1.893+ff*.617+ff*.07954))*oneDivRes).xyz;
    }
    fragColor = vec4(c/(5.+9.*(1.-blur)), 1.);
}