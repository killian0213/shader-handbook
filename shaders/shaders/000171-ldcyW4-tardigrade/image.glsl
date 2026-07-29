// Image (image) — tardigrade by zguerrero
// https://www.shadertoy.com/view/ldcyW4

vec2 SinusNoise(vec2 uv)
{
    vec4 s = sin(uv.xyxy * vec4(6.0, 5.5, 5.8, 6.3) + iTime * vec4(0.1, 0.13, -0.2, -0.06));
    vec4 s2 = sin(uv.xyxy * vec4(7.2, 6.8, 7.4, 6.5) + iTime * vec4(-0.07, -0.08, 0.1, 0.8) + s); 
    return vec2(s2.x + s2.y, s2.z + s2.w);
}

//https://www.shadertoy.com/view/4djSRW
float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * 443.8975);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy/iResolution.xy;
    vec2 sNoise = SinusNoise(uv*2.0);
    uv += sNoise*0.005;
    
	vec4 t0 = textureLod(iChannel0, uv, 0.0);
    
    float h = hash12(uv)*0.2+0.8;
    
	vec4 res = (t0.xxxx + t0.w*1.5) * mix(1.0, h, clamp(t0.y, 0.5, 1.0));
        
	fragColor = pow(res*1.1, vec4(1.75));
}