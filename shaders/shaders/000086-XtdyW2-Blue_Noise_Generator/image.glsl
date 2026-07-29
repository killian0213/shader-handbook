// Image (image) — Blue Noise Generator by paniq
// https://www.shadertoy.com/view/XtdyW2

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;
    ivec2 sz = ivec2(iResolution.xy);
    ivec2 px = ivec2(fragCoord);
   	float v_ref = texelFetch(iChannel1, ivec2(fragCoord)/1 % ivec2(iChannelResolution[1].xy), 0).r;
#if 0
    float v = texelFetch(iChannel0, px, 0).r;    
    float v_old = texelFetch(iChannel2, px, 0).r;
    if (uv.x > 0.5) {
        fragColor = vec4(v_ref,v_ref,v_ref,1.0);
    } else if (v != v_old) {
        fragColor = vec4(1.0,0.0,0.0,1.0);
    } else {
		fragColor = vec4(v,v,v,1.0);
    }
#else
    float v = texelFetch(iChannel0, px, 0).r;    
#if 0
    vec2 s0_x0 = quantify_error(iChannel0, px, sz, v, v);
    if (uv.x > 0.5) {
    v = s0_x0.x * 1.0;
    }
#endif

#if 0
    if (uv.x > 0.5) {
        v = v_ref; 
    }
    v = step(v, uv.y);
#endif
    //v = step(0.999/255.0, v);
    //v = step(v, 0.0);
    fragColor = vec4(v, v, v, 1.0);
#endif
}