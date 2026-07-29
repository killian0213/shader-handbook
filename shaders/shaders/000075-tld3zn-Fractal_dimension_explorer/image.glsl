// Image (image) — Fractal dimension explorer by michael0884
// https://www.shadertoy.com/view/tld3zn

// Fork of "Path marching experimental" by michael0884. https://shadertoy.com/view/tdGSRd
// 2019-12-04 22:16:41

// Fork of "Path marching - sky illumination" by None. https://shadertoy.com/view/-1
// 2019-11-26 00:05:56

/// USE WASD TO MOVE AROUND

float sqr(float x)
{
    return x*x;
}

float sdist(vec3 a, vec3 b, float r)
{
    vec3 d = a-b;
    return dot(d,d)/(sqr(r)+1e-6);
}

vec4 sample_radius(vec2 pos, float lod)
{
    vec4 res = vec4(0.);
    float R = exp2(lod)/iResolution.x;
    float norm = 0.;
    for(float i = -2.; i <= 2.; i++)
    {
        for(float j = -2.; j <= 2.; j++)
        {
            float k = 1./(1. + dot(vec2(i,j),vec2(i,j)));
            res += texture(iChannel2, pos+vec2(i,j)*R, lod)*k;
            norm += k;
        }
    }
    return res/norm;
}

//cheap bloom
vec4 mip_bloom(vec2 pos, float exposure)
{
    vec4 fcol = vec4(0.);
    for(float i = 0.; i<4.; i+=1.)
    {
        fcol += pow(abs(sample_radius(pos, i)),vec4(2.));
    }
    return fcol*exposure;
}

const vec3 msat = vec3(.3,.3,.3);
const float msdiv = .12;
vec3 saturate( vec3 v ) {
  // https://www.shadertoy.com/view/Wtt3R8
  float sv = dot(v,msat);
  vec3 hs = v/sv*msdiv;
  float ls = (1.-exp(-sv))*.9;
  float s = 1.-exp(-sv*sv/10.);
  vec3 hs2 = mix(hs,vec3(1),s);
  return ls*hs2/mix(msdiv,1.,s);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pos = fragCoord/iResolution.xy;
   
    #ifdef AUTOEXPOSURE
    	float avg_ill = length(texture(iChannel2, pos, log2(max(iResolution.x, iResolution.y))).xyz);
    	float exposure = 1.6*pow(abs(avg_ill+1e-5), -1.);
    #else
    	float exposure = 10.;
    #endif
    
    vec4 c = texture(iChannel2, pos) + BLOOM*mip_bloom(pos, exposure);
    vec3 col = c.xyz;
    

    
    ///tonemapping
    //col*=.3;
    //col=vec3(dot(col,vec3(.2126,.7152,.0722))); // grey luminance test
    //col = (1. - exp(-exposure*col))*.9; // exactly matches saturate(expos*col) for colorless input.
    col = saturate(exposure*col);
    fragColor.xyz = pow(col,vec3(1./2.2));
}