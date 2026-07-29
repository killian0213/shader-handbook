// Common (common) — 3D Monte Carlo Geometry test by rreusser
// https://www.shadertoy.com/view/wdffWj

// Color functions from: https://www.shadertoy.com/view/wt23Rt

//Hue to RGB (red, green, blue).
//Source: https://github.com/tobspr/GLSL-Color-Spaces/blob/master/ColorSpaces.inc.glsl
#define saturate(v) clamp(v,0.,1.)

//HSV (hue, saturation, value) to RGB.
//Sources: https://gist.github.com/yiwenl/745bfea7f04c456e0101, https://gist.github.com/sugi-cho/6a01cae436acddd72bdf
vec3 hsv2rgb(vec3 c){
	vec4 K=vec4(1.,2./3.,1./3.,3.);
	return c.z*mix(K.xxx,saturate(abs(fract(c.x+K.xyz)*6.-K.w)-K.x),c.y);
}

//RGB to HSV.
//Source: https://gist.github.com/yiwenl/745bfea7f04c456e0101
vec3 rgb2hsv(vec3 c) {
	float cMax=max(max(c.r,c.g),c.b),
	      cMin=min(min(c.r,c.g),c.b),
	      delta=cMax-cMin;
	vec3 hsv=vec3(0.,0.,cMax);
	if(cMax>cMin){
		hsv.y=delta/cMax;
		if(c.r==cMax){
			hsv.x=(c.g-c.b)/delta;
		}else if(c.g==cMax){
			hsv.x=2.+(c.b-c.r)/delta;
		}else{
			hsv.x=4.+(c.r-c.g)/delta;
		}
		hsv.x=fract(hsv.x/6.);
	}
	return hsv;
}




//------------------------------------------------------------------

float sdPlane( vec3 p ) {
	return p.y;
}

float sdTorus( vec3 p, vec2 t ) {
    return length( vec2(length(p.xz)-t.x,p.y) )-t.y;
}

//------------------------------------------------------------------

vec2 opU( vec2 d1, vec2 d2 ) {
	return (d1.x<d2.x) ? d1 : d2;
}

vec2 opD( vec2 d1, vec2 d2 ) {
	return (d1.x>=d2.x) ? d1 : d2;
}

// exponential smooth min (k = 32);
float smin( float a, float b, float k ) {
    float res = exp2( -k*a ) + exp2( -k*b );
    return -log2( res )/k;
}

// exponential smooth min (k = 32);
vec2 smin( vec2 a, vec2 b, float k ) {
    vec2 res = exp2( -k*a ) + exp2( -k*b );
    return -log2( res )/k;
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr ) {
	vec3 cw = normalize(ta - ro);
	vec3 cp = vec3(sin(cr), cos(cr), 0.0);
	vec3 cu = normalize(cross(cw, cp));
	vec3 cv = (cross(cu, cw));
    return mat3(cu, cv, cw);
}


