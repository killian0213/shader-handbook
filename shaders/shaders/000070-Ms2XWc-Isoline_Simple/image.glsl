// Image (image) — Isoline Simple by iapafoto
// https://www.shadertoy.com/view/Ms2XWc

// Created by sebastien durand - 2014
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

//#define MOUSE_CTRL        

//#define WITH_FWIDTH // not super constant thickness 
#define WITH_DFDXDY   // nice result

float time;

// - Bicubic --------------------------------------------------------
// [iq: https://www.shadertoy.com/view/XsSXDy]

vec4 BS_A = vec4( 3., -6.,   0.,  4. ) /  6.;
vec4 BS_B = vec4(-1.,  6., -12.,  8. ) /  6.;
vec4 powers( float x ) { return vec4(x*x*x, x*x, x, 1.); }

vec4 spline(float x, vec4 c0, vec4 c1, vec4 c2, vec4 c3 ) {
    return c0*dot( BS_B, powers(x + 1.)) + c1*dot( BS_A, powers(x      )) +
           c2*dot( BS_A, powers(1. - x)) + c3*dot( BS_B, powers(2. - x));
}
#define SAM(a,b)  texture(iChannel0, (i+vec2(a,b)+0.5)/res, -99.0)
vec4 texture_Bicubic( sampler2D tex, vec2 t) {
    vec2 res = iChannelResolution[0].xy;
    vec2 p = res*t - .5, f = fract(p), i = floor(p);
    return spline( f.y, spline( f.x, SAM(-1,-1), SAM( 0,-1), SAM( 1,-1), SAM( 2,-1)),
                        spline( f.x, SAM(-1, 0), SAM( 0, 0), SAM( 1, 0), SAM( 2, 0)),
                        spline( f.x, SAM(-1, 1), SAM( 0, 1), SAM( 1, 1), SAM( 2, 1)),
                        spline( f.x, SAM(-1, 2), SAM( 0, 2), SAM( 1, 2), SAM( 2, 2)));
}



float eval(vec2 uv) {
#ifdef MOUSE_CTRL        
    return 5. + 10.*texture_Bicubic(iChannel0, vec2(1, 0) +uv*.04).x;
#else
    return 5.*cos(iTime*.05) + 10.*texture_Bicubic(iChannel0, vec2(cos(time), sin(time)) +uv*(1.+.5*cos(iTime*.05))*.04).x;
#endif
}

// - Palette ---------------------------------------------------------
// https://www.shadertoy.com/view/4dsSzr

vec3 heatmapGradient(float t) {
	return clamp((pow(t, 1.5) * .8 + .2) * vec3(smoothstep(0., .35, t) + t * .5, smoothstep(.5, 1., t), max(1. - t * 1.7, t * 7. - 6.)), 0., 1.);
}

vec3 palette(float v) {
    return heatmapGradient(mod((v-11.)*.1,1.));
}



// - Isoline ---------------------------------------------------------
// based on article
// https://iquilezles.org/articles/distance

float isoline(float val, float lg, float ref, float pas, float tickness) {
    float v = abs(mod(val-ref+pas*.5, pas)-pas*.5)/lg - .1*tickness;
    return smoothstep(.2,.8, v);
}


// - Main ------------------------------------------------------------
void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    time = iTime *0.005;
    
	vec2 uv = fragCoord.xy / iResolution.x;
    
    float val = eval(uv);
    
#ifdef WITH_FWIDTH
    float lg = 2.*fwidth(val); // not super constant thickness 
#else 
#ifdef WITH_DFDXDY
    float lg = 2.*length(vec2(dFdx(val), dFdy(val)));
#else    
    vec3 delta = vec3(1./iResolution.xx, 0);
    vec2 grad = vec2(eval(uv+delta.xz)-eval(uv-delta.xz), eval(uv+delta.zy)-eval(uv-delta.zy)); 
    float lg = length(grad);
#endif
#endif  

    float 
#ifdef MOUSE_CTRL        
        ref = eval(iMouse.xy/iResolution.xy), // reference value
        k0 = isoline(val, lg, 1., 20., 2.),
#else 
        ref = 1.,
        k0 = 1.,
#endif    
    	k1 = isoline(val, lg, ref, .4, 1.),
    	k2 = isoline(val, lg, ref, 2., 10.);
    
    // paletize value
    vec3 col = palette(val); 

    // apply isoline to color
    col *= k0*k2; //mix(vec3(0), col, k2);
	col *= (.3+(k1*.7));
    col *= pow(30.0*uv.x*uv.y*(1.-uv.x)*(1.-uv.y),.2);
	fragColor = vec4(col,1);
}

