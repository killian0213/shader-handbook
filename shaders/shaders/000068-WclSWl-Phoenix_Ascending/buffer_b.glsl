// Buffer B (buffer) — Phoenix Ascending by igneus
// https://www.shadertoy.com/view/WclSWl

// *******************************************************************************************************
//   Hovering hawk encoded as MLP
// *******************************************************************************************************

#define z4 vec4(0)
#define m4 mat4
#define v4 vec4
#define kNNInputWidth 12
#define kNNInputBlocks ((kNNInputWidth + 3) / 4)
#define kNNOutputWidth 1
#define kNumHarmonics 2
#define kInputDimensions 3
#define kW (2 * kInputDimensions * kNumHarmonics)

vec4[kNNInputBlocks] FourierEncode(in vec3 p, in vec3 weights)
{
    vec4[kNNInputBlocks] v;
    for (int harmonic = 0; harmonic < kNumHarmonics; ++harmonic)
    {
        for (int d = 0; d < 2 * kInputDimensions; ++d)
        {
            int i = 2 * kInputDimensions * harmonic + d;
            v[i>>2][i&3] = sin( kPi * float(1 + harmonic) * p[d >> 1] + kHalfPi * float(d & 1)) * weights[d >> 1];
        }
    }
    return v;
}  

float Sigmoid(vec4 v)
{
    return dot(vec4(1), 1. / (1. + exp(-(v * 50.))));
}

