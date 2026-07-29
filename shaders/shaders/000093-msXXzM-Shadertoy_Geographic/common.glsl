// Common (common) — Shadertoy Geographic by iapafoto
// https://www.shadertoy.com/view/msXXzM

// Created by Sebastien Durand - 11/2022
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
//-----------------------------------------------------
// Sounds based with minor changed on
//     Dave Hoskins [Frozen wasteland] https://www.shadertoy.com/view/Xls3D2
// ------------------------------------------------------------
// Many part of shading based on 
//     iq [Bridge] https://www.shadertoy.com/view/Mds3z2
// ------------------------------------------------------------
// Penguin feets and texture bedes on
//     kuvkar [AngryBird] https://www.shadertoy.com/view/ldKXRz
// ------------------------------------------------------------

#define ZERO min(0,iFrame)

#define MOD2 vec2(.16632,.17369)
#define MOD3 vec3(.16532,.17369,.15787)


//----------------------------------------------------------------------------------------
// Dave Hoskins Hash functions
//----------------------------------------------------------------------------------------
//  1 out, 1 in ...
float hash11(float p) {
	vec2 p2 = fract(vec2(p) * MOD2);
    p2 += dot(p2.yx, p2.xy+19.19);
	return fract(p2.x * p2.y);
}

//----------------------------------------------------------------------------------------
//  2 out, 1 in...
vec2 hash21(float p) {
    vec3 p3 = fract(vec3(p) * MOD3);
    p3 += dot(p3.xyz, p3.yzx + 19.19);
    return fract(vec2(p3.x * p3.y, p3.z*p3.x));
}

float hash12( vec2 p ) {
    p  = 50.*fract( p*.3183099 );
    return fract( p.x*p.y*(p.x+p.y) );
}

//----------------------------------------------------------------------------------------
///  2 out, 2 in...
vec2 hash22(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * MOD3);
    p3 += dot(p3.zxy, p3.yxz+19.19);
    return fract(vec2(p3.x * p3.y, p3.z*p3.x));
}

// utilise pour le texture3D
vec3 noised(in vec2 x) {
    vec2 p = floor(x),
         w = fract(x),
         u = w*w*(3.-2.*w);  
    float a = hash12(p),
          b = hash12(p+vec2(1,0)),
          c = hash12(p+vec2(0,1)),
          k1 = b - a,
          k2 = c - a,
          k4 = a - b - c + hash12(p+vec2(1));
    return vec3( -1.+2.*(a + k1*u.x + k2*u.y + k4*u.x*u.y), 
                 12.*w*(1.-w) * vec2(k1 + k4*u.y, k2 + k4*u.x) );
}

float noise3D(in vec3 p){
	const vec3 s = vec3(113, 157, 1);
	vec3 ip = floor(p); 
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
	p -= ip; 
    p = p*p*(3. - 2.*p);
    h = mix(fract(sin(h)*43758.5453), fract(sin(h + s.x)*43758.5453), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    float n = mix(h.x, h.y, p.z);
    return n;
}
