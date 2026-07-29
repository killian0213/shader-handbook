// Common (common) — 3D Diffusion Automata by Shane
// https://www.shadertoy.com/view/cl3yDN

// A cube of dimension 8 and a square of dimension 64 will
// each require the same number of pixels for storage.
const float wrap = 8.; // (2^3)*(2^3)*(2^3) = 2^12.
const float cubeMapRes = 64.; // (2^6)*(2^6) = 2^12.

/////////////////////
/////////////////////

// I might replace this with the Murmurhash functions, but I wanted
// to try these out first, since I like the simplicity, and they're
// supposed to be fast. Anyway, you can read all about it, here:

// A Mind Forever Programming - Random Floats in GLSL 330
// Author: Lee C
// https://amindforeverprogramming.blogspot.com/2013/07/random-floats-in-glsl-330.html
 
uint hash( uint x ){
    x += ( x << 10u ); x ^= ( x >>  6u );
    x += ( x <<  3u ); x ^= ( x >> 11u );
    x += ( x << 15u ); return x;
}

uint hash( uvec2 v ){ return hash( v.x ^ hash(v.y) ); }
uint hash( uvec3 v ){ return hash( v.x ^ hash(v.y) ^ hash(v.z) ); }
uint hash( uvec4 v ){ return hash( v.x ^ hash(v.y) ^ hash(v.z) ^ hash(v.w) ); }

float hash41( vec4 f ){

    const uint mantissaMask = 0x007FFFFFu;
    const uint one          = 0x3F800000u;
   
    uint h = hash( floatBitsToUint( f ) );
    h &= mantissaMask;
    h |= one;
    
    float  r2 = uintBitsToFloat( h );
    return r2 - 1.;
}

float hash31( vec3 f ){
    const uint mantissaMask = 0x007FFFFFu;
    const uint one          = 0x3F800000u;
   
    uint h = hash( floatBitsToUint( f ) );
    h &= mantissaMask;
    h |= one;
    
    float  r2 = uintBitsToFloat( h );
    return r2 - 1.;
}

float hash21( vec2 f ){
    const uint mantissaMask = 0x007FFFFFu;
    const uint one          = 0x3F800000u;
   
    uint h = hash( floatBitsToUint( f ) );
    h &= mantissaMask;
    h |= one;
    
    float  r2 = uintBitsToFloat( h );
    return r2 - 1.;
}

//////////////////////

// Converting pixels on a 2D square area to their equivalent 
// 3D positions and back again: For anyone who finds this confusing,
// I've explained the simple process below.


vec3 convertCoord(vec2 p){

    // Convert the 2D coordinate to its equivalent 3D coordinates.
    
    // 2D coordinate -- Wrapping isn't mandatory, but this is a wrapped example.
    p = mod(floor(p), cubeMapRes); 
    // Converting the above 2D coordinate to its linear representation.
    float i = p.x + p.y*cubeMapRes;

    // Converting the linear number above to 3D coordinates. The wrapping is
    // overkill here, since things have been arranged to fit perfectly, 
    // but it's there anyway.
    return mod(vec3(i, floor(i/wrap), floor(i/(wrap*wrap))), wrap);
}

vec2 convertCoord(vec3 p){

    // Convert the 3D coordinates to its equivalent 2D coordinates.
    
    // Wrapping the 3D coordinates first -- Only for this example.
    p = mod(floor(p), wrap);
    // Converting the above 3D coordinate to its linear representation.
    float i = p.x + (p.y + p.z*wrap)*wrap;
    // Converting the linear number above to 2D coordinates. The wrapping is
    // overkill here, since things have been arranged to fit perfectly, 
    // but it's there anyway.
    return mod(vec2(i, floor(i/cubeMapRes)), cubeMapRes);
}



/*
// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21(vec2 f){

    // The first line relates to ensuring that icosahedron vertex identification
    // points snap to the exact same position in order to avoid hash inaccuracies.
    uvec2 p = floatBitsToUint(f);
    p = 1664525U*(p>>1U^p.yx);
    return float(1103515245U*(p.x^(p.y>>3U)))/float(0xffffffffU);
}
*/

/* 
// IQ's "uint" based uvec3 to float hash.
float hash31(vec3 f){

    //f.xy = mod(f.xy, 1.);
    uvec3 p = floatBitsToUint(f);
    p = 1103515245U*((p >> 2U)^(p.yzx>>1U)^p.zxy);
    uint h32 = 1103515245U*(((p.x)^(p.y>>3U))^(p.z>>6U));

    uint n = h32^(h32 >> 16);
    return float(n & uint(0x7fffffffU))/float(0x7fffffff);
}
*/

/*
// IQ's "uint" based uvec4 to float hash.
float hash41(vec4 f){

    uvec4 p = floatBitsToUint(f);
    uint h32 = 19u*p.x + 47u*p.y + 101u*p.z + 131u*p.w + 173u;

    uint n = h32^(h32 >> 16);
    return float(n & uint(0x7fffffffU))/float(0x7fffffff);
}
*/

/*
// Commutative smooth minimum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smin(float a, float b, float k){

   float f = max(0., 1. - abs(b - a)/k);
   return min(a, b) - k*.25*f*f;
}

// Commutative smooth maximum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smax(float a, float b, float k){
    
   float f = max(0., 1. - abs(b - a)/k);
   return max(a, b) + k*.25*f*f;
}
*/

// Six cube face directions.
const vec3[6] e = vec3[6](vec3(-1, 0, 0), vec3(1, 0, 0), vec3(0, -1, 0), vec3(0, 1, 0),
                          vec3(0, 0, -1), vec3(0, 0, 1));
 
