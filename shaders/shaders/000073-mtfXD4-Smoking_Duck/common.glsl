// Common (common) — Smoking Duck by xjorma
// https://www.shadertoy.com/view/mtfXD4

// Created by David Gallardo - xjorma/2023
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0

const float dissipation 	= 0.95;

const float ballRadius		= 0.09;
const float fogHeigth		= ballRadius * 3.;
const int	nbSlice			= 24;
const float fogSlice		= fogHeigth / float(nbSlice);
const int	nbSphere 		= 1;
const float shadowDensity 	= 15.;
const float fogDensity 		= 5.;
const float lightHeight     = 2.0;
const float waterHeight     = 0.2;
const float waterScale      = 0.025;
const float duckScale       = 0.25;
const vec3  lightPos        = vec3(0.5, lightHeight, 0.5);

const float tau =  radians(360.0);
const float pi =  radians(180.0);


// https://www.shadertoy.com/view/4djSRW

float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec4 hash41(float p)
{
	vec4 p4 = fract(vec4(p) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
    
}

vec2 rotate(float angle, float radius)
{
    return vec2(cos(angle),-sin(angle)) * radius;
}

bool floorIntersect(in vec3 ro, in vec3 rd, in float floorHeight, out float t) 
{
    ro.y -= floorHeight;
    if(rd.y < -0.01)
    {
        t = ro.y / - rd.y;
        return true;
    }
    return false;
} 

// https://iquilezles.org/articles/intersectors

vec2 sphIntersect( in vec3 ro, in vec3 rd, in vec3 ce, float ra )
{
    vec3 oc = ro - ce;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - ra*ra;
    float h = b*b - c;
    if( h<0.0 ) return vec2(-1.0); // no intersection
    h = sqrt( h );
    return vec2( -b-h, -b+h );
}


// https://iquilezles.org/articles/boxfunctions

vec2 boxIntersection( in vec3 ro, in vec3 rd, in vec3 rad, in vec3 center,out vec3 oN ) 
{
    ro -= center;
    vec3 m = 1.0/rd;
    vec3 n = m*ro;
    vec3 k = abs(m)*rad;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;

    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
	
    if( tN>tF || tF<0.0) return vec2(-1.0); // no intersection
    
    oN = -sign(rd)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);

    return vec2( tN, tF );
}


vec2 duckPosition(int frame, float aspectRatio)
{
    float fframe = float(frame);
    float s = 0.02;
    return vec2(cos(fframe * s * 0.5) * aspectRatio, sin(fframe * s)) * 0.7;
}


float dist2(vec3 v)
{
    return dot(v, v);
}

// Box SDF by IQ https://iquilezles.org/articles/distfunctions/distfunctions.htm
float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

// Duck model from Jimmi: https://www.shadertoy.com/view/4lsSDl

float duckBody(vec3 p) {
    float k = 6.0;
    float a = 0.;
    
    //p.x = abs(p.x);
    
    a += exp(-k * sdSphere(p + vec3(0.11, 0, 0.1), 0.06));
    a += exp(-k * sdSphere(p + vec3(-0.11, 0, 0.1), 0.06));
    a += exp(-k * sdSphere(p + vec3(0.2, 0, 0.3), 0.1));
    a += exp(-k * sdSphere(p + vec3(-0.2, 0, 0.3), 0.1));
    a += exp(-k * sdSphere(p + vec3(0.2, 0, 0.55), 0.07));
    a += exp(-k * sdSphere(p + vec3(-0.2, 0, 0.55), 0.07));
    a += exp(-k * sdSphere(p + vec3(-0.00, 0, 0.72), 0.1));
    
    a += exp(-k * sdSphere(p + vec3(0, -0.39, 0.8), 0.01));

    a += exp(-k * sdSphere(p + vec3(0, -0.7, 0.1), 0.15));
    a += exp(-k * sdSphere(p + vec3(0, -0.65, -0.05), 0.07));

    return -log(a) / k;
}

float beak(vec3 p, float s)
{
    float k = max(length(p)-s, -(length(p+vec3(-0.15,-0.2,-0.1))-0.25));
    k = max(k, -(length(p+vec3(0.12,-0.2,-0.1))-0.25));
    return k < 0.0 ? 0.0 : k;
}

float duckBeak(vec3 p)
{
    float k = 12.0;
    float a = 0.;
    
    a += exp(-k * beak(p + vec3(0, -0.55, -0.1), 0.15));

    return -log(a) / k;
}

float duckMap(in vec3 p)
{
    p /= duckScale;
    return min(duckBody(p), duckBeak(p)) * duckScale;
}


vec4 nearest(vec4 d1, vec4 d2)
{
    return (d1.x<d2.x) ? d1 : d2;
}

vec4 duckMapColor(vec3 p)
{
    p /= duckScale;
    p.x = abs(p.x);
    vec4 res = vec4(duckBody(p), vec3(1, 1, 0));
    res = nearest(res, vec4(duckBeak(p), vec3(1, 0, 0)));
    res = nearest(res, vec4(sdSphere(p-vec3(0.09, 0.62, 0.14), 0.06), vec3(0.0, 0, 0.3)));
    res.x *= duckScale;
    return res;
}

#define NORMALFUNC(NAME, MAPFUNC, EPS)								\
vec3 NAME(in vec3 p)								    			\
{                                                                   \
    const vec2 k = vec2(EPS,-EPS);				                    \
    return normalize( k.xyy * MAPFUNC(p + k.xyy) + 			    	\
                      k.yyx * MAPFUNC(p + k.yyx) + 				    \
                      k.yxy * MAPFUNC(p + k.yxy) + 				    \
                      k.xxx * MAPFUNC(p + k.xxx) );				    \
}

NORMALFUNC(calcNormalDuck,duckMap, 0.0001)

// Fog by IQ https://iquilezles.org/articles/fog

vec3 applyFog( in vec3  rgb, vec3 fogColor, in float distance)
{
    float fogAmount = exp( -distance );
    return mix( fogColor, rgb, fogAmount );
}