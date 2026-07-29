// Common (common) — Vortex Swirl Heightmap by Shane
// https://www.shadertoy.com/view/WXt3Rn

#define TAU 6.2831853
#define PI 3.14159265
 
 
float tm;

 // Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21(vec2 f){
    uvec2 p = floatBitsToUint(f + 16384.);
    p = 1664525U*(p>>1U^p.yx);
    return float(1103515245U*(p.x^(p.y>>3U)))/float(0xffffffffU);
}
 

// Dave's hash function. More reliable with large values, but will still eventually 
// break down.
//
// Hash without Sine.
// Creative Commons Attribution-ShareAlike 4.0 International Public License.
// Created by David Hoskins.
// vec3 to vec3.
vec3 hash33G(vec3 p){

    
    //p = mod(p, gSc);
    
	p = fract(p * vec3(.10313, .10307, .09731));
    p += dot(p, p.yxz + 19.1937);
    p = fract((p.xxy + p.yxx)*p.zyx)*2. - 1.;
    return p;
   
    /*
    // Note the "mod" call. Slower, but ensures accuracy with large time values.
    mat2  m = rot2(mod(iTime, 6.2831853));	
	p.xy = m * p.xy;//rotate gradient vector
    p.yz = m * p.yz;//rotate gradient vector
    //p.zx = m * p.zx;//rotate gradient vector
	return p;
    */

}

// Gradient noise.
float gradN3D( in vec3 p ){

    // Used as shorthand to write things like vec3(1, 0, 1) in the short form, e.yxy. 
    const vec2 e = vec2(0, 1);
    
    // Break space into cube cells to produce the position 
    // based ID and local coordinates.
    vec3 i = floor(p); p -= i;

    #if 1
    // quintic interpolant
    vec3 u = p*p*p*(p*(p*6. - 15.) + 10.);
    #else
    // cubic interpolant
    vec3 u = p*p*(3. - 2.*p);
    #endif 
    
   
    const mat4x2 v = mat4x2(vec2(0), vec2(0, 1), vec2(1, 0), vec2(1));
    vec4 a, b, h;
    for(int j = 0; j<4; j++){
        
        a.x = dot(hash33G(i + vec3(v[j], 0)), p - vec3(v[j], 0)); // Front.
        b.x = dot(hash33G(i + vec3(v[j], 1)), p - vec3(v[j], 1)); // Back.
        a = a.yzwx; b = b.yzwx;
    }
    
    // Interpolate between the front and back plane vertex gradient-based values.
    h = mix(a, b, u.z);
    // Interpolate the results between the bottom and top.
    h.xy = mix(h.xz, h.yw, u.y);
    // Finally, interpolate from left to right, then normalize.
    return mix(h.x, h.y, u.x)*.5 + .5;
    
    /*
    
    float c = mix( mix( mix( dot( hash33G( i + e.xxx ), p - e.xxx ), 
                          dot( hash33G( i + e.yxx ), p - e.yxx ), u.x),
                     mix( dot( hash33G( i + e.xyx ), p - e.xyx ), 
                          dot( hash33G( i + e.yyx ), p - e.yyx ), u.x), u.y),
                mix( mix( dot( hash33G( i + e.xxy ), p - e.xxy ), 
                          dot( hash33G( i + e.yxy ), p - e.yxy ), u.x),
                     mix( dot( hash33G( i + e.xyy ), p - e.xyy ), 
                          dot( hash33G( i + e.yyy ), p - e.yyy ), u.x), u.y), u.z );
    return c*.5 + .5;                      
    */
}


// Smooth fract function.
float sFract(float x, float sf){
   
    x = fract(x);
    return min(x, (1. - x)*x*sf);
    
}


// The grungey texture -- Kind of modelled off of the metallic Shaderto texture,
// but not really. Most of it was made up on the spot, so probably isn't worth 
// commenting. However, for the most part, is just a mixture of colors using 
// noise variables.
vec3 GrungeTex(vec3 p){
    
    
 	// Some fBm noise.
    //float c = n2D(p*4.)*.66 + n2D(p*8.)*.34;
    float c = gradN3D(p*2.)*.57 + gradN3D(p*4.5)*.28 + gradN3D(p*10.)*.15;
    c = smoothstep(.15, .85, c);
    
    // Noisey bluish red color mix.
    vec3 col = mix(vec3(.35, .2, .02)*.9, vec3(.32, .4, .6), c);
    // Running slightly stretched fine noise over the top.
    col *= gradN3D(p*vec3(150, 350, 150))*.5 + .5; 
    
    // Using a smooth fract formula to provide some splotchiness... Is that a word? :)
    col = mix(col, col*vec3(.75, .95, 1.2), sFract(c*4., 12.));
    col = mix(col, col*vec3(1.2, 1, .8)*.8, sFract(c*5. + .35, 12.)*.5);
    
    // More noise and fract tweaking.
    c = gradN3D(p*8. + .5)*.7 + gradN3D(p*18. + .5)*.3;
    c = c*.7 + sFract(c*5., 16.)*.3;
    col = mix(col*.6, col*1.4, c);
    
    float fineNoise = gradN3D(p*128.);
    col *= sFract(fineNoise*2., 12.)*.3 + .9;
    
    // Clamping to a zero to one range.
    return clamp(col, 0., 1.);
    
}
