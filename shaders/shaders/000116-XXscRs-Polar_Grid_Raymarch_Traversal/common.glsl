// Common (common) — Polar Grid Raymarch Traversal by Shane
// https://www.shadertoy.com/view/XXscRs

///////////////////////////
#define PI 3.14159265
#define TAU 6.2831853


// Microfaceted normal distribution function.
float D_GGX(float NoH, float roughness) {
    float alpha = pow(roughness, 4.);
    float b = (NoH*NoH*(alpha - 1.) + 1.);
    return alpha/(PI*b*b);
}

// Surface geometry function.
float G1_GGX_Schlick(float NoV, float roughness) {
    //float r = roughness; // original
    float r = .5 + .5*roughness; // Disney remapping.
    float k = (r*r)/2.;
    float denom = NoV*(1. - k) + k;
    return max(NoV, .001)/denom;
}

float G_Smith(float NoV, float NoL, float roughness) {
    float g1_l = G1_GGX_Schlick(NoL, roughness);
    float g1_v = G1_GGX_Schlick(NoV, roughness);
    return g1_l*g1_v;
}

// Bidirectional Reflectance Distribution Function (BRDF). 
//
// If you want a quick crash course in BRDF, see the following:
// Microfacet BRDF: Theory and Implementation of Basic PBR Materials
// https://www.youtube.com/watch?v=gya7x9H3mV0&t=730s
//
vec3 BRDF(vec3 col, vec3 n, vec3 l, vec3 v, 
          float type, float rough, float fresRef, vec3 lCol){
     
    vec3 h = normalize(v + l); // Half vector.

    // Standard BRDF dot product calculations.
    float nv = clamp(dot(n, v), 0., 1.);
    float nl = clamp(dot(n, l), 0., 1.);
    float nh = clamp(dot(n, h), 0., 1.);
    float vh = clamp(dot(v, h), 0., 1.);  


    // Specular microfacet (Cook- Torrance) BRDF.
    //
    // F0 for dielectics in range [0., .16] 
    // Default FO is (.16 * .5^2) = .04
    // Common Fresnel values, F(0), or F0 here.
    // Water: .02, Plastic: .05, Glass: .08, Diamond: .17
    // Copper: vec3(.95, .64, .54), Aluminium: vec3(.91, .92, .92), Gold: vec3(1, .71, .29),
    // Silver: vec3(.95, .93, .88), Iron: vec3(.56, .57, .58).
    vec3 f0 = vec3(.16*(fresRef*fresRef)); 
    // For metals, the base color is used for F0.
    f0 = mix(f0, col, type);
    vec3 F = f0 + (1. - f0)*pow(1. - vh, 5.);  // Fresnel-Schlick reflected light term.
    // Microfacet distribution... Most dominant term.
    float D = D_GGX(nh, rough); 
    // Geometry self shadowing term.
    float G = G_Smith(nv, nl, rough); 
    // Combining the terms above.
    vec3 spec = F*D*G/(4.*max(nv, .001));


    // Diffuse calculations.
    vec3 diff = vec3(nl);
    diff *= 1. - F; // If not specular, use as diffuse (optional).
    diff *= (1. - type); // No diffuse for metals.


    // Combining diffuse and specular.
    // You could specify a specular color, multiply it by the base
    // color, or multiply by a constant. It's up to you.
    return (col*diff + lCol*spec*PI);
  
}
////////////////////
/*
// Commutative smooth minimum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smin(float a, float b, float k){

   float f = max(0., 1. - abs(b - a)/k);
   return min(a, b) - k*.25*f*f;
}
*/

// Commutative smooth maximum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smax(float a, float b, float k){
    
   float f = max(0., 1. - abs(b - a)/k);
   return max(a, b) + k*.25*f*f;
}