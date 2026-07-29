// Common (common) — Packed Mobius Strip by Shane
// https://www.shadertoy.com/view/Xf2czW

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

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// IQ's vec2 to float hash.
// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21(vec2 f){

    // The first line relates to ensuring that icosahedron vertex identification
    // points snap to the exact same position in order to avoid hash inaccuracies.
    uvec2 p = floatBitsToUint(f);
    p = 1664525U*(p>>1U^p.yx);
    return float(1103515245U*(p.x^(p.y>>3U)))/float(0xffffffffU);
}

// IQ's "uint" based uvec3 to float hash.
float hash31(vec3 f){

    //f.xy = mod(f.xy, GRID_SIZE);
    uvec3 p = floatBitsToUint(f);
    p = 1103515245U*((p >> 2U)^(p.yzx>>1U)^p.zxy);
    uint h32 = 1103515245U*(((p.x)^(p.y>>3U))^(p.z>>6U));

    uint n = h32^(h32 >> 16);
    return float(n & uint(0x7fffffffU))/float(0x7fffffff);
}


// Wavy repeat striped pattern.
float bgPat(vec2 p, float tm){

    // Overall pattern rotation.
    p *= rot2(-PI/6.);
    
    // Scaling and translation.
    const float gSc = 2.;
    p *= gSc;
    
    // Stripe ID -- Not used here.
    //vec2 ip = floor(p);
 
    // Screen coordinate perturbation.    
    vec2 offs = vec2(0, sin(p/gSc*PI*2. + cos(p.yx/gSc*PI*3. + tm)*PI/4.) )*.05*gSc;
   
    // Applying the UV offset above.    
    p.xy -= offs;
    p.y -= dot(sin(p - cos(p.yx*1.25 + tm)), vec2(.1));
    
    // Repeat line distance field.
    float d = (abs(fract(p.y) - .5) - .2);
    
    // Experiments.
    //if(mod(ip.y, 2.)==0.)
    //if((ip.y)==2. || (ip.y)==-4.)
    //d = max(d, -((abs(mod(p.x, 1.) - .5) - .2)));
    //d = min(d + .05, abs(d - .04) - .04);
    //if(abs(ip.y + 1.)>5.) d = 1e5;
    
    return d/gSc;
    
}




