// Buffer D (buffer) — Iridescent Car Paint by piyushslayer
// https://www.shadertoy.com/view/mdSyWd

/**
    Contrast Adaptive Sharpening pass based on AMD's FidelityFx library to recover some
    of the car paint microdetails after TAA (only if TAA is enabled).  
*/

#ifdef CAS_FILTER
    #define CAS_BETTER_DIAGONALS
    #define FSR_CAS_DENOISE
    #define CAS_GO_SLOWER
    #define CAS_SLOW
#endif

const float SHARPNESS = 0.8;

float APrxLoRcpF1(in float a)
{
    return uintBitsToFloat(uint(0x7ef07ebb) - floatBitsToUint(a));
}

float APrxLoSqrtF1(in float a)
{
    return uintBitsToFloat((floatBitsToUint(a) >> 1u) + uint(0x1fbc4639));
}

float APrxMedRcpF1(in float a)
{
    float b = uintBitsToFloat(uint(0x7ef19fff) - floatBitsToUint(a));
    return b * ( -b * a + 2.0);
}

vec3 CasLoad(in ivec2 pixelCoord)
{
    return texelFetch(iChannel0, pixelCoord, 0).xyz;
}

uvec4 CasSetup(in float sharpness)
{
    uvec4 result;
    float sharp = -1.0 / mix(8.0, 5.0, Saturate(sharpness));
    vec2 hSharp = vec2(sharp);
    result.x = floatBitsToUint(sharp);
    result.y = packHalf2x16(hSharp);
    result.z = floatBitsToUint(8.0);
    result.w = 0u;
    
    return result;
}

