// Common (common) — Physarum Circular by michael0884
// https://www.shadertoy.com/view/wtKGW1

//simulation variables
#define dt 0.25
#define prad 1.4
#define decay 0.15

//cell speed
float pspeed = 7.;

//sensor distance 
float sdist = 50.;

//sensor strenght
float sst = 10.;

//sensor angle
float sangl = 0.2; //radians

#define pdens 2.
//definitions
#define size iResolution.xy
#define pixel(a, p) texture(a, p/vec2(textureSize(a,0)))
#define texel(a, p) texelFetch(a, ivec2(p-0.5), 0)
#define ch0 iChannel0
#define ch1 iChannel1
#define ch2 iChannel2
#define ch3 iChannel3
#define PI 3.14159265

//hash functions
//https://www.shadertoy.com/view/4djSRW
float hash11(float p)
{
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}


vec2 hash21(float p)
{
	vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
	p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx+p3.yz)*p3.zy);

}

vec2 hash22(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);

}


//functions
float gauss(vec2 x, float r)
{
    return exp(-pow(length(x)/r,2.));
}
   

//a rainbow colormap from Matlab
float interpolate(float val, float y0, float x0, float y1, float x1) 
{
    return (val-x0)*(y1-y0)/(x1-x0) + y0;
}

float base(float val) 
{
    if ( val <= -0.75 ) return 0.0;
    else if ( val <= -0.25 ) return interpolate( val, 0.0, -0.75, 1.0, -0.25 );
    else if ( val <= 0.25 ) return 1.0;
    else if ( val <= 0.75 ) return interpolate( val, 1.0, 0.25, 0.0, 0.75 );
    else return 0.0;
}

vec3 jet_colormap(float v)
{
    return vec3(base(v - 0.5),base(v),base(v + 0.5));
}

vec3 jet_range(float v, float a, float b)
{
    return jet_colormap(2.*clamp((v-a)/(b-a),0.,1.) - 1.);
}

//Laplacian operator
vec4 Laplace(sampler2D ch, vec2 p)
{
    vec3 dx = vec3(-1,0.,1);
    return texel(ch, p+dx.xy)+texel(ch, p+dx.yx)+texel(ch, p+dx.zy)+texel(ch, p+dx.yz)-4.*texel(ch, p);
}

//Gradient
vec2 Grad(sampler2D ch, vec2 p)
{
    vec3 dx = vec3(-1,0.,1);
    return vec2(length(texel(ch, p+dx.zy)),length(texel(ch, p+dx.yz))) - length(texel(ch, p));
}