vec2 EvaluateMLP(vec3 uvt)
{
   uvt.z = mix(-1., 1., uvt.z);
   vec4[3] I = FourierEncode(uvt, vec3(1., 1., 0.5));   
   
   v4[3] A0; v4[3] A1; v4[3] A2; float A3, code = 0.;
   
   A0[0] = m4(0.332,0.179,0.157,-0.519,0.064,-0.557,0.012,-0.304,0.252,0.358,0.302,0.248,0.373,-0.461,0.661,0.027) * I[0] + 
   m4(0.312,0.108,-0.527,0.767,0.243,-0.187,-1.250,-0.514,0.181,-0.336,-0.023,0.332,0.004,0.025,-0.192,0.103) * I[1] + 
   m4(-0.041,0.282,-0.766,-0.095,0.084,-0.109,0.074,-0.109,0.150,-0.250,0.069,-0.168,-0.048,-0.303,0.499,0.039) * I[2] + v4(0.569,-0.328,0.322,0.101);code += Sigmoid( A0[0]);
 A0[0] *= mix(v4(1e-2), v4(1), step(v4(0),  A0[0]));
   A0[1] = m4(-0.244,-0.572,0.317,0.422,0.569,0.175,0.138,0.356,0.752,-0.380,0.695,-0.504,0.188,0.562,-0.297,-0.242) * I[0] + 
   m4(0.638,-0.614,0.097,-0.042,1.271,-0.882,0.946,0.625,0.150,0.161,-0.009,-0.179,-0.382,-0.260,-0.090,-0.001) * I[1] + 
   m4(-0.347,-0.122,0.058,0.118,-0.028,-0.043,0.159,-0.410,0.211,0.026,0.025,-0.209,0.072,-0.341,0.034,0.546) * I[2] + v4(0.012,-0.130,-0.490,0.140);code += Sigmoid( A0[1]);
 A0[1] *= mix(v4(1e-2), v4(1), step(v4(0),  A0[1]));
   A0[2] = m4(-0.763,0.156,0.266,0.812,-0.017,0.165,-0.340,-0.629,-0.371,-0.071,-0.155,-0.687,-0.611,0.360,0.179,0.084) * I[0] + 
   m4(-0.303,0.380,0.287,-0.276,0.189,0.093,-0.212,-0.205,0.182,-0.278,-0.160,0.056,0.141,-0.047,0.609,0.459) * I[1] + 
   m4(0.440,0.246,-0.029,0.285,-0.180,-0.318,0.108,0.028,-0.253,-0.273,-0.112,0.065,0.255,0.245,-0.044,-0.074) * I[2] + v4(0.215,0.612,-0.817,-0.591);code += Sigmoid( A0[2]);
 A0[2] *= mix(v4(1e-2), v4(1), step(v4(0),  A0[2]));
   A1[0] = m4(-0.602,0.111,-0.229,-0.184,-0.077,0.177,-0.389,0.192,-0.380,-0.010,0.058,-0.031,-1.074,0.431,0.339,-0.108) * A0[0] + 
   m4(-0.780,-0.047,-0.223,0.533,-0.128,0.352,0.748,-0.238,-1.078,-0.409,0.426,0.721,-0.055,0.472,0.338,-0.158) * A0[1] + 
   m4(-0.236,0.335,-0.088,-0.243,-0.161,-0.661,-0.356,0.315,0.877,-0.632,-0.408,-0.712,0.374,-0.328,-0.168,-1.506) * A0[2] + v4(0.080,0.493,0.601,-0.400);code += Sigmoid( A1[0]);
 A1[0] *= mix(v4(1e-2), v4(1), step(v4(0),  A1[0]));
   A1[1] = m4(0.165,-0.108,0.423,0.358,-0.177,0.491,0.215,-0.097,0.686,0.671,-0.097,0.158,-0.256,0.235,-0.062,0.152) * A0[0] + 
   m4(-0.565,0.016,0.199,0.785,0.014,-0.649,-0.467,-0.604,0.903,1.419,0.425,-0.995,0.050,0.184,0.475,0.287) * A0[1] + 
   m4(-0.141,0.706,0.431,-0.219,0.260,-0.155,0.146,-0.064,0.626,-0.389,0.399,-0.317,0.361,0.185,-0.628,-0.223) * A0[2] + v4(-0.300,-0.259,-0.017,-0.170);code += Sigmoid( A1[1]);
 A1[1] *= mix(v4(1e-2), v4(1), step(v4(0),  A1[1]));
   A1[2] = m4(-0.917,-0.322,0.473,0.343,0.056,0.087,-0.367,-0.565,-0.396,-0.243,-0.374,0.259,0.642,0.047,-0.144,0.039) * A0[0] + 
   m4(0.166,-0.142,0.286,-0.365,0.187,0.516,0.284,-0.571,-0.287,0.099,-0.985,-0.600,-2.283,0.317,-0.417,-0.094) * A0[1] + 
   m4(-0.089,-0.077,-0.138,-0.739,-0.111,-0.310,0.378,0.091,1.814,-0.207,0.600,0.752,-0.070,0.937,0.073,0.335) * A0[2] + v4(-0.680,0.415,0.336,0.504);code += Sigmoid( A1[2]);
 A1[2] *= mix(v4(1e-2), v4(1), step(v4(0),  A1[2]));
   A2[0] = m4(-0.188,-0.070,0.745,0.810,-0.195,-0.802,0.328,0.080,-0.372,-0.035,0.638,0.110,-0.606,0.269,1.047,0.887) * A1[0] + 
   m4(0.269,0.213,-1.139,-0.505,-0.728,-0.508,0.316,0.428,-0.609,0.512,0.009,0.218,0.582,-0.346,-1.039,-0.728) * A1[1] + 
   m4(0.726,-0.603,-0.777,0.820,-0.450,0.546,-0.746,-0.411,-0.032,-0.245,-0.713,-0.341,-0.250,0.621,0.525,0.181) * A1[2] + v4(0.579,-0.154,0.475,0.530);code += Sigmoid( A2[0]);
 A2[0] *= mix(v4(1e-2), v4(1), step(v4(0),  A2[0]));
   A2[1] = m4(-0.392,0.342,0.009,-0.525,-0.594,-0.885,0.272,-0.480,-0.616,0.014,0.032,-0.075,-0.280,0.287,0.887,-0.135) * A1[0] + 
   m4(0.144,0.480,-0.106,-0.037,-0.294,0.051,0.470,0.571,0.015,-0.062,-0.188,0.391,0.753,-0.308,-0.802,0.609) * A1[1] + 
   m4(1.073,0.212,3.231,-0.080,0.434,-0.521,-0.246,0.289,0.448,-0.102,0.352,-0.088,-0.025,-0.380,0.037,0.062) * A1[2] + v4(-0.169,-0.083,-0.241,0.554);code += Sigmoid( A2[1]);
 A2[1] *= mix(v4(1e-2), v4(1), step(v4(0),  A2[1]));
   A2[2] = m4(-0.483,0.117,0.097,0.205,-0.461,-0.377,0.071,0.091,-0.584,-0.551,-0.509,0.512,-0.909,0.300,0.309,0.610) * A1[0] + 
   m4(0.244,0.261,-0.146,-0.794,0.016,0.207,-0.684,0.449,0.234,-0.090,0.500,0.003,0.399,-0.321,0.327,-0.447) * A1[1] + 
   m4(0.149,-0.362,-0.190,0.316,0.411,0.219,-0.459,-0.340,0.405,0.362,-0.011,-0.376,-0.046,0.335,-0.416,0.441) * A1[2] + v4(0.003,-0.081,-0.560,0.403);code += Sigmoid( A2[2]);
 A2[2] *= mix(v4(1e-2), v4(1), step(v4(0),  A2[2]));
   A3 =dot(v4(-0.756,-0.544,-0.686,0.495), A2[0]) + dot(v4(-0.366,0.757,-0.237,-0.367), A2[1]) + dot(v4(-0.334,-0.315,0.700,0.722), A2[2]) + 0.918;
   
   return vec2(A3, code);
}
#undef z4
#undef m4
#undef v4
#undef kNNInputWidth
#undef kNNOutputWidth

