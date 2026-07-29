// Common (common) — After... by Dave_Hoskins
// https://www.shadertoy.com/view/3sBGRt

// After...
// by David Hoskins.
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

//----------------------------------------------------------------------------------------
#define FAR 12000.
#define TAU 6.28318530718
#define SUN_COLOUR vec3(1., .7, .5)
#define FOG_COLOUR vec3(.48, .49, .53)

vec3 sunLight, crowPos;

//----------------------------------------------------------------------------------------
vec3 cameraPath( float z )
{
	return vec3(4110.+sin(z*.0004)*2500.0,
                900.0+cos(z*.00063)*600.,
                z);
}

//----------------------------------------------------------------------------------------
mat3 setCamMat( in vec3 ro, in vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

#define HASHSCALE1 .1031
#define HASHSCALE3 vec3(.1031, .1030, .0973)

//----------------------------------------------------------------------------------------
float hash11(float p)
{
	vec3 p3  = fract(vec3(p) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}
//----------------------------------------------------------------------------------------
float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

//----------------------------------------------------------------------------------------
vec2 hash22(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * HASHSCALE3);
    p3 += dot(p3, p3.yzx+19.19);
    return fract((p3.xx+p3.yz)*p3.zy);
}

//----------------------------------------------------------------------------------------
float noise( in vec2 n )
{
    vec2 p = floor(n);
    n = fract(n);
    n = n*n*(3.0-2.0*n);
    
    float res = mix(mix( hash12(p), hash12(p+vec2(1.0 ,0.0)),n.x),
                    mix( hash12(p + vec2(0.0,1.0)), hash12(p + vec2(1.0,1.0)),n.x),n.y);
    return res;
}

//----------------------------------------------------------------------------------------
vec2 noise2D( in vec2 n )
{
    vec2 p = floor(n);
    n = fract(n);
    n = n*n*(3.0-2.0*n);
    
    vec2 res = mix(mix( hash22(p), hash22(p+vec2(1.0 ,0.0)),n.x),
                    mix( hash22(p + vec2(0.0,1.0)), hash22(p + vec2(1.0,1.0)),n.x),n.y);
    return res;
}


//----------------------------------------------------------------------------------------
//Thanks iq...
float sMax(float a, float b, float s)
{
    
    float h = clamp( 0.5 + 0.5*(a-b)/s, 0., 1.);
    return mix(b, a, h) + h*(1.0-h)*s;
}