// Common (common) — Sparse Hexagon Grid Tree by Shane
// https://www.shadertoy.com/view/3sfXWl

#define PI 3.14159265

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }



#define FLAT_TOP_HEXAGON

// Square texture storage size.
// Changine this requires a shader reset.
const float GRID_SIZE = 32.;
const float scale = 1./GRID_SIZE;

// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21(vec2 f){

    //f = mod(f, GRID_SIZE);
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


// Signed distance to a line passing through A and B.
float distLineS(vec2 p, vec2 a, vec2 b){

   b -= a; 
   return dot(p - a, vec2(-b.y, b.x)/length(b));
}


#define ASIZE 6


#ifdef FLAT_TOP_HEXAGON
vec2[ASIZE] e = vec2[ASIZE](vec2(-1), vec2(-1, 1), vec2(0, 2), vec2(1), vec2(1, -1), vec2(0, -2));
#else
vec2[ASIZE] e = vec2[ASIZE](vec2(-2, 0), vec2(-1, 1), vec2(1), vec2(2, 0), vec2(1, -1), vec2(-1));
#endif                      
                      
                      
                      
// Hexagon vertex IDs. They're useful for neighboring edge comparisons, etc.
// Multiplying them by "s" gives the actual vertex postion.
#ifdef FLAT_TOP_HEXAGON
// Vertices: Clockwise from the left.
                     
// Multiplied by 12 to give integer entries only.
const vec2[6] vID = vec2[6](vec2(-4, 0), vec2(-2, 6), vec2(2, 6), 
                      vec2(4, 0), vec2(2, -6), vec2(-2, -6)); 

const vec2[6] eID = vec2[6](vec2(-3, 3), vec2(0, 6), vec2(3), 
                      vec2(3, -3), vec2(0, -6), vec2(-3));

#else
// Vertices: Clockwise from the bottom left. -- Basically, the ones 
// above rotated anticlockwise. :)

// Multiplied by 12 to give integer entries only.
const vec2[6] vID = vec2[6](vec2(-6, -2), vec2(-6, 2), vec2(0, 4), 
                      vec2(6, 2), vec2(6, -2), vec2(0, -4));

const vec2[6] eID = vec2[6](vec2(-6, 0), vec2(-3, 3), vec2(3, 3), vec2(6, 0), 
                      vec2(3, -3), vec2(-3, -3));

#endif


vec2 indexToDir(float i) {
    
    // Converts 0, 1, 2, 3, 4, 5 or 6 to the down-left, left, up-left, 
    // up-right, right, down-right, vectors respectively... for pointed
    // top hexagons, and slightly different directions for the flat top.
    return e[int(i)]; 
}

float dirToIndex(vec2 u) {
    
    // Converts the directions above back to indices.
    
    // The following would do it too.
    int i;
    for(i = 0; i<ASIZE; i++){ if(u == e[i]) break; }
    
    return float(i);
}

float rndDirIndex(vec3 ut){
    // Returns a random number based on 2D position and time.
    return mod(floor(72.*hash31(ut)), float(ASIZE));
}

vec2 rndDir(vec3 u) {
    // Returns a random direction.
    return indexToDir(rndDirIndex(u));
}

// Helper vector. If you're doing anything that involves regular triangles or hexagons, the
// 30-60-90 triangle will be involved in some way, which has sides of 1, sqrt(3) and 2.
#ifdef FLAT_TOP_HEXAGON
const vec2 s = vec2(1.7320508, 1);
#else
const vec2 s = vec2(1, 1.7320508);
#endif


/*
// The 2D hexagonal isosuface function: If you were to render a horizontal line and one that
// slopes at 60 degrees, mirror, then combine them, you'd arrive at the following. As an 
// aside, the function is a bound -- as opposed to a Euclidean distance representation, but
// either way, the result is hexagonal boundary lines.
float hex(in vec2 p){
    
    p = abs(p);
    
    #ifdef FLAT_TOP_HEXAGON
    // Below is equivalent to:
    //return max(p.x*.866025 + p.y*.5, p.y); 

    return max(dot(p, s*.5), p.y); // Hexagon.
    #else
    // Below is equivalent to:
    //return max(p.x*.5 + p.y*.866025, p.x); 

    return max(dot(p, s*.5), p.x); // Hexagon.
    #endif
    
}
*/

// This function returns the hexagonal grid coordinate for the grid cell, and the 
// corresponding hexagon cell ID .
vec4 getHex(vec2 p){
    
    // The hexagon centers: Two sets of repeat hexagons are required to fill in the space.
    
    #ifdef FLAT_TOP_HEXAGON
    vec4 hC = floor(vec4(p, p - vec2(1, .5))/s.xyxy) + .5;
    #else
    vec4 hC = floor(vec4(p, p - vec2(.5, 1))/s.xyxy) + .5;
    #endif    
    //vec4 hC = floor(vec4(p/s, p/s + .5));
    
    // Centering the coordinates with the hexagon centers above.
    vec4 h = vec4(p - hC.xy*s, p - (hC.zw + .5)*s);
    //vec4 h = p.xyxy - vec4(hC.xy + .5, hC.zw)*s.xyxy;
    
    
    // Nearest hexagon center (with respect to p). By the way, the unique ID (the .zw bit), 
    // needs to be multiplied by "s" to give the correct quantized position back. 
    // For example: float ns = noise2D(hID*s);
    //
    return dot(h.xy, h.xy)<dot(h.zw, h.zw) ? vec4(h.xy, hC.xy) : vec4(h.zw, hC.zw + .5);

}
