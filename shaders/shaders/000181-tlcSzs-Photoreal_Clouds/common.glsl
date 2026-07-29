// Common (common) — Photoreal Clouds by TekF
// https://www.shadertoy.com/view/tlcSzs

// quality adjustments - to improve fps
const int sampleCountMultiplier = 11; // increase this until fps drops
#define MOSAIC_PREVIEW 1
//#define RESOLUTION_REDUCTION 2

//#define ANIMATE 1


// random hash from here: https://www.shadertoy.com/view/4dVBzz
#define M1 1597334677U     //1719413*929
#define M2 3812015801U     //140473*2467*11
#define M3 3299493293U     //467549*7057

#define F0 (1.0/float(0xffffffffU))

#define hash(n) n*(n^(n>>15))

#define coord1(p) (uint(p)*M1)
#define coord2(p) (uvec2(p).x*M1^uvec2(p).y*M2)
#define coord3(p) (uvec3(p).x*M1^uvec3(p).y*M2^uvec3(p).z*M3)

float hash1(uint n){return float(hash(n))*F0;}
vec2 hash2(uint n){return vec2(hash(n)*uvec2(0x1U,0x3fffU))*F0;}
vec3 hash3(uint n){return vec3(hash(n)*uvec3(0x1U,0x1ffU,0x3ffffU))*F0;}
vec4 hash4(uint n){return vec4(hash(n)*uvec4(0x1U,0x7fU,0x3fffU,0x1fffffU))*F0;}


// sequential rand functions - return a different value each time
uint seed = 1u;

void SeedRand( int frame, vec2 fragCoord )
{
    seed = coord3(uvec3(frame,fragCoord));
}
float rand() { return hash1(coord1(seed++)); }
vec2 rand2() { return hash2(coord1(seed++)); }
vec3 rand3() { return hash3(coord1(seed++)); }
vec4 rand4() { return hash4(coord1(seed++)); }


// continuous noise
// cheaper and uglier than perlin
float Noise( vec3 pos )
{
    uvec3 p = uvec3(ivec3(floor(pos))+0x8000000);
    vec3 f = smoothstep(.0,1.,fract(pos));
    uvec2 d = uvec2(0,1);
    
    return
        mix(
        	mix(
                mix( hash1(coord3(p+d.xxx)), hash1(coord3(p+d.yxx)), f.x ),
                mix( hash1(coord3(p+d.xyx)), hash1(coord3(p+d.yyx)), f.x ),
                f.y
            ),
        	mix(
                mix( hash1(coord3(p+d.xxy)), hash1(coord3(p+d.yxy)), f.x ),
                mix( hash1(coord3(p+d.xyy)), hash1(coord3(p+d.yyy)), f.x ),
                f.y
            ),
            f.z
        );
}


// catmull-rom texture sampler, from https://www.shadertoy.com/view/4tyGDD by Giliam de Carpentier
vec4 SampleTextureBilinearlyAndUnpack(sampler2D tex, vec2 uv)
{
    vec4 sample_color = texture(tex, uv, 0.0);
#ifdef PACK_SIGNED_TO_UNSIGNED
    sample_color = 2.0 * sample_color - 1.0;
#endif // PACK_SIGNED_TO_UNSIGNED
    return sample_color;
}
 
vec4 SampleTextureCatmullRom4Samples(sampler2D tex, vec2 uv, vec2 texSize)
{
    // Based on the standard Catmull-Rom spline: w1*C1+w2*C2+w3*C3+w4*C4, where
    // w1 = ((-0.5*f + 1.0)*f - 0.5)*f, w2 = (1.5*f - 2.5)*f*f + 1.0,
    // w3 = ((-1.5*f + 2.0)*f + 0.5)*f and w4 = (0.5*f - 0.5)*f*f with f as the
    // normalized interpolation position between C2 (at f=0) and C3 (at f=1).
 
    // half_f is a sort of sub-pixelquad fraction, -1 <= half_f < 1.
    vec2 half_f     = 2.0 * fract(0.5 * uv * texSize - 0.25) - 1.0;
 
    // f is the regular sub-pixel fraction, 0 <= f < 1. This is equivalent to
    // fract(uv * texSize - 0.5), but based on half_f to prevent rounding issues.
    vec2 f          = fract(half_f);
 
    vec2 s1         = ( 0.5 * f - 0.5) * f;            // = w1 / (1 - f)
    vec2 s12        = (-2.0 * f + 1.5) * f + 1.0;      // = (w2 - w1) / (1 - f)
    vec2 s34        = ( 2.0 * f - 2.5) * f - 0.5;      // = (w4 - w3) / f
 
    // positions is equivalent to: (floor(uv * texSize - 0.5).xyxy + 0.5 +
    // vec4(-1.0 + w2 / (w2 - w1), 1.0 + w4 / (w4 - w3))) / texSize.xyxy.
    vec4 positions  = vec4((-f * s12 + s1      ) / (texSize * s12) + uv,
                           (-f * s34 + s1 + s34) / (texSize * s34) + uv);
 
    // Determine if the output needs to be sign-flipped. Equivalent to .x*.y of
    // (1.0 - 2.0 * floor(t - 2.0 * floor(0.5 * t))), where t is uv * texSize - 0.5.
    float sign_flip = half_f.x * half_f.y > 0.0 ? 1.0 : -1.0;
 
    vec4 w          = vec4(-f * s12 + s12, s34 * f); // = (w2 - w1, w4 - w3)
    vec4 weights    = vec4(w.xz * (w.y * sign_flip), w.xz * (w.w * sign_flip));
 
    return SampleTextureBilinearlyAndUnpack(tex, positions.xy) * weights.x +
           SampleTextureBilinearlyAndUnpack(tex, positions.zy) * weights.y +
           SampleTextureBilinearlyAndUnpack(tex, positions.xw) * weights.z +
           SampleTextureBilinearlyAndUnpack(tex, positions.zw) * weights.w;
}
