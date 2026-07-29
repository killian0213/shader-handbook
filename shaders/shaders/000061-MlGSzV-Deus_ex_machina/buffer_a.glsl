// Buffer A (buffer) — Deus ex machina by nimitz
// https://www.shadertoy.com/view/MlGSzV

// Deus ex machina by nimitz (twitter: @stormoid)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Contact the author for other licensing options

#define time iTime

#define DROP_VAL 4.05
#define SUB_OFFSET 0.0238321
#define CLAMP_MAX 8.1

//Main rule
float spread(in ivec2 p, float h)
{
    //vec2 w = 1./iResolution.xy;
    
    vec4 texN = texelFetch(iChannel0, p + ivec2(0,1), 0);
    vec4 texS = texelFetch(iChannel0, p + ivec2(0,-1), 0);
    vec4 texE = texelFetch(iChannel0, p + ivec2(1, 0), 0);
    vec4 texW = texelFetch(iChannel0, p + ivec2(-1, 0), 0);
    
    vec4 texNE = texelFetch(iChannel0, p + ivec2(1,1), 0);
    vec4 texNW = texelFetch(iChannel0, p + ivec2(-1,1), 0);
    vec4 texSE = texelFetch(iChannel0, p + ivec2(1,-1), 0);
    vec4 texSW = texelFetch(iChannel0, p + ivec2(-1,-1), 0);
    
    texE *= step(gl_FragCoord.x+1., iResolution.x);
    texW *= step(0., gl_FragCoord.x-1.);
    texN *= step(0., gl_FragCoord.y-1.);
    texS *= step(gl_FragCoord.y+1., iResolution.y);
 
#if 1
    //still works without all boundaries
    texNE *= step(gl_FragCoord.x+1., iResolution.x)*step(0., gl_FragCoord.y-1.);
    texSE *= step(gl_FragCoord.x+1., iResolution.x)*step(gl_FragCoord.y+1., iResolution.y);
    texSW *= step(0., gl_FragCoord.x-1.)*step(gl_FragCoord.y+1., iResolution.y);
    texNW *= step(0., gl_FragCoord.x-1.)*step(0., gl_FragCoord.y-1.);
#endif
    
    if (h > DROP_VAL) h -= 8.0 - SUB_OFFSET;
    
    if (texN.x > DROP_VAL) h += 1.0;
    if (texS.x > DROP_VAL) h += 1.0;
    if (texE.x > DROP_VAL) h += 1.0;
    if (texW.x > DROP_VAL) h += 1.0;
    if (texNE.x > DROP_VAL) h += 1.0;
    if (texNW.x > DROP_VAL) h += 1.0;
    if (texSE.x > DROP_VAL) h += 1.0;
    if (texSW.x > DROP_VAL) h += 1.0;
    
    h = clamp(h, 0.0, CLAMP_MAX);
    
    return h;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 q = fragCoord.xy / iResolution.xy;
    
    //vec4 tex = texture(iChannel0, q);
    vec4 tex = texelFetch(iChannel0, ivec2(fragCoord.xy), 0);
    float height = spread(ivec2(fragCoord.xy), tex.x);

    if (iFrame < 10)
  		height = DROP_VAL + 0.1;
    
    float v = 4.0*step(sin(time*0.07),0.);
    
    #if 1
    vec3 col = sin(vec3(.85,2.,3.)-vec3(-v*.98,v*.5,v*.8)*1.32 - v*1. + height + fract(height*7.0)*0.3)*0.4+0.4;
    #else
    vec3 col = sin(vec3(1.7,1.4,.8)*1.1-vec3(-v*.8,v*.56,-v*3.)*1.32 - v*0.18 + height + fract(height*7.0)*0.3)*0.45+0.4;
    #endif
    
    col = mix(col, tex.yzw, 0.5);
    
    fragColor = vec4(height, col);
}