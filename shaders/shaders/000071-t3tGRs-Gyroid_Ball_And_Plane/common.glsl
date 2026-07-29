// Common (common) — Gyroid Ball And Plane by Shane
// https://www.shadertoy.com/view/t3tGRs

#define TAU 6.2831853
#define PI 3.14159265 
 
 
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

// Commutative smooth minimum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smin(float a, float b, float k){

   float f = max(0., 1. - abs(b - a)/k);
   return min(a, b) - k*.25*f*f;
}
 
 
// IQ's "uint" based uvec3 to float hash with Fabrice's modification.
float hash31(vec3 f){

   
    uvec3 p = floatBitsToUint(f);
    p = 1664525U*((p >> 2U)^(p.yzx>>1U)^p.zxy);
    uint h32 = 1103515245U*(((p.x)^(p.y>>3U))^(p.z>>6U));

    uint n = h32^(h32 >> 16);
    return float(n & uint(0x7fffffffU))/float(0x7fffffff);
    
}
 


// Hash without Sine -- Dave Hoskins
// https://www.shadertoy.com/view/4djSRW
//  3 out, 3 in...
vec3 hash33(vec3 p){

 	p = fract(p*vec3(.5031, .6030, .4973));
    p += dot(p, p.yxz + 142.5453);
    return fract((p.xxy + p.yxx)*p.zyx);

}

 
////////////////////
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


