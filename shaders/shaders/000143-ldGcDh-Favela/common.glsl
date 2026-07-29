// Common (common) — Favela by duvengar
// https://www.shadertoy.com/view/ldGcDh


// hash2 taken from Dave Hoskins https://www.shadertoy.com/view/4djSRW
float hash2(vec2 p)
{
    
	vec3 p3  = fract(vec3(p.xyx) * .2831);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}


///// NOISE /////
float hash(float n) {
    return fract(sin(n)*43758.5453123);   
}

float noise(in vec2 x) {
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    float n = p.x + p.y * 57.0;
    return mix(mix(hash(n + 0.0), hash(n + 1.0), f.x), mix(hash(n + 57.0), hash(n + 58.0), f.x), f.y);
}

////// FBM ////// 
// see iq // https://www.shadertoy.com/view/lsfGRr

mat2 m = mat2( 0.6, 0.6, -0.6, 0.8);
float fbm(vec2 p){
 
    float f = 0.0;
    f += 0.5000 * noise(p); p *= m * 2.02;
    f += 0.2500 * noise(p); p *= m * 2.03;
    f += 0.1250 * noise(p); p *= m * 2.01;
    f += 0.0625 * noise(p); p *= m * 2.04;
    f /= 0.9375;
    return f;
}


vec4 someFunction( vec4 a, float b )
{
    return a+b;
}
/////////////////////////////////////////////////////////////////////
// iq's cosine palette function
vec3 palette( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}