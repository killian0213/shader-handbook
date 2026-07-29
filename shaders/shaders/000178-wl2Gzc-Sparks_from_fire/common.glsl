// Common (common) — Sparks from fire by jaszunio15
// https://www.shadertoy.com/view/wl2Gzc


float hash1_2(in vec2 x)
{
 	return fract(sin(dot(x, vec2(52.127, 61.2871))) * 521.582);   
}

vec2 hash2_2(in vec2 x)
{
    return fract(sin(x * mat2x2(20.52, 24.1994, 70.291, 80.171)) * 492.194);
}

//Simple interpolated noise
vec2 noise2_2(vec2 uv)
{
    //vec2 f = fract(uv);
    vec2 f = smoothstep(0.0, 1.0, fract(uv));
    
 	vec2 uv00 = floor(uv);
    vec2 uv01 = uv00 + vec2(0,1);
    vec2 uv10 = uv00 + vec2(1,0);
    vec2 uv11 = uv00 + 1.0;
    vec2 v00 = hash2_2(uv00);
    vec2 v01 = hash2_2(uv01);
    vec2 v10 = hash2_2(uv10);
    vec2 v11 = hash2_2(uv11);
    
    vec2 v0 = mix(v00, v01, f.y);
    vec2 v1 = mix(v10, v11, f.y);
    vec2 v = mix(v0, v1, f.x);
    
    return v;
}

//Simple interpolated noise
float noise1_2(in vec2 uv)
{
    vec2 f = fract(uv);
    //vec2 f = smoothstep(0.0, 1.0, fract(uv));
    
 	vec2 uv00 = floor(uv);
    vec2 uv01 = uv00 + vec2(0,1);
    vec2 uv10 = uv00 + vec2(1,0);
    vec2 uv11 = uv00 + 1.0;
    
    float v00 = hash1_2(uv00);
    float v01 = hash1_2(uv01);
    float v10 = hash1_2(uv10);
    float v11 = hash1_2(uv11);
    
    float v0 = mix(v00, v01, f.y);
    float v1 = mix(v10, v11, f.y);
    float v = mix(v0, v1, f.x);
    
    return v;
}