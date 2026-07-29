// Common (common) — Voronoi Tech Texture by Shane
// https://www.shadertoy.com/view/tcXSRf

//#define STATIC

// 2 PI.
#define TAU 6.2831853 

// Global time variable.
float tm;

// A slight variation on a function from Nimitz's hash collection, here: 
// Quality hashes collection WebGL2 - https://www.shadertoy.com/view/Xt3cDn
vec2 hash22A(vec2 f){

    // Fabrice Neyret's vec2 to unsigned uvec2 conversion. I hear that it's not
    // that great with smaller numbers, so I'm fudging an increase.
    uvec2 p = floatBitsToUint(f + 1024.);
    
    // Modified from: iq's "Integer Hash - III" (https://www.shadertoy.com/view/4tXyWN)
    // Faster than "full" xxHash and good quality.
    p = 1103515245U*((p>>1U)^(p.yx));
    uint h32 = 1103515245U*((p.x)^(p.y>>3U));
    uint n = h32^(h32>>16);
    
    uvec2 rz = uvec2(n, n*48271U);
    #ifdef STATIC
    // Standard uvec2 to vec2 conversion with wrapping and normalizing.
    return (vec2((rz>>1)&uvec2(0x7fffffffU))/float(0x7fffffff) - .5);
    #else
    f = vec2((rz>>1)&uvec2(0x7fffffffU))/float(0x7fffffff);
    return sin(f*TAU + tm)*.5;
    #endif
}

 
// 2D 2nd-order Voronoi: Obviously, this is just a rehash of IQ's original. I've tidied
// up those if-statements. Since there's less writing, it should go faster. That's how 
// it works, right? :D
//
vec3 VoronoiA(in vec2 p){
    
	vec2 ip = floor(p) + .5, o; p -= ip;
	
	vec3 d = vec3(1); // 1.4, etc. "d.z" holds the distance comparison value.
    
    float minD = 1.;
    vec2 id;
    
	for(int y =-1; y<=1; y++){
		for(int x =-1; x<=1; x++){
            
			o = vec2(x, y);
            o += hash22A(ip + o) - p;
            
	        o = abs(o);
            d.z = (o.x + o.y)*.7071; // Manhattan.
            
            if(d.z<minD){ minD = d.z; id = vec2(x, y) + ip; }
            //d.z = max(max(o.x, o.y), (o.x + o.y)*.7071); // .7071 for an octagon, etc.
            
            d.y = max(d.x, min(d.y, d.z));
            d.x = min(d.x, d.z); 
                       
		}
	}
    
	
    float r = (d.y - d.x); // return 1.-d.x; // etc.
    r = clamp(r + .05, 0., .6);
    
    return vec3(r, id);
    
}

////////////////

// Microfaceted normal distribution function.
float D_GGX(float NoH, float roughness) {
    float alpha = pow(roughness, 4.);
    float b = (NoH*NoH*(alpha - 1.) + 1.);
    return alpha/(3.14159265*b*b);
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
          float type, float rough, float fresRef){
     
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
  return (col*diff + spec*3.14159265);
  
}