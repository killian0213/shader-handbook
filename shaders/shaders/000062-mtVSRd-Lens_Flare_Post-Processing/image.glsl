// Image (image) — Lens Flare Post-Processing by gelami
// https://www.shadertoy.com/view/mtVSRd


// Lens Flare Post-Processing - gelami
// https://www.shadertoy.com/view/mtVSRd

/* 
 * Lens flare post-processing effect featuring ghosts, halo, glare, and bloom
 * 
 * Mouse drag to look around
 * Defines in Common
 * 
 * Resources:
 * 
 * Custom Lens-Flare Post-Process in Unreal Engine - Froyok
 * https://www.froyok.fr/blog/2021-09-ue4-custom-lens-flare/
 * 
 * Pseudo Lens Flare - John Chapman
 * http://john-chapman-graphics.blogspot.com/2013/02/pseudo-lens-flare.html
 * 
 * Bloom pass based from:
 * 2-Pass Buffer Bloom - gelami
 * https://www.shadertoy.com/view/cty3R3
 * 
 */


// Fork of "Gelami Raymarching Template" by gelami. https://shadertoy.com/view/mslGRs
// 2023-06-09 09:23:00

vec2 fisheye(vec2 uv)
{
    uv = uv * 2.0 - 1.0;
    
    const float f = 0.5;
    const float scale = f * atan(1.0 / f);
    float rd = length(uv) * scale;
    float ru = f*tan(rd / f);
    float phi = atan(uv.y, uv.x);
    uv = (vec2(cos(phi), sin(phi)) * ru + 1.0) * 0.5;

    return uv;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pv = (2. * (fragCoord) - iResolution.xy) / iResolution.y;
    vec2 uv = fragCoord / iResolution.xy;
    vec2 px = 1.0 / iResolution.xy;
    vec2 aspect = vec2(iResolution.x / iResolution.y, 1);
    
    vec3 ro = getCameraPos(iMouse, iResolution.xy, iTime);
    vec3 lo = getLookAtPos();
    
    mat3 cmat = getCameraMatrix(ro, lo);

    vec3 col = texture(iChannel0, uv).rgb;
    
    vec2 iuv = 1.0 - uv;
    
    const float k = length(vec2(0.5));
    
    float l = length(0.5 - iuv) / k;
    
    // Dirt texture
    float dirt = 1.0 - textureLod(iChannel3, (pv + 1.0) * 0.5, 1.0).r;
    dirt = dirt*dirt * 0.4 + 0.6;
    
    float crot = cmat[0].z + cmat[1].y + cmat[2].x;
    
    vec2 suv = rot2D(crot) * pv;
    
    // Starburst texture
    float star = atan(suv.y, suv.x) / TAU + 0.5;
    star = textureLod(iChannel3, vec2(star * 2.5, 0), 0.0).b;
    star = smoothstep(0.1, 0.65, star);
    star = mix(star, 0.1, smoothstep(1.0, 0.35, l));
    
    dirt *= star;
    
    #ifdef GHOSTS
    float gstr = GHOSTS_OFFSET;
    vec2 guv = (0.5 - iuv) * gstr;
    
    const float ca = CHROMATIC_ABERRATION_STRENGTH;
    vec3 caStr = vec3(-px.y, 0, px.y) * ca;
    vec2 dir = normalize(guv);
    
    vec3 res = vec3(0);
    for (int i = 0; i < GHOSTS_COUNT; i++)
    {
        vec2 p = iuv + guv * float(i);
        
        float d = length(0.5 - p) / k;
        float w = pow(max(1.0 - d, 0.0), 8.0);
    
        float f = texture(iChannel3, vec2(0.12 * d, 0)).b * 5.0;
        
        vec3 c = palette2(f) * 3.0;
        
        #ifdef CHROMATIC_ABERRATION
        res += sampleDistorted(iChannel0, p, dir, caStr) * w * c;
        #else
        res += sampleBuffer(iChannel0, p) * w * c;
        #endif
    }
    
    col += res * dirt * GHOSTS_STRENGTH;
    
    #endif
    
    #ifdef HALO
    const float hstr = HALO_RADIUS;
    vec2 huv = normalize(pv) * hstr;
    
    vec2 fuv = fisheye(iuv);
    float hw = length(0.5 - fract(huv / aspect + iuv)) / k;
    hw = pow(max(1.0 - hw, 0.0), 8.0) * smoothstep(0.1, 0.0, length(pv) - hstr * 2.0) * HALO_STRENGTH;
    
    #ifdef CHROMATIC_ABERRATION
    col += sampleDistorted(iChannel0, huv / aspect + iuv, dir, caStr) * hw * dirt;
    #else
    col += sampleBuffer(iChannel0, huv / aspect + iuv) * hw * dirt;
    #endif
    
    #endif
    
    #ifdef BLOOM
    vec3 bloom = vec3(0);
    
    bloom += SampleLod(iChannel1, uv, iResolution.xy, 0).rgb;
    bloom += SampleLod(iChannel1, uv, iResolution.xy, 1).rgb;
    bloom += SampleLod(iChannel1, uv, iResolution.xy, 2).rgb;
    bloom += SampleLod(iChannel1, uv, iResolution.xy, 3).rgb;
    bloom += SampleLod(iChannel1, uv, iResolution.xy, 4).rgb;
    bloom += SampleLod(iChannel1, uv, iResolution.xy, 5).rgb;
    
    bloom /= 6.0;
    
    col += bloom * BLOOM_STRENGTH;
    #endif
    
    #ifdef GLARE
    col += texture(iChannel2, uv * 0.5).rgb * GLARE_STRENGTH;
    #endif
    
    col *= EXPOSURE;
    col = max(col, vec3(0));
    
    #ifdef SHOW_FALSE_COLOR
    col = palette(saturate(luminance(col)));
    
    if (fragCoord.y < 10.0)
        col = palette(uv.x);
    #endif
    
    col = ReinhardJodie(col);
    //col = ReinhardExtLuma(col, 2.5);
    //col = ACESFilm(col * 0.35);
    
    fragColor = vec4(linearTosRGB(col), 1);
    fragColor += (dot(hash23(vec3(fragCoord, iTime)), vec2(1)) - 0.5) / 255.;
}
