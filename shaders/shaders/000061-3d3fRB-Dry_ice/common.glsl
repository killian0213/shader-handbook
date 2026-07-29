// Common (common) — Dry ice by xjorma
// https://www.shadertoy.com/view/3d3fRB

// Created by David Gallardo - xjorma/2020
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0

const float dissipation 	= 0.95;

const float ballRadius		= 0.06;
const float fogHeigth		= ballRadius * 2.;
const int	nbSlice			= 32;
const float fogSlice		= fogHeigth / float(nbSlice);
const int	nbSphere 		= 3;
const float ShadowDensity 	= 25.;
const float FogDensity 		= 20.;

const float tau =  radians(360.);


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