// Image (image) — [ConcoursJFIG2021] Alpine Flyby by loicvdb
// https://www.shadertoy.com/view/flc3Rn

void mainImage(out vec4 o, in vec2 u){
    
    // == motion blur ============================================
    mat3 cam = getMat3(0);
    vec3 rd = cam * normalize(vec3((u-iResolution.xy*.5)/iResolution.y, FocalLength));
    vec3 ro = getVec3(3);
    float depth = texture(iChannel1, u/iResolution.xy).a;
    
    mat3 pCam = getMat3(5);
    vec3 pRo = getVec3(8);
    vec3 pxyz = transpose(pCam) * (ro+depth*rd-pRo);
    vec2 puv = FocalLength * pxyz.xy * iResolution.y / pxyz.z + iResolution.xy*.5;
    
    vec3 x = vec3(0);
    const int samples = 16;
    vec2 d = (puv-u) / float(samples);
    for(int i = 0; i < samples; i++) {
        ivec2 iu = clamp(ivec2(u+float(i-samples/2)*d), ivec2(0), ivec2(iResolution.xy)-1);
        x += texelFetch(iChannel1, iu, 0).rgb;
    }
    
    x /= float(samples);
    
    
    // == fast bloom ============================================
    float r = floor(log2(iResolution.y) - 4.5) + .5;
    for(int i = 0; i < 2; i++)
        x += texture(iChannel1, u/iResolution.xy, r+float(i*2)).rgb*.1;
    
    
    // == transitions ===========================================
    #ifndef FLY_MODE
    float f = iTime*.1;
    x *= smoothstep(-.2, .2, .5-abs(.5-fract(f)))*2.-1.;
    #endif
    
    
    // == exposure =============================================
    x *= 2.;
    
    
    // == vignette =============================================
    vec2 cuv = u/iResolution.xy-.5;
    x *= 1. - dot(cuv, cuv)*1.4;
    
        
    // == ACES fit =============================================
    x = (x*(2.51*x+.03))/(x*(2.43*x+.59)+.14);
    
    o = vec4(x, 1.);
}