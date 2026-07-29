// Image (image) — Swarming Anchoveta by fenix
// https://www.shadertoy.com/view/mtSGDt

// ---------------------------------------------------------------------------------------
//	Created by fenix in 2023
//	License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
//  75k Engraulia ringens, the Peruvian anchoveta, form into a swarm in an attempt to
//  dissuade predators. Water surface borrowed from rockhard's
//
//      ocean under               https://shadertoy.com/view/7dyXWc
//
//  FXAA from reinder's
//
//      Post process - FXAA       https://shadertoy.com/view/ls3GWS
//
//  SSAO originally from iq's
//
//      SSAO (basic)              https://www.shadertoy.com/view/Ms23Wm
//
//  I saw these fish swarms, and I thought it looked like a good use for SSAO.
//
//      https://www.researchgate.net/profile/Michael-Thrun/publication/338880262/figure/fig1/AS:1033391478669313@1623391136755/A-fish-swarm-in-the-form-of-a-ball-Uber-Pix-2015-an-example-of-emergence-in-swarms.ppm
//
//  Since I already had particles rendering with SSAO, I modified the particle sim to
//  to move like this swarm, and then modified the particle rendering to draw ellipoids
//  instead of spheres, with an environment map. For the environment map and background
//  I borrowed the water surface from the excellent "water under" by rockhard (if (s)he
//  sees this I hope (s)he's OK with my pilfering...if not please let me know).
//
//  The physics simply treats the particles as spheres. But, the screen-space voronoi 
//  neighbor search does take the ellipsoid shape into account (otherwise the heads and
//  tails of the fish get lost).
//
//  As usual I'm not really that happy with the anti-aliasing. The FXAA avoids the worst
//  artifacts at least. Suggestions are welsome!
//
//  Click mouse to attract the swarm. Space to disable SSAO, shift to disable FXAA.
//
//  Buffer A simulates particles and tracks particle neighbors in 3D
//  Buffer B computes nearest particles to each screen pixel
//  Buffer C renders G buffer
//  Buffer D performs lighting and SSAO
//  Image performs FXAA post-process
//
// ---------------------------------------------------------------------------------------

// From reinder's  Post process - FXAA
//    https://www.shadertoy.com/view/ls3GWS
// he got it from:
//    http://www.geeks3d.com/20110405/fxaa-fast-approximate-anti-aliasing-demo-glsl-opengl-test-radeon-geforce/3/
#define FXAA_SPAN_MAX 8.0
#define FXAA_REDUCE_MUL   (1.0/FXAA_SPAN_MAX)
#define FXAA_REDUCE_MIN   (1.0/128.0)
#define FXAA_SUBPIX_SHIFT (1.0/4.0)

vec3 AArender( vec2 uv2 )
{    
    uv2 /= iResolution.xy;
    vec2 rcpFrame = 1. / iResolution.xy;
    vec4 uv = vec4( uv2, uv2 - (rcpFrame * (0.5 + FXAA_SUBPIX_SHIFT)));

    vec3 rgbNW = textureLod(iChannel0, uv.zw, 0.0).xyz;
    vec3 rgbNE = textureLod(iChannel0, uv.zw + vec2(1,0)*rcpFrame.xy, 0.0).xyz;
    vec3 rgbSW = textureLod(iChannel0, uv.zw + vec2(0,1)*rcpFrame.xy, 0.0).xyz;
    vec3 rgbSE = textureLod(iChannel0, uv.zw + vec2(1,1)*rcpFrame.xy, 0.0).xyz;
    vec3 rgbM  = textureLod(iChannel0, uv.xy, 0.0).xyz;

    vec3 luma = vec3(0.299, 0.587, 0.114);
    float lumaNW = dot(rgbNW, luma);
    float lumaNE = dot(rgbNE, luma);
    float lumaSW = dot(rgbSW, luma);
    float lumaSE = dot(rgbSE, luma);
    float lumaM  = dot(rgbM,  luma);

    float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
    float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));

    vec2 dir;
    dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
    dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));

    float dirReduce = max(
        (lumaNW + lumaNE + lumaSW + lumaSE) * (0.25 * FXAA_REDUCE_MUL),
        FXAA_REDUCE_MIN);
    float rcpDirMin = 1.0/(min(abs(dir.x), abs(dir.y)) + dirReduce);
    
    dir = min(vec2( FXAA_SPAN_MAX,  FXAA_SPAN_MAX),
          max(vec2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX),
          dir * rcpDirMin)) * rcpFrame.xy;

    vec3 rgbA = (1.0/2.0) * (
        textureLod(iChannel0, uv.xy + dir * (1.0/3.0 - 0.5), 0.0).xyz +
        textureLod(iChannel0, uv.xy + dir * (2.0/3.0 - 0.5), 0.0).xyz);
    vec3 rgbB = rgbA * (1.0/2.0) + (1.0/4.0) * (
        textureLod(iChannel0, uv.xy + dir * (0.0/3.0 - 0.5), 0.0).xyz +
        textureLod(iChannel0, uv.xy + dir * (3.0/3.0 - 0.5), 0.0).xyz);
    
    float lumaB = dot(rgbB, luma);

    if((lumaB < lumaMin) || (lumaB > lumaMax)) return rgbA;
    
    return rgbB; 
}

// From https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
vec3 ACESFilm(vec3 x)
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return clamp((x*(a*x+b))/(x*(c*x+d)+e), 0., 1.);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    if (keyDown(KEY_SPACE))
        fragColor = texture(iChannel0, fragCoord/iResolution.xy);
    else
        fragColor.xyz = AArender(fragCoord);
        
    fragColor.xyz = pow(ACESFilm(fragColor.xyz), vec3(1./2.2));
    fragColor.w = 1.;
}