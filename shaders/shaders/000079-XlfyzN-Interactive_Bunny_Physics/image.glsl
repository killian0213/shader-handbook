// Image (image) — Interactive Bunny Physics by ThomasSchander
// https://www.shadertoy.com/view/XlfyzN

vec3 Tonemap_ACES(const vec3 x) {
    // Narkowicz 2015, "ACES Filmic Tone Mapping Curve"
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return (x * (a * x + b)) / (x * (c * x + d) + e);
}

//#define NO_POST_PRO

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 q = fragCoord.xy / iResolution.xy;
    
#ifdef NO_POST_PRO
    fragColor.xyz = pow(Tonemap_ACES(textureLod(iChannel0, q, 0.0).xyz), vec3(0.4545));
    return;
#endif
    vec2 v = -1.0 + 2.0*q;
    v.x *= iResolution.x/ iResolution.y;
    
    float vign = smoothstep(4.0, 0.6, length(v));
    
    vec2 centerToUv = q-vec2(0.5);
	vec3 aberr;
    aberr.x = textureLod(iChannel0, vec2(0.5)+centerToUv*0.995,0.0).x; 
    aberr.y = textureLod(iChannel0, vec2(0.5)+centerToUv*0.997, 0.0).y;
    aberr.z = textureLod(iChannel0, vec2(0.5)+centerToUv, 0.0).z;
    float exposure = (1.0+0.1*sin(0.5*iTime)*sin(1.4*iTime));
    fragColor = vec4(pow(Tonemap_ACES(exposure*vign*aberr), vec3(0.1+0.4545)), 1.0);
}

