// Common (common) — Extruded Maze by Shane
// https://www.shadertoy.com/view/wXjGD1

// Maze pattern. 
// Broken lines: 0, Straight edge diagonal: 1.
#define MAZE_PATTERN 0

// Only display the 2D pattern.
//#define SHOW_2D_PATTERN

 
// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21(vec2 f){

    //f = mod(f, GRID_SIZE);
    // The first line relates to ensuring that icosahedron vertex identification
    // points snap to the exact same position in order to avoid hash inaccuracies.
    uvec2 p = floatBitsToUint(f + 1024.);
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

 
/*
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
*/

// Unsigned distance to the segment joining "a" and "b".
// This is basically IQ's well known formula.
float distLine(vec2 p, vec2 a, vec2 b){

    p -= a; b -= a;
    float h = clamp(dot(p, b)/dot(b, b), 0., 1.);
    return length(p - b*h);
}

/////////////////
// Global cell scale and line width.
const vec2 sc = vec2(1)/2.;
const float lw = sc.x/5.5;

// Cell type, cell coordinate and ID.
int type;
vec2 gPP;
vec2 gIP;

#if MAZE_PATTERN == 1
    
float truchetI(vec2 p, vec2 offs){

    
    vec2 ip = floor(p/sc) - offs;
    p -= (ip + .5)*sc; 
    
    gPP = p;
    gIP = ip;
    
    
    float rnd = hash21(ip);
    
    // Cross and lines random distribution threshold.
    float th = .4;
     
    float ln = 1e5;
    if(rnd<th){
     
        // Cross.
        p = abs(p);
        ln = min(p.x, p.y);
        type = 0;
 
    }
    else {
    
        // Lines.
        type = 1;
    
        // Random reverse.
        float reverse = 1.;
        float rnd2 = hash21(ip + .13);
        if(rnd2<.5){ p.x = -p.x; reverse = -1.; }
   
        // Two diagonal dividing line fields. Positive on 
        // one side, and negative on the other.
        float diag = dot(p - vec2(0, .5)*sc, vec2(.7071));
        float diag2 = dot(p - vec2(0, -.5)*sc, vec2(.7071));
        
        // Absolute for lines.
        ln = abs(diag);
        float ln2 = abs(diag2);
       
        // In the event that a neighbor is not another set of straight 
        // lines (a cross), you need to give the appropriate line a 
        // 45 degree bend toward the neighboring cell. Yes, this is an
        // annoying and slightly expensive piece of logic, but I don't 
        // see another way.
        if(hash21(ip + vec2(0, 1))<th) ln = max(ln, -p.x);
        if(hash21(ip + reverse*vec2(1, 0))<th) ln = max(ln, -p.y);
        
        if(hash21(ip + vec2(0, -1))<th) ln2 = max(ln2, p.x); 
        if(hash21(ip + reverse*vec2(-1, 0))<th) ln2 = max(ln2, p.y); 
       
        // Combine the bent or straight lines.
        ln = min(ln, ln2);
       
        
    
    }
   
   
    return ln - lw;

}

float grid;

// Second maze pattern. This one was annoying to code, and it's slower
// than I wanted it to be. If someone knows of a better way to produce
// one of these, feel free to let me know.
vec3 truchet(inout vec2 p){

    
      
    float d = truchetI(p, vec2(0));
    
    vec2 svP = gPP;
    vec2 svP0 = gPP;
    vec2 svIP = gIP;
    
    
    
    float sq = max(abs(svP.x), abs(svP.y)) - sc.x/2.;
    //grid = abs(sq);
    
 
    if(type==0){
    
        // Cross.
        // Retrieve the neighboring cell distances, in order to
        // add the tiny overlap within the cross cell. Just to
        // make matters worse, these neighboring line tiles will
        // depend on their own neighbors, which needs to be 
        // included in the logic.
       
        // Join with the neighbors.
        for(int i = 0; i<4; i++){
            
            vec2 ij = vec2(-1, 0);
            if(i%2==0) ij = -ij;
            if(i>1) ij = ij.yx;
            float dI = truchetI(p, ij); 
            if(dI<d){
               
               d = dI;
               //svP = gPP;
               
            }
        
        }
        
  
       
        if(hash21(svIP + .22)<.5) svP = svP.yx;
        float ln2 = abs(abs(svP.x) - lw -.02) - .02;
        ln2 = max(ln2, abs(svP.y) - lw - .04);
        d = max(d, -ln2);
        
       
    
    }
    
      
    //d = max(d, sq + .001);

      
    p = svP0; 
    return vec3(d, svIP);

}


#else

vec3 truchet(inout vec2 p){


    vec2 ip = floor(p/sc) + .5;
  
    p -= (ip)*sc;
    
    vec2 svP = p;

    
    
    float rnd = hash21(ip + .11);
    float rnd2 = hash21(ip + .33);    
 
    
     
    if(rnd<.5) p = p.yx*vec2(-1, 1);
 
   
    vec2 d = vec2(1e5);
    
    float ew = 1./6.*sc.x; // Max 1./3.
    
   
    // Cut line. Opposite of the normal direction.
    d.y = distLine(p, (vec2(-.5, .5)*1.5)*sc, (vec2(.5, -.5)*1.5)*sc) - (.7071*sc.x - ew*2.)/2.;
    //d.y = distLine(p, vec2(-.5)*1.5, vec2(.5)*1.5) - (.7071 - ew*2.)/2.;
   
    float dA = distLine(p, (vec2(-.5, 0)-1.)*sc, (vec2(0, .5) + 1.)*sc) - ew;
  
   float dB = distLine(p, (vec2(0, -.5)-1.)*sc, (vec2(.5, 0)+1.)*sc) - ew;
     if(mod(ip.x + ip.y, 3.)<.5){
     //if(hash21((ip) + .44)<.35){
         if(rnd2<.35) dA = max(dA, -d.y); 
         else if(rnd2>.65) dB = max(dB, -d.y);
         
         //dA = max(dA, -d.y);
     }

     //if(mod(ip.x + ip.y + 1., 4.)<.35) dB = max(dB, -d.y); 
     //else dB = max(dB, -d.y);
     
     d.x = min(dA, dB);
 
    // Cell lines.
    //#define DIGI
    #ifdef DIGI
    p = abs(p) - sc/2.;
    d = max(d, max(p.x, p.y) + .001);
    #endif

    
     
    //arc = abs(abs(arc - .5) - .5);
    
    p = svP;
    
    return vec3(d.x, ip);
}

#endif



///////////////////////////
const float PI = 3.14159265;

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
          float type, float rough, float fresRef, vec3 spCol){
   
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
    // Metals: I think all need to be converted to linear form (roughly squared).
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
    return (col*diff + spCol*spec*PI);
  
}
////////////////////

/*
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
   
    
    // Note the "mod" call. Slower, but ensures accuracy with large time values.
    //mat2  m = rot2(mod(iTime, 6.2831853));	
	//p.xy = m * p.xy;//rotate gradient vector
    //p.yz = m * p.yz;//rotate gradient vector
    ////p.zx = m * p.zx;//rotate gradient vector
	//return p;
    

}

// Gradient noise. Just a slight reworking of IQ's original.
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
 
}
*/