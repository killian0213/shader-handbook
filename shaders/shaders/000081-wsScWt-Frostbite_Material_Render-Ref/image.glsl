// Image (image) — Frostbite Material Render-Ref by TinyTexel
// https://www.shadertoy.com/view/wsScWt

// Lincense: CC0 (https://creativecommons.org/publicdomain/zero/1.0/)

/*
Basic implementation of Frostbite's material + relevant sampling strategies.
Camera controls via mouse + shift key.

References:
	https://seblagarde.files.wordpress.com/2015/07/course_notes_moving_frostbite_to_pbr_v32.pdf
	https://blog.selfshadow.com/publications/s2012-shading-course/burley/s2012_pbs_disney_brdf_notes_v3.pdf

The bulk of the material specific code is in the Common tab; direct light sampling routines + rendering in BufferA. Tonemapping in Image.
*/


#if 1
vec4 cubic2(float x)
{
	float x2 = x * x;
	float x3 = x2 * x;
	vec4 w;
	w.x = -x3 + 3.0f * x2 - 3.0f * x + 1.0f;
	w.y = 3.0f * x3 - 6.0f * x2 + 4.0f;
	w.z = -3.0f * x3 + 3.0f * x2 + 3.0f * x + 1.0f;
	w.w = x3;
	return w / 6.0f;
}

vec4 SampleCubic(vec2 mPos)
{    
	mPos -= 0.5f;

	vec2 fuvw = fract(mPos);
	mPos -= fuvw;

	vec4 cubicX = cubic2(fuvw.x);
	vec4 cubicY = cubic2(fuvw.y);

	vec2 cX = mPos.xx + vec2(-0.5f, 1.5f);
	vec2 cY = mPos.yy + vec2(-0.5f, 1.5f);

	vec2 sX = cubicX.xz + cubicX.yw;
	vec2 sY = cubicY.xz + cubicY.yw;

	vec2 offsetX = cX + cubicX.yw / sX;
	vec2 offsetY = cY + cubicY.yw / sY;

	vec4 value0;
	vec4 value1;
	vec4 value2;
	vec4 value3;

	value0 = textureLod(iChannel0, vec2(offsetX.x, offsetY.x) / iResolution.xy, 0.0);
	value1 = textureLod(iChannel0, vec2(offsetX.y, offsetY.x) / iResolution.xy, 0.0);
	value2 = textureLod(iChannel0, vec2(offsetX.x, offsetY.y) / iResolution.xy, 0.0);
	value3 = textureLod(iChannel0, vec2(offsetX.y, offsetY.y) / iResolution.xy, 0.0);

	float lX = sX.x / (sX.x + sX.y);
	float lY = sY.x / (sY.x + sY.y);

	return mix(mix(value3, value2, lX), mix(value1, value0, lX), lY);
}
#else
float BSpline(float x)
{
    bool s = x < 0.0;
    
    x = abs(x);

    bool c = x < 1.0;
    
    if(!c) x = 2.0 - x;
    
    float x2 = x  * x;
    float x3 = x2 * x;
	
    float r = x3 * (1.0/6.0);
    
    if(c) r = r * 3.0 - x2 + 2.0/3.0;
    
    return r;
}
vec2 BSpline(vec2 v)
{
    return vec2(BSpline(v.x), BSpline(v.y));
}

vec4 SampleCubic(vec2 uv)
{
    uv += 0.5;
    vec2 uv0 = floor(uv);
    vec2 fuv = fract(uv);
    
    vec4 col = vec4(0.0);
    for(float y = 0.0; y < 4.0; ++y)
    for(float x = 0.0; x < 4.0; ++x)
    {
        vec2 o = vec2(x, y);
        vec2 w = 1.0 - abs(fuv - o);
        w = BSpline(fuv - o+1.0);
        
    	col += texelFetch(iChannel0, ivec2(uv0+o)-2, 0) * (w.x*w.y);
    }
    
    return col;
}
#endif


vec3 sRGB_EOTF(vec3 rgb)
{
    return If(greaterThan(rgb, vec3(0.0031308)), pow(rgb, vec3(1.0/2.4)) * 1.055 - 0.055, rgb * 12.92);
}


// ACES fit by Stephen Hill (@self_shadow)
// https://github.com/TheRealMJP/BakingLab/blob/master/BakingLab/ACES.hlsl 
// more info: https://www.shadertoy.com/view/WltSRB

