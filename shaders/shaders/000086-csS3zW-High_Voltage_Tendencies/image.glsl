// Image (image) — High Voltage Tendencies by leon
// https://www.shadertoy.com/view/csS3zW


// High Voltage Tendencies
// Another cloud shader

// reduces if too slow
const float frames = 3.;

// global
float glow;

// snippets
#define R iResolution.xy
#define N(a,b,c) normalize(vec3(a,b,c))
#define ss(a,b,t) smoothstep(a,b,t)
mat2 rot (float a) { float c=cos(a),s=sin(a); return mat2(c,-s,s,c); }
float gyroid (vec3 seed) { return dot(sin(seed),cos(seed.yzx)); }

// noise
float fbm (vec3 seed)
{
    float result = 0., a = .5;
    for (int i = 0; i < 8; ++i, a/=2.)
    {
        result += abs(gyroid(seed/a))*a;
    }
    return result;
}

// signed distance function
float map(vec3 p)
{
    float dist = 100.;
    
    // cloud
    vec3 seed = p*.4;
    seed.z += iTime*.1;
    float noise = fbm(seed);
    dist = length(p) - .5 - noise*1.;
    
    // lightning
    const float count = 4.;
    float a = 1.;
    float t = iTime*.2 + noise*.5;
    float r = .1+.2*sin(iTime+p.x);
    float shape = 100.;
    for (float i = 0.; i < count; ++i)
    {
        p.xz *= rot(t/a);
        p.xy *= rot(t/a);
        p = abs(p)-r*a;
        shape = min(shape, length(p.xz));
        a /= 1.8;
    }
    glow += .002/shape;
    dist = min(dist, shape);
    
    return dist*.8;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord-iResolution.xy/2.)/iResolution.y;
    vec3 color = vec3(0);
    
    // layers
    for (float f = 0.; f < frames; ++f)
    {
        // blue noise scroll by iq https://www.shadertoy.com/view/tlySzR
        ivec2 p = ivec2(fragCoord);
        p = (p+(iFrame*196+int(f))*ivec2(113,127)) & 1023;
        vec3 blu = texelFetch(iChannel0,p,0).xyz;

        // coordinates
        vec3 pos = vec3(0,0,7);
        vec3 ray = normalize(vec3(uv,-3));
        ray.xy += blu.xy * ss(.5,8.,length(uv)); // blur edge
        pos += ray * blu.z * 4.; // pre start

        vec3 tint = vec3(0);
        glow = 0.;

        // raymarch
        const float count = 40.;
        float maxDist = 10.;
        float steps = 0.;
        float total = 0.;
        for (steps = count; steps > 0.; --steps) {
            float dist = map(pos);
            if (dist < .001*total || total > maxDist) break;
            dist *= 0.9+0.1*blu.z; // dithering
            ray.xy += blu.xy*total*.001; // depth of field
            pos += ray * dist;
            total += dist;
        }

        // shading
        float shade = steps/count;
        if (shade > .1 && total < maxDist) {

            // NuSan https://www.shadertoy.com/view/3sBGzV
            vec2 noff = vec2(.2*pow(length(uv),2.),0);
            vec3 normal = normalize(map(pos)-vec3(map(pos-noff.xyy), map(pos-noff.yxy), map(pos-noff.yyx)));

            // color palette https://iquilezles.org/www/articles/palettes/palettes.htm
            tint = .8+.5*cos(vec3(1,2,3)*6.1 + pos.y*1. + normal.z*3.);

            // backlight
            tint *= dot(normal, ray)*.5+.5;
        }

        // bloom
        tint += glow*.5;
        
        // average
        color += tint/frames;
    }
    
    fragColor = vec4(color, 1);
}