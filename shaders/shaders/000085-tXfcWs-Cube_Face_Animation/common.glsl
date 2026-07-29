// Common (common) — Cube Face Animation by Shane
// https://www.shadertoy.com/view/tXfcWs



// Use an isometric camera setup. Using a convential camera spoils
// the illusion a little, but still looks interesting.
#define ISOMETRIC

// Face holes.
#define HOLES

///////////////

// Far plane, or maximum ray distance.
#define FAR 10.


// PI and 2PI.
#define PI 3.14159265357989
#define TAU 6.2831853


// Standard 2D rotation formula.
mat2 r2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21(vec2 f){
    //f = mod(f + 16384., 16384.); // Annoying GPU hash related hack.
    uvec2 p = floatBitsToUint(f);
    p = 1664525U*(p>>1U^p.yx);
    return float(1103515245U*(p.x^(p.y>>3U)))/float(0xffffffffU);
}


// IQ's 2D box formula with smoothing.
float sBoxS(in vec2 p, in vec2 b, in float rf){
  
  vec2 d = abs(p) - b + rf;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - rf;
    
}

// IQ's 3D box formula with smoothing.
float sBoxS(in vec3 p, in vec3 b, in float rf){
  
  vec3 d = abs(p) - b + rf;
  return min(max(max(d.x, d.y), d.z), 0.) + length(max(d, 0.)) - rf;
    
}


//////////////////////////


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

// Diffuse.
vec3 getDiff(vec3 FS, float nl, float rough, float type){

    // Diffuse calculations.
    vec3 diff = nl*(1. - FS); // If not specular, use as diffuse (optional)
    return diff*(1. - type); // No diffuse for metals.
}

///////////

// Dave Hoskins's hash function.
// 4 in, 4 out.
vec4 hash4(vec4 p){

    p = fract(p*.1031);
    p *= p + 42.4573;
    p *= p + p;
    return fract(p);
}

// Compact version of IQ's 3D value function.
float n3D(vec3 p){

	const vec3 s = vec3(71, 157, 113);

	vec3 ip = floor(p); p -= ip;
	p = p*p*(3. - 2.*p);
	vec4 h = vec4(0, s.yz, s.y + s.z) + dot(ip, s);
	h = mix(hash4(h), hash4(h + s.x), p.x);
	h.xy = mix(h.xz, h.yw, p.y);
	return mix(h.x, h.y, p.z);
}

 