// sRGB => XYZ => D65_2_D60 => AP1
const mat3 sRGBtoAP1 = mat3
(
	0.613097, 0.339523, 0.047379,
	0.070194, 0.916354, 0.013452,
	0.020616, 0.109570, 0.869815
);

// AP1 => RRT_SAT
const mat3 RRT_SAT = mat3
(
	0.970889, 0.026963, 0.002148,
	0.010889, 0.986963, 0.002148,
	0.010889, 0.026963, 0.962148
);


// sRGB => XYZ => D65_2_D60 => AP1 => RRT_SAT
const mat3 ACESInputMat = mat3
(
    0.59719, 0.35458, 0.04823,
    0.07600, 0.90834, 0.01566,
    0.02840, 0.13383, 0.83777
);

// ODT_SAT => XYZ => D60_2_D65 => sRGB
const mat3 ACESOutputMat = mat3
(
     1.60475, -0.53108, -0.07367,
    -0.10208,  1.10813, -0.00605,
    -0.00327, -0.07276,  1.07602
);

vec3 ToneTF0(vec3 x)
{
    vec3 a = (x            + 0.0509184) * x;
    vec3 b = (x * 0.973854 + 0.7190130) * x + 0.0778594;
    
    return a / b;
}

vec3 ToneTF1(vec3 x)
{
    vec3 a = (x          + 0.0961727) * x;
    vec3 b = (x * 0.9797 + 0.6157480) * x + 0.213717;
    
    return a / b;
}

vec3 ToneTF2(vec3 x)
{
    vec3 a = (x            + 0.0822192) * x;
    vec3 b = (x * 0.983521 + 0.5001330) * x + 0.274064;
    
    return a / b;
}

vec3 RRTAndODTFit(vec3 x)
{
    vec3 a = (x            + 0.0245786) * x;
    vec3 b = (x * 0.983729 + 0.4329510) * x + 0.238081;
    
    return a / b;
}

vec3 Tonemap_ACESFitted(vec3 srgb)
{
    vec3 color = srgb * ACESInputMat;
   
   #if 1
    color = ToneTF0(color);
   #else
    color = RRTAndODTFit(color);
   #endif
    
    color = color * ACESOutputMat;

    return color;
}

vec3 Tonemap_ACESFitted2(vec3 acescg)
{
    vec3 color = acescg * RRT_SAT;
    
   #if 1
    color = ToneTF0(color);
   #else
    color = RRTAndODTFit(color);
   #endif
    
    color = color * ACESOutputMat;

    return color;
}

vec3 Tonemap(vec3 col)
{
    #if 1
    #ifdef USE_ACESCG
	col = Tonemap_ACESFitted2(col);
    #else
	col = Tonemap_ACESFitted(col);
    #endif
    #endif
    
    col = clamp01(col);
    
    return col;
}

void mainImage(out vec4 fragColor, in vec2 uv)
{
    float exposure = 3.0;
    
	vec2 tex = uv / iResolution.xy;
    
    vec3 col = textureLod(iChannel0, tex, 0.0).rgb;

    col = Tonemap(col * exp2(exposure));
    
    #if 1
    {
        /* oversample tonemapping; prevents aliased edges around very bright spots/light sources */
        vec3 fcol = vec3(0.0);
        vec3 fm = vec3(0.0);

        const uint count = 8u; 
        for(uint i = 0u; i < count; ++i)
        {
            vec2 o = Float11(Roberts(uvec2(0u), i));
            vec2 off = o * 0.75;
            //off = vec2(Sample_Triangle(o.x), Sample_Triangle(o.y))*1.5;

            //vec3 c0 = textureLod(iChannel0, (uv + off) / iResolution.xy, 0.0).rgb;
            vec3 c0 = SampleCubic(uv + off).rgb;
            c0 *= exp2(exposure);

            vec3 c1 = Tonemap(c0);

            fm += clamp01((c1 - c0)*(c1 - c0));

            fcol += (c1);
        }

        fcol /= float(count);
        fm /= float(count);

        col = mix(col, fcol, 1.0-(1.0-fm)*(1.0-fm));
        //col = mix(col, fcol, fm);
    }
    #endif
    
    #if 0
    // vignetting:
    vec2 s = abs(tex*2.0-1.0);
    s.x = 1.0-Pow3(s.x);    s.y = 1.0-Pow3(s.y);
    col *= mix(1.0, 0.4, Pow2(1.0-sqrt(s.x*s.y)));
	#endif
    
    fragColor = vec4(sRGB_EOTF(clamp(col, 0.0, 1.0)), 0.0);
    //fragColor = vec4(col, 0.0);
}