// Buffer A (buffer) — Inkelly by leon
// https://www.shadertoy.com/view/4fl3Wl

// Inkelly
// leon denise 2023-12-27

// other variations
// https://www.shadertoy.com/view/4cs3Rs
// https://www.shadertoy.com/view/4cX3WS

// feedback displace pass

float delay = 4.;

// crazy noise
float gyroid (vec3 seed) { return dot(sin(seed),cos(seed.yzx)); }
float fbm (vec2 pos)
{
    float t = floor(iTime/delay);
    float t2 = t*1.354;
    vec3 p = vec3(pos, t);
    float result = 0., a = .5;
    for (int i = 0; i < 3; ++i, a /= 2.) {
        result += abs(gyroid(p/a)*a);
    }
    result = sin(result*6.283+t2-pos.x);
    return result;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    vec2 p = (2.*fragCoord-iResolution.xy)/iResolution.y;
    
    // curl noise
    vec2 e = vec2(4./iResolution.y,0);
    vec2 curl = vec2(fbm(p+e.xy)-fbm(p-e.xy), fbm(p+e.yx)-fbm(p-e.yx)) / (2.*e.x);
    curl = vec2(curl.y, -curl.x);
    
    // spawn shape
    p += curl*.05;
    float dist = max(abs(p.x)-2.,abs(p.y));
    //dist = abs(length(p)-.5);
    float mask = smoothstep(.01, 0., dist);
    
    // displace
    curl *= 0.005;
    vec4 frame = texture(iChannel0, uv + curl);

    // feedback
    mask = max(mask, frame.r - iTimeDelta);
    
    fragColor = vec4(mask, curl, 1);
}