// Image (image) — [SH17B] The Next Generation by Klems
// https://www.shadertoy.com/view/ldSfRG


#define PI 3.14159265359
#define PHI 1.61803398875

#define SAMPLES 20
#define BLOOM_RADIUS 20.0

vec3 hash33(vec3 p3){
    #define HASHSCALE3 vec3(.1031, .1030, .0973)
	p3 = fract(p3 * HASHSCALE3);
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    
	vec2 uv = fragCoord / iResolution.xy;
    vec4 value = texture(iChannel0, uv);
	vec3 rnd = hash33(vec3(fragCoord, iFrame));
    
    fragColor.rgb = value.rgb;
    
    
    vec3 bloom = vec3(0);
    float totfac = 0.0;
    
    // bloom
    for (int i = 0 ; i < SAMPLES ; i++) {
        
        float theta = 2.0*PI*PHI*float(i);
        theta += rnd.x*2.0*PI;
        float radius = sqrt(float(i)) / sqrt(float(SAMPLES));
        radius *= BLOOM_RADIUS;
        
        vec2 offset = vec2(cos(theta), sin(theta))*radius;
        vec4 here = texture(iChannel0, (fragCoord+offset)/iResolution.xy);
        
        float fact = smoothstep(BLOOM_RADIUS, 0.0, radius);
        
        bloom += here.rgb*0.05*fact;
        totfac += fact;
    }
    
    bloom /= totfac;
    fragColor.rgb += bloom;
    
    // clamp values, then gamma correction
    fragColor.rgb = clamp(fragColor.rgb, vec3(0), vec3(1));
    fragColor.rgb = pow(fragColor.rgb, vec3(1.0/2.2));
    
    // vignette
    vec2 p = fragCoord.xy / iResolution.xy * 2.0 - 1.0;
    fragColor.rgb = mix(fragColor.rgb, vec3(0), dot(p, p)*0.1);
    
    
}