void CasFilter(inout vec3 color, in ivec2 pixelCoord, in uvec4 casParams)
{
    vec3 a = CasLoad(pixelCoord + ivec2(-1,-1));
    vec3 b = CasLoad(pixelCoord + ivec2( 0,-1));
    vec3 c = CasLoad(pixelCoord + ivec2( 1,-1));
    vec3 d = CasLoad(pixelCoord + ivec2(-1, 0));
    vec3 e = CasLoad(pixelCoord);
    vec3 f = CasLoad(pixelCoord + ivec2( 1, 0));
    vec3 g = CasLoad(pixelCoord + ivec2(-1, 1));
    vec3 h = CasLoad(pixelCoord + ivec2( 0, 1));
    vec3 i = CasLoad(pixelCoord + ivec2( 1, 1));
    
    // Soft min and max.
    //  a b c             b
    //  d e f * 0.5  +  d e f * 0.5
    //  g h i             h
    float mnR = Min3(Min3(d.r, e.r, f.r), b.r, h.r);
    float mnG = Min3(Min3(d.g, e.g, f.g), b.g, h.g);
    float mnB = Min3(Min3(d.b, e.b, f.b), b.b, h.b);
    
#ifdef CAS_BETTER_DIAGONALS
    float mnR2 = Min3(Min3(mnR, a.r, c.r), g.r, i.r);
    float mnG2 = Min3(Min3(mnG, a.g, c.g), g.g, i.g);
    float mnB2 = Min3(Min3(mnB, a.b, c.b), g.b, i.b);
    mnR = mnR + mnR2;
    mnG = mnG + mnG2;
    mnB = mnB + mnB2;
#endif

    float mxR = Saturate(Max3(Max3(d.r, e.r, f.r), b.r, h.r));
    float mxG = Saturate(Max3(Max3(d.g, e.g, f.g), b.g, h.g));
    float mxB = Saturate(Max3(Max3(d.b, e.b, f.b), b.b, h.b));
    
#ifdef CAS_BETTER_DIAGONALS
    float mxR2 = Saturate(Max3(Max3(mxR, a.r, c.r), g.r, i.r));
    float mxG2 = Saturate(Max3(Max3(mxG, a.g, c.g), g.g, i.g));
    float mxB2 = Saturate(Max3(Max3(mxB, a.b, c.b), g.b, i.b));
    mxR = mxR + mxR2;
    mxG = mxG + mxG2;
    mxB = mxB + mxB2;
#endif

// Smooth minimum distance to signal limit divided by smooth max.
#ifdef CAS_GO_SLOWER
    float rcpMR = 1.0 / mxR;
    float rcpMG = 1.0 / mxG;
    float rcpMB = 1.0 / mxB;
#else
    float rcpMR = APrxLoRcpF1(mxR);
    float rcpMG = APrxLoRcpF1(mxG);
    float rcpMB = APrxLoRcpF1(mxB);
#endif
#ifdef CAS_BETTER_DIAGONALS
    float ampR = Saturate(min(mnR, 2.0 - mxR) * rcpMR);
    float ampG = Saturate(min(mnG, 2.0 - mxG) * rcpMG);
    float ampB = Saturate(min(mnB, 2.0 - mxB) * rcpMB);
#else
    float ampR = Saturate(min(mnR, 1.0 - mxR) * rcpMR);
    float ampG = Saturate(min(mnG, 1.0 - mxG) * rcpMG);
    float ampB = Saturate(min(mnB, 1.0 - mxB) * rcpMB);
#endif

// Shaping amount of sharpening.
#ifdef CAS_GO_SLOWER
    ampR = sqrt(ampR);
    ampG = sqrt(ampG);
    ampB = sqrt(ampB);
#else
    ampR = APrxLoSqrtF1(ampR);
    ampG = APrxLoSqrtF1(ampG);
    ampB = APrxLoSqrtF1(ampB);
#endif

    // Filter shape.
    //  0 w 0
    //  w 1 w
    //  0 w 0
    float peak = uintBitsToFloat(casParams.x);

#ifdef FSR_CAS_DENOISE
    // Luma times 2.
    float bL = b.b * 0.5 + (b.r * 0.5 + b.g);
    float dL = d.b * 0.5 + (d.r * 0.5 + d.g);
    float eL = e.b * 0.5 + (e.r * 0.5 + e.g);
    float fL = f.b * 0.5 + (f.r * 0.5 + f.g);
    float hL = h.b * 0.5 + (h.r * 0.5 + h.g);
    
    // Noise detection.
    float nz = 0.25 * bL + 0.25 * dL + 0.25 * fL + 0.25 * hL - eL;
    nz = Saturate(abs(nz) * APrxMedRcpF1(Max3(Max3(bL, dL, eL), fL, hL) - Min3(Min3(bL, dL, eL), fL, hL)));
    nz = 1.0 - 0.5 * nz;
    peak *= nz;
#endif

    float wR = ampR * peak;
    float wG = ampG * peak;
    float wB = ampB * peak;
    
    // Filter.
#ifndef CAS_SLOW
    // Using green coef only, depending on dead code removal to strip out the extra overhead.
#ifdef CAS_GO_SLOWER
    float rcpWeight = 1.0 / (1.0 + 4.0 * wG);
#else
    float rcpWeight = APrxMedRcpF1(1.0 + 4.0 * wG);
#endif
    color.r = (b.r * wG + d.r * wG + f.r * wG + h.r * wG + e.r) * rcpWeight;
    color.g = (b.g * wG + d.g * wG + f.g * wG + h.g * wG + e.g) * rcpWeight;
    color.b = (b.b * wG + d.b * wG + f.b * wG + h.b * wG + e.b) * rcpWeight;
#else
#ifdef CAS_GO_SLOWER
    float rcpWeightR = 1.0 / (1.0 + 4.0 * wR);
    float rcpWeightG = 1.0 / (1.0 + 4.0 * wG);
    float rcpWeightB = 1.0 / (1.0 + 4.0 * wB);
#else
    float rcpWeightR = APrxMedRcpF1(1.0 + 4.0 * wR);
    float rcpWeightG = APrxMedRcpF1(1.0 + 4.0 * wG);
    float rcpWeightB = APrxMedRcpF1(1.0 + 4.0 * wB);
#endif
    color.r = (b.r * wR + d.r * wR + f.r * wR + h.r * wR + e.r) * rcpWeightR;
    color.g = (b.g * wG + d.g * wG + f.g * wG + h.g * wG + e.g) * rcpWeightG;
    color.b = (b.b * wB + d.b * wB + f.b * wB + h.b * wB + e.b) * rcpWeightB;
#endif
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    ivec2 pixelCoord = ivec2(fragCoord);
    vec4 outColor = texelFetch(iChannel0, pixelCoord, 0);

#ifdef CAS_FILTER
    uvec4 casParams = CasSetup(SHARPNESS);
    CasFilter(outColor.xyz, pixelCoord, casParams);
#endif

    fragColor = outColor;
}