// Common (common) — Offset Stochastic Tiling by Shane
// https://www.shadertoy.com/view/w3V3Dh

// Frame color - Chrome: 0, Gold: 1.
#define FRAME_COL 0

// Display the square grid.
//#define GRID

// PI and 2 PI.
#define PI 3.14159265357989
#define TAU 6.2831853


float gTm;

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21(vec2 f){
    uvec2 p = floatBitsToUint(f + 16384.);
    p = 1664525U*(p>>1U^p.yx);
    return float(1103515245U*(p.x^(p.y>>3U)))/float(0xffffffffU);
}


// A slight variation on one of Dave Hoskins's hash functions,
// which you can find here:
//
// Hash without Sine -- Dave Hoskins
// https://www.shadertoy.com/view/4djSRW
// 1 out, 2 in...
//#define STATIC
float hash21B(vec2 p){
 
	vec3 p3  = fract(vec3(p.xyx)*.1031);
    p3 += dot(p3, p3.yzx + 39.123);
    
    #ifdef STATIC
    return (fract((p3.x + p3.y)*p3.z) - .5)*.45;
    #else
    p3.x = fract((p3.x + p3.y) * p3.z);
    return sin(p3.x*TAU + gTm)*.225; // Animation, if desired.
    #endif
}


 
// A slight variation on a function from Nimitz's hash collection, here: 
// Quality hashes collection WebGL2 - https://www.shadertoy.com/view/Xt3cDn
vec2 hash22(vec2 f){

     
    // Fabrice Neyret's vec2 to unsigned uvec2 conversion. I hear that it's not
    // that great with smaller numbers, so I'm fudging an increase.
    uvec2 p = floatBitsToUint(f + 16384.);
    
    // Modified from: iq's "Integer Hash - III" (https://www.shadertoy.com/view/4tXyWN)
    // Faster than "full" xxHash and good quality.
    p = 1103515245U*((p>>1U)^(p.yx));
    uint h32 = 1103515245U*((p.x)^(p.y>>3U));
    uint n = h32^(h32>>16);
    
    uvec2 rz = uvec2(n, n*48271U);
    // Standard uvec2 to vec2 conversion with wrapping and normalizing.
    return vec2((rz>>1)&uvec2(0x7fffffffU))/float(0x7fffffff);

}


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

// Unsigned distance to the segment joining "a" and "b".
float distLine(vec2 p, vec2 a, vec2 b){

    p -= a; b -= a;
    float h = clamp(dot(p, b)/dot(b, b), 0., 1.);
    return length(p - b*h);
}

/*
// Signed distance to a line passing through "a" and "b".
float distLineS(vec2 p, vec2 a, vec2 b){

   b -= a; 
   return dot(p - a, vec2(-b.y, b.x)/length(b));
}
*/

// More correct signed line distance. Based on IQ's original, but with
// a sign addition.
float distLineS(vec2 p, vec2 a, vec2 b){  
   
    b -= a; 
    return dot(p - a, vec2(-b.y, b.x)/length(b));
  
}

// IQ's box function.
float sBox(in vec2 p, in vec2 b){
  
  vec2 d = abs(p) - b;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.));
    
}

/*
// Return the distance of ray origin to the line intersection point
// in the direction of the unit direction ray. If the ray falls outside
// the line between points "a" and "b", it won't detect a hit... Not
// all line algorithms work this way. By the way, if anyone knows of a
// faster, more efficient version of this, feel free to let me know.
float lineIntersectRobust(vec2 ro, vec2 rd, vec2 a, vec2 b){

    vec2 v1 = ro - a;
    vec2 v2 = b - a;
    vec2 v3 = vec2(-rd.y, rd.x);

    float dotP = dot(v2, v3);
    if(abs(dotP)<1e-6) return 1e8;

    float t1 = (v2.x*v1.y - v2.y*v1.x)/dotP;
    float t2 = dot(v1, v3)/dotP;

    if(t1 >= 0. && (t2 >= 0. && t2 <= 1.)) return t1;

    return 1e8;
}
*/

// Return the distance of ray origin to the line intersection point
// in the direction of the unit direction ray. The line is infinite,
// meaning it exceeds the "a" and "b" boundary points.
//
// In this case, the intersection is guaranteed, so we can employ 
// some shortcuts.
float lineIntersect(vec2 ro, vec2 rd, vec2 a, vec2 b){

    vec2 v1 = ro - a;
    vec2 v2 = b - a;
    vec2 v3 = vec2(-rd.y, rd.x);

    float dotP = dot(v2, v3);
    
    return(v2.x*v1.y - v2.y*v1.x)/dotP;

}

////////////////////////////////////
/*
vec3 hsl2rgb(in vec3 c){

    vec3 rgb = clamp(abs(mod(c.x*6. + vec3(0, 4, 2), 6.) - 3.) - 1., 0., 1.);
    return c.z + c.y*(rgb - .5)*(1. - abs(2.*c.z - 1.));
}

vec3 ryb2rgb(vec3 col){


    // Smoothing. Everyone else seems to perform this cubic smoothing
    // step first, so I'll leave it in.
    
    col = smoothstep(0., 1., col);
    
   
    // RYB to RGB modified from Gosset et al.
    // 
    // RYB   000     100     010     110     001     101     011     111
    //     white     red  yellow  orange    blue  purple   green   black
    // R       1       1       1       1   0.163     0.5       0       0
    // G       1       0       1     0.5   0.373       0    0.66       0
    // B       1       0       0       0     0.6     0.5     0.2       0
    // RGB to RYB
    // 
    // RGB   000     100     010     110     001     101     011     111
    //     black     red   green  yellow    blue magenta turquoi.  white
    // R       1       1       0       0       0   0.309       0       0
    // Y       1       0       1       1       0       0   0.053       0
    // B       1       0   0.483       0       1   0.469   0.210       0

 
    // 8 cube corner base colors.
    //
    // RYB to RGB
    #if 1
    
    // Modified from Gosset et al.
    vec3 c111 = vec3(1, 1, 1); // No colors: White.
    vec3 c110 = pow(vec3(.163, .373, .6), vec3(2.2)); //vec3(.02, .3, .9) // Blue: Blue
    vec3 c101 = vec3(1, 1, .04); // Yellow: Red and Green.
    vec3 c011 = vec3(1, .0225, .0049); // Red: Red.
    vec3 c100 = pow(vec3(0, .66, .2), vec3(2.2)); // Yellow and Blue: Green.
    vec3 c010 = pow(vec3(.5, 0, .5), vec3(2.2)); // Red and Blue: Magenta.
    vec3 c001 = pow(vec3(1, .5, 0), vec3(2.2)); // Red and Yellow: Orange.
    vec3 c000 = pow(vec3(.2, .094, 0), vec3(2.2)); // Red, Yellow and Blue: Black (Dark brown).

    #else
    
    // Another one that favors brighter colors, especially the blue.
    vec3 c111 = vec3(1, 1, 1); // No colors: White.
    vec3 c110 = pow(vec3(2, 71, 254)/255., vec3(2.2)); // Blue: Blue
    vec3 c101 = pow(vec3(254, 254, 51)/255., vec3(2.2)); // Yellow: Red and Green.
    vec3 c011 = pow(vec3(254, 39, 18)/255., vec3(2.2)); // Red: Red.
    vec3 c100 = pow(vec3(102, 176, 50)/255., vec3(2.2)); // Yellow and Blue: Green.
    vec3 c010 = pow(vec3(134, 1, 175)/255., vec3(2.2)); // Red and Blue: Magenta.
    vec3 c001 = pow(vec3(251, 153, 2)/255., vec3(2.2)); // Red and Yellow: Orange.
    vec3 c000 = pow(vec3(51, 24, 0)/255., vec3(2.2)); // Red, Yellow and Blue: Black  (Dark brown)..

    #endif
    
    
    // Standard cubic interpolation.  
    vec3 c = mix(mix(mix(c000, c001, col.z), mix(c010, c011, col.z), col.y), 
             mix(mix(c100, c101, col.z), mix(c110, c111, col.z), col.y), col.x);

    
    return c;
}

vec3 artPal(vec3 col){
    col = hsl2rgb(col);
    return ryb2rgb(col);
}
*/

// IQ's distance to a regular pentagon, without trigonometric functions. 
// Other distances here:
// https://iquilezles.org/articles/distfunctions2d
//
float sdPoly(in vec2 p, in mat4x2 v, int num){

    //const int num = 4;//v.length();
    float d = length(p - v[0]);
    float s = 1.;
    for( int i = 0, j = num - 1; i < num; j = i, i++){
    
        // distance
        vec2 e = v[j] - v[i];
        vec2 w =    p - v[i];
        vec2 b = w - e*clamp(dot(w, e)/dot(e, e), 0., 1. );
        // Straight edges when displaying the grid.
        #ifdef GRID
        d = min( d, length(b));
        #else
        d = smin( d, length(b), .015);
        #endif

    }
    
    return -d;
}


// Bidirectional Reflectance Distribution Function (BRDF). 
//
// If you want a quick crash course in BRDF, see the following:
// Microfacet BRDF: Theory and Implementation of Basic PBR Materials
// https://www.youtube.com/watch?v=gya7x9H3mV0&t=730s
//

// Surface geometry function.
float GGX_Schlick(float nv, float rough) {
    //float r = rough; // original
    float r = .5 + .5*rough; // Disney remapping.
    float k = (r*r)/2.;
    float denom = nv*(1. - k) + k;
    return max(nv, .001)/denom;
}

// Specular calculation.
vec3 getSpec(vec3 FS, float nh, float nr, float nl, float rough){

    // Microfacet distribution... Most dominant term.
    // Microfaceted normal distribution function.
    float alpha = pow(rough, 4.);
    float b = (nh*nh*(alpha - 1.) + 1.);
    float D = alpha/(3.14159265*b*b);    
    
    // Geometry self shadowing term.
    // G_Smith calculations.
    float g1_l = GGX_Schlick(nl, rough);
    float g1_v = GGX_Schlick(nr, rough);
    float G = g1_l*g1_v;
    
    // Combining the terms above.
    return FS*D*G/(4.*max(nr, .001))*3.14159265;
}

vec3 getDiff(vec3 FS, float nl, float type){

    // Diffuse calculations.
    vec3 diff = nl*(1. - FS); // If not specular, use as diffuse (optional)
    return diff*(1. - type); // No diffuse for metals.
}

 

///////////

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

//////

// Quick "point in quad" check. Used when subdividing nonconvex
// quads, if that option is chosen... It's a long story. The short 
// version being, "Why does everything have to be so difficult?" :D
bool inQuad(mat4x2 v, vec2 p) {
  
  bool hit = false;
    
  for(int i = 0; i < 4; i++) {
      
      vec2 p0 = v[i];
      vec2 p1 = v[(i + 3)%4];
      
  	  if ((p0.y>p.y != p1.y>p.y) &&  (p.x<(p1.x - p0.x)*(p.y-p0.y)/(p1.y - p0.y) + p0.x)){
         hit = !hit;
      }
  }
  
  return hit;
}

