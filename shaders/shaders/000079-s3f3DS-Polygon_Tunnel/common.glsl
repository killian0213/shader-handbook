// Common (common) — Polygon Tunnel by Shane
// https://www.shadertoy.com/view/s3f3DS

// PI and 2 PI. 
#define PI 3.14159265
#define TAU 6.2831853

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// Commutative smooth maximum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smax(float a, float b, float k){
    
   float f = max(0., 1. - abs(b - a)/k);
   return max(a, b) + k*.25*f*f;
}


/*
// Hash without Sine -- Dave Hoskins
// https://www.shadertoy.com/view/4djSRW
// 2 out, 2 in...
vec2 hash22(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx)*vec3(.3031, .4030, .5973));
    p3 += dot(p3, p3.yzx + 42.1237);
    return fract((p3.xx+p3.yz)*p3.zy);
}
*/

// Bidirectional Reflectance Distribution Function (BRDF). 
//
// If you want a quick crash course in BRDF, see the following:
// Microfacet BRDF: Theory and Implementation of Basic PBR Materials
// https://www.youtube.com/watch?v=gya7x9H3mV0&t=730s
//

// Surface geometry function.
float GGX_Schlick(float nv, float rough) {
    //float r = roughness; // original
    float r = .5 + .5*rough; // Disney remapping.
    float k = (r*r)/2.;
    float denom = nv*(1. - k) + k;
    return max(nv, .001)/denom;
}

float G_Smith(float nr, float nl, float rough) {
    float g1_l = GGX_Schlick(nl, rough);
    float g1_v = GGX_Schlick(nr, rough);
    return g1_l*g1_v;
}

// Specular calculation.
vec3 getSpec(vec3 FS, float nh, float nr, float nl, float rough){

    // Microfacet distribution... Most dominant term.
    // Microfaceted normal distribution function.
    float alpha = pow(rough, 4.);
    float b = (nh*nh*(alpha - 1.) + 1.);
    float D = alpha/(3.14159265*b*b);    
    
    // Geometry self shadowing term.
    float G = G_Smith(nr, nl, rough);
    
    // Combining the terms above.
    return FS*D*G/(4.*max(nr, .001))*3.14159265;
}

vec3 getDiff(vec3 FS, float nl, float rough, float type){

    // Diffuse calculations.
    vec3 diff = nl*(1. - FS); // If not specular, use as diffuse (optional)
    return diff*(1. - type); // No diffuse for metals.
}
