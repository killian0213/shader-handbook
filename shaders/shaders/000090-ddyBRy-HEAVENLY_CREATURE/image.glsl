// Image (image) — HEAVENLY CREATURE by alro
// https://www.shadertoy.com/view/ddyBRy

/*

    Further adventures in texture storage and volumetric rendering. 
    Use mouse to move camera.

    Using blackle's excellent rabbit SDF: https://www.shadertoy.com/view/wtVyWK
    Inspired by https://www.shadertoy.com/view/tdjBR1
    
    Store both main density and density along the light ray in Cubemap A
    We then do not need the expensive inner sampling loop when we render in Buffer B
    The tradeoff is that the shape is static but the surface could still be
    moved if light rays do not need detail.
    
    There are 2 more channels in the cubemap which allow us to either increase
    the resolution or add more variables such as colour or ambient lighting.
    
    See Common tab for resolution and light sampling constants

    EDIT: Force a second render in frame 10 to fix CubemapA loading error

*/

const float bloomStrength = 0.5;

//-------------------------------- Bicubic blur --------------------------------

// https://www.shadertoy.com/view/Dl2SDW

// Cubic B-spline weighting
vec2 w0(vec2 a){
    return (1.0/6.0)*(a*(a*(-a + 3.0) - 3.0) + 1.0);
}

vec2 w1(vec2 a){
    return (1.0/6.0)*(a*a*(3.0*a - 6.0) + 4.0);
}

vec2 w2(vec2 a){
    return (1.0/6.0)*(a*(a*(-3.0*a + 3.0) + 3.0) + 1.0);
}

vec2 w3(vec2 a){
    return (1.0/6.0)*(a*a*a);
}

// g0 is the amplitude function
vec2 g0(vec2 a){
    return w0(a) + w1(a);
}

// h0 and h1 are the two offset functions
vec2 h0(vec2 a){
    return -1.0 + w1(a) / (w0(a) + w1(a));
}

vec2 h1(vec2 a){
    return 1.0 + w3(a) / (w2(a) + w3(a));
}

vec4 bicubic(sampler2D tex, vec2 uv, vec2 textureLodSize, float lod){
	
    uv = uv * textureLodSize + 0.5;
    
	vec2 iuv = floor(uv);
	vec2 f = fract(uv);

    // Find offset in texel
    vec2 h0 = h0(f);
    vec2 h1 = h1(f);

    // Four sample points
	vec2 p0 = (iuv + h0 - 0.5) / textureLodSize;
	vec2 p1 = (iuv + vec2(h1.x, h0.y) - 0.5) / textureLodSize;
	vec2 p2 = (iuv + vec2(h0.x, h1.y) - 0.5) / textureLodSize;
	vec2 p3 = (iuv + h1 - 0.5) / textureLodSize;
	
    // Weighted linear interpolation
    // g0 + g1 = 1 so only one is needed for a mix
    vec2 g0 = g0(f);
    return mix( mix(textureLod(tex, p3, lod), textureLod(tex, p2, lod), g0.x),
                mix(textureLod(tex, p1, lod), textureLod(tex, p0, lod), g0.x), g0.y);
}

vec4 textureBicubic(sampler2D s, vec2 uv, float lod) {

    vec2 lodSizeFloor = vec2(textureSize(s, int(lod)));
    vec2 lodSizeCeil = vec2(textureSize(s, int(lod + 1.0)));

    vec4 floorSample = bicubic(s, uv, lodSizeFloor.xy, floor(lod));
    vec4 ceilSample = bicubic(s, uv, lodSizeCeil.xy, ceil(lod));

    return mix(floorSample, ceilSample, fract(lod));
}

vec4 getBlur(sampler2D s, vec2 uv, float blur){
    float maxLod = floor(log2(iChannelResolution[0].x));
    float lod = mix(0.0, maxLod-1.0, blur);
    return textureBicubic(s, uv, lod);
}

//----------------------------- Tonemapping and output ------------------------------

//https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
vec3 ACESFilm(vec3 x){
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    vec2 uv = fragCoord/iResolution.xy;
    
    vec3 col = texture(iChannel0, uv).rgb;

    if(bloomStrength > 0.0){
        vec3 bloom = getBlur(iChannel0, uv, 0.2).rgb;
        bloom += getBlur(iChannel0, uv, 0.3).rgb;
        bloom += getBlur(iChannel0, uv, 0.55).rgb;
        bloom += getBlur(iChannel0, uv, 0.6).rgb;
        bloom /= 4.0;
        col += bloomStrength * bloom;
    }
    
    // Tonemapping
    col = ACESFilm(col);
    
    // Gamma
    col = pow(col, vec3(0.4545));
    
    fragColor = vec4(col, 1.0);
}