// Image (image) — Non-Euclidean world by tmst
// https://www.shadertoy.com/view/WsXcWn

#define DEPTH(texCoord) textureLod(iChannel0, texCoord, 0.0).a

void outlineCheck(in vec2 uv, in float weight, in float aBase, inout float n) {
    n += weight * (1.0 - isInInterval(aBase-0.004, aBase+0.004, DEPTH(uv)));
}

float outline(in vec2 uv, in float aBase) {
    vec2 uvPixel = 1.0/iResolution.xy;
    float n = 0.0;

    outlineCheck(uv + vec2( 1.0, 0.0)*uvPixel, 0.125, aBase, n);
    outlineCheck(uv + vec2( 0.0, 1.0)*uvPixel, 0.125, aBase, n);
    outlineCheck(uv + vec2( 0.0,-1.0)*uvPixel, 0.125, aBase, n);
    outlineCheck(uv + vec2(-1.0, 0.0)*uvPixel, 0.125, aBase, n);

    outlineCheck(uv + vec2( 1.0, 1.0)*uvPixel, 0.125, aBase, n);
    outlineCheck(uv + vec2( 1.0,-1.0)*uvPixel, 0.125, aBase, n);
    outlineCheck(uv + vec2(-1.0, 1.0)*uvPixel, 0.125, aBase, n);
    outlineCheck(uv + vec2(-1.0,-1.0)*uvPixel, 0.125, aBase, n);

    return n;
}

vec2 ssao(vec2 fragCoord) {
    vec2 texCoord = fragCoord / iResolution.xy;
    vec2 texColorSize = iResolution.xy;

    float d = DEPTH(texCoord);
    float scaleBase = 0.25/d;

    vec2 offset[16];
    float rand = hash12(fragCoord);
    vec2 invRes = 1.0 / iResolution.xy;
    
    mat2 m = mat2(INV_SQRT2, INV_SQRT2, -INV_SQRT2, INV_SQRT2);

    float dSample = 2.0*scaleBase;
    float ra = rand*PI_OVER_2;
    vec2 r = vec2(cos(ra), sin(ra));
    offset[ 0] = dSample*vec2( r.x, r.y)*invRes;
    offset[ 1] = dSample*vec2(-r.y, r.x)*invRes;
    offset[ 2] = dSample*vec2(-r.x,-r.y)*invRes;
    offset[ 3] = dSample*vec2( r.y,-r.x)*invRes;

    dSample = 4.0*scaleBase;
    r = m*r;
    offset[ 4] = dSample*vec2( r.x, r.y)*invRes;
    offset[ 5] = dSample*vec2(-r.y, r.x)*invRes;
    offset[ 6] = dSample*vec2(-r.x,-r.y)*invRes;
    offset[ 7] = dSample*vec2( r.y,-r.x)*invRes;

    dSample = 6.0*scaleBase;
    r = m*r;
    offset[ 8] = dSample*vec2( r.x, r.y)*invRes;
    offset[ 9] = dSample*vec2(-r.y, r.x)*invRes;
    offset[10] = dSample*vec2(-r.x,-r.y)*invRes;
    offset[11] = dSample*vec2( r.y,-r.x)*invRes;

    dSample = 8.0*scaleBase;
    r = m*r;
    offset[12] = dSample*vec2( r.x, r.y)*invRes;
    offset[13] = dSample*vec2(-r.y, r.x)*invRes;
    offset[14] = dSample*vec2(-r.x,-r.y)*invRes;
    offset[15] = dSample*vec2( r.y,-r.x)*invRes;

    float deeperCount = 0.0;
    float nearerCount = 0.0;
    for(int i=0; i<16; ++i){
        vec2 texSamplePos = texCoord + offset[i];
        float dsamp = DEPTH(texSamplePos);

        deeperCount += step(d, dsamp);
        nearerCount += step(dsamp, d);
    }

    float shadowIntensity = clamp(1.0 - deeperCount/8.0, 0.0, 1.0);
    float highlightIntensity = clamp(1.0 - nearerCount/8.0, 0.0, 1.0);

    return vec2(shadowIntensity, highlightIntensity);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    vec4 dataBase = textureLod(iChannel0, uv, 0.0);
    vec3 rgb = unpackColor(dataBase.st);
    float glow = dataBase.b;
    float depth = dataBase.a;
    
    vec2 datassao = ssao(fragCoord);
    float outlineAmount = outline(uv, depth);
    
    vec4 overlay = vec4(0.0);
    overlay = blendOnto((0.15*datassao.t)*vec4(vec3(1.0), 1.0), overlay);
    overlay = blendOnto((0.75*datassao.s)*vec4(vec3(0.0), 1.0), overlay);
    overlay = blendOnto((0.4*outlineAmount) * vec4(vec3(0.0), 1.0), overlay);
    overlay *= 1.0 - glow;

    bool showOverlay = texelFetch(iChannel1, ivec2(KEY_S,0), 0).x > 0.5;
    if (showOverlay) {
        rgb = vec3(0.4);
    }
    vec3 finalRGB = blendOnto(overlay, rgb).rgb;

    float dCorner = length(uv - vec2(0.5)) * SQRT2;
    float vignetteFactor = 1.0 - mix(0.0, 0.4, smoothstep(0.3, 0.9, dCorner));
    fragColor = vec4(vignetteFactor*finalRGB, 1.0);
}