vec3 indexToDir(float i) {
   // Converts the indices 0 through to 5 to one of the direction above.
   return e[int(i)]; 
}

float dirToIndex(vec3 p) {
    
    // Converts the left, right, down, up, backward, forward 
    // vectors to 0, 1, 2, 3,  4 or 5 respectively.
    for(int i = 0; i<6; i++){
        if(p == e[i]) return float(i);
    }
    
    // Redundant, because the above will always return... but I'm paranoid, 
    // so if one day it doesn't, this will be waiting. :D
    return 0.;
}

float rndDirIndex(vec4 ut){
    // Returns a random number based on 2D position and time.
    return mod(floor(96.*hash41(ut)), 6.);
}

float rndDirIndex(vec4 ut, float maxM){
    // Returns a random number based on 2D position and time,
    // but with restrictions.
    return mod(floor(72.*hash41(ut)), maxM);
}

vec3 rndDir(vec4 u) {
    // Returns a random direction.
    return indexToDir(rndDirIndex(u));
}

vec3 rndDir(vec4 u, float maxM) {
    // Returns a random direction with restrictions.
    return indexToDir(rndDirIndex(u, maxM));
}

// IQ's signed box formula.
float sBoxS(in vec2 p, in vec2 b, in float sf){

  p = abs(p) - b + sf;
  return length(max(p, 0.)) + min(max(p.x, p.y), 0.) - sf;
}

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
  return (col*diff + spec*PI);
  
}
////////////////////

// An art deco multiscale Truchet pattern. Made up on the spot, 
// but it seems to work.
vec4 Truchet(vec2 p, vec3 cellID, float faceID, inout vec2 scl){
      

     // Save coordinates.
     vec2 oP = p;


     // Scaling, ID, and local coordinates.
     vec2 oScl = scl;
     vec2 id2 = floor(p/scl) + .5;
     p -= (id2)*scl;//mod(tuv, scl) - scl/2.;
     
     // Unique face identifier.
     vec3 id3 = cellID + vec3(id2/12., faceID/12.);

     // Random subdivision.
     int divN = 0;
     if(hash31(id3 + .09)<.5){ 
         scl /= 2.; 
         p = oP;
         id2 = floor(p/scl) + .5;
         //p = mod(p, scl) - scl/2.;
         p -= (id2)*scl;
         
         id3 = cellID + vec3(id2/12., faceID/12.);
         
         divN++; // Subdivision number.
     }


     
     // Random coordinate rotation.
     //if(hash31(id3 + .42)<.5) p = rot2(3.14159/2.*floor(hash21(id3 + .01)*32.))*p;
     if(hash31(id3 + .42)<.5) p = p.yx*vec2(-1, 1);

     // The distance field holder. The pattern involves rending overlapping,
     // so requires to place holders.
     vec2 dd = vec2(1e5);
     
     // Triangle experiment for next time.
     //vec2 rTuv = rot2(3.14159/4.)*tuv;
     //dd.x = (tuv.x + tuv.y)*.7071;
     //dd.y = -(tuv.x + tuv.y)*.7071;
     //dd = max(dd, max(abs(tuv.x), abs(tuv.y)) - scl.x/2.);
     
     // Cell bounds.
     //float bx = sBoxS(p, scl/2. - .005, 0.);

     
     if(hash31(id3 + .12)<.65){
     
         // Random arcs, interspersed with random points that 
         // break up the pattern.

         if(hash31(id3 + .19)<.65){
             dd.x = length(p - scl/2.);
             dd.x = abs(dd.x - scl.x/2.);
         }
         else {
             dd.x = length(p - vec2(1, 0)*scl/2.);
             dd.x = min(dd.x, length(p - vec2(0, 1)*scl/2.));
         }

         if(hash31(id3 + .21)<.65){
             dd.y = length(p + scl/2.);
             dd.y = abs(dd.y - scl.y/2.);
         }
         else {
             dd.y = length(p - vec2(-1, 0)*scl/2.);
             dd.y = min(dd.y, length(p - vec2(0, -1)*scl/2.));
             
         }  

     }
     else {
     
         // Random lines, interspersed with random points that 
         // break up the pattern.

         if(hash31(id3 + .13)<.65){
             dd.x = abs(p.y);
         }
         else {
             dd.x = length(p - vec2(-1, 0)*scl/2.);
             dd.x = min(dd.x, length(p - vec2(1, 0)*scl/2.));
         }

         if(hash31(id3 + .14)<.65){
             dd.y = abs(p.x);
         }
         else {
             dd.y = length(p - vec2(0, -1)*scl/2.);
             dd.y = min(dd.y, length(p - vec2(0, 1)*scl/2.));
         }
     }


     // Line pattern.
     float lNum = 12./oScl.x;
     float offs = divN==0? .5 : .5; //  Different for different scales.
     vec2 pat = (abs(fract(dd*lNum + offs) - .5) - .2)/lNum;
     //vec2 pat = vec2(1e5);//

     // If not subdivided, split the pattern and move it to match the
     // position of the subdivided one. It's one of many standard
     // multiscale pattern moves.
     if(divN == 0) dd = abs(dd - .25*scl.x);
     //dd = abs(dd + .125) - .125;
    
     // Apply some scale based width.
     dd.xy -= .24/2.*oScl;
     
     
     
     // Randomize the rendering order to mix things up more.
     if(hash31(id3 + .15)<.5){ dd = dd.yx; pat = pat.yx; }
     
     //dd = max(dd, sBoxS(tuv, scl/2. - .005, 0.));
 

     // Return the overlapping Truchet pattern distances 
     // and the lines pattern distances.
     return vec4(dd, pat);  

}