float EvaluateHead(vec2 p, float time)
{
    vec2 v0 = vec2(0., mix(0.075, 0.085, sin01(kTwoPi * (0.2 + time))));
    vec2 v1 = vec2(0., -0.25);    
    v1 -= v0;
    float t = saturate((dot(p, v1) - dot(v0, v1)) / dot(v1, v1));
    vec2 perp = v0 + t * v1;
    return (length(p - perp) - 0.065) / 0.15;
}

vec3 EvaluateBody(vec2 uv, float time)
{
    float head = EvaluateHead(uv, time);
    
    uv.x = mix(-1., 1., 1. - abs(uv.x) - 0.015) * 0.9;
    uv.y *= 2. * 0.9;
    
    if(cwiseMax(abs(uv)) > 0.9) { return vec3(1); }
    
    #define kDeltaT 1e-3
    vec3 f;
    f.xy = EvaluateMLP(vec3(uv, time));
    f.z = (EvaluateMLP(vec3(uv, time + kDeltaT)).x - f.x) / kDeltaT;
    
    // x: field value, y: accumulated activations, z: temporal differential dF/dt
    return vec3(min(head, f.x), f.yz);
}

void mainImage( out vec4 rgbaFrag, in vec2 xyFrag )
{        
    xyFrag /= kHawkScale;
    
    rgbaFrag *= 0.;
    
    vec2 xyView = ScreenToNormalisedScreen(xyFrag, iResolution.xy);
        
    //rgbaFrag.xy = uv;
    
    /*float posTime = kTime * .3;
    int interval = int(posTime);
    vec2[4] knots;
    for(int i = 0; i < 4; ++i)
    {    
        RNGCtx rng = PCGInitialise(HashOf(uint(interval + i)));
        knots[i] = mix(vec2(-1.), vec2(1.), Rand4(rng).xy) * 0.1;
    }
    
    vec4 p = EvaluateCatmullRom(knots[0], knots[1], knots[2], knots[3], fract(posTime));
    
    float theta = p.w * 0.1;
    xyView *= RotMat2(theta);
    
    xyView += p.xy;*/
    
    //phase += 0.005 * sin01(10. * kTwoPi * fract(time));
    
    //float theta = mix(-1., 1., sin01(5.5 * iTime)) * 0.05;    
    //xyView *= RotMat2(theta);
    //xyView.x += mix(-1., 1., cos01(2.5 * iTime)) * -0.2;
    //xyView.y += mix(0., -1., sin01(2.5 * iTime)) * -0.1;
        
    #define kGlidePose 0.45
    vec4 hawkCtx = GetHawkHoverCtx(kTime);
    vec3 f = EvaluateBody(xyView, fract(hawkCtx.z + kGlidePose));
    
    float outline = saturate(1. - abs(f.x) * 20.);
    float mask = max(outline, 1. - step(0., f.x));
    
    float features = 0.;   
    
    // Eyes
    xyView.x = abs(xyView.x);
    float headBob = 0.015 * sin01(kTwoPi * (0.2 + hawkCtx.z));
    float blink = saturate(sin01(kTime * 2.) * 50.);
    features = mix(features, 1., SDFEllipse(xyView, vec2(0.032, 0.065 + headBob), vec2(0.6 * blink, 1.) * 0.007, 0.9, 1.5 / iResolution.y));
    
    // Beak
    xyView.y = xyView.y - headBob - 0.017;
    features = mix(features, 0.7, saturate(1. - sqr(xyView.y / 0.015)) * SDFLine(xyView, vec2(0.005, 0.015), vec2(0.0, 0.), 0.003, 1. / iResolution.y));
   
    rgbaFrag.x = sin(2. * f.y) * mask;
    rgbaFrag.y = 0.5 * f.z * mask;
    rgbaFrag.z = features;
    rgbaFrag.w = mask;
        
}