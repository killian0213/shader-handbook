// Common (common) — Hexagon Cell Edge Weave by Shane
// https://www.shadertoy.com/view/3cGczz

/////////////////
// Variable defines.

// Shuffle vertices: The cyclic shuffle will rotate the array elements
// around in a circular fashion, like so:
// [1, 2, 3, 4, 5, 6] -> [6, 1, 2, 3, 4, 5] -> [5, 6, 1, 2, 3, 4], etc. 
// A random shuffle, will put them in any order. In this case, it will
// result in weave like connections.
// [1, 2, 3, 4, 5, 6] -> [3, 6, 1, 4, 2, 5], etc. 
//
// Shuffle type -- Random (weave): 0, Cyclic: 1.
#define SHUFFLE_TYPE 0

// Force the pattern to form closed loops. This option definitely
// looks nicer, but it isn't mandatory.
#define CLOSED_LOOPS

// Curve type -- Circular: 0, Hexagonal: 1, Dodecahedral: 2.
#define CURVE_TYPE 0

// Display visible edge vertices.
#define VERTICES

// Display the background detail.
#define BACKGROUND_DETAIL


// Flat top hexagon grid, or pointed... This is a bit of overkill,
// but it can sometimes be handy to have.
#define FLAT_TOP

////////////////////

// PI and 2PI constants.
#define PI 3.14159265
#define TAU 6.28318530718


// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }

// Global pattern scale.
const vec2 gSc = vec2(1, 1)/8.;



// Flat top hexagon, or pointed top.
#ifdef FLAT_TOP
const vec2 s = vec2(1.732, 1)*gSc;
#else
const vec2 s = vec2(1, 1.732)*gSc;
#endif

// Hexagon vertex IDs. They're useful for neighboring edge comparisons, etc.
// Multiplying them by "s" gives the actual vertex postion.
#ifdef FLAT_TOP
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

// Vertices and mid edge points.
vec2[6] v = vec2[6](vID[0]*s/12., vID[1]*s/12., vID[2]*s/12., 
                    vID[3]*s/12., vID[4]*s/12., vID[5]*s/12.);

// Multiplied by 12 to give integer entries only.
vec2[6] e = vec2[6](eID[0]*s/12., eID[1]*s/12., eID[2]*s/12., 
                    eID[3]*s/12., eID[4]*s/12., eID[5]*s/12.);

// Signed distance to a line passing through "a" and "b".
float distLineS(vec2 p, vec2 a, vec2 b){

   b -= a; 
   return dot(p - a, vec2(-b.y, b.x)/length(b));
}

// Hexagonal bound: Not technically a distance function, but it's
// good enough for this example.
float getHex(vec2 p){
    
    float poly = -1e5;
    p = abs(p);
    for(int i = 0; i<3; i++){
    
        float lnI = distLineS(p, v[i + 1], v[(i + 2)]);
        poly = max(poly, lnI);
    
    }
     
    return poly;
}

// Hexagonal grid coordinates. This returns the local coordinates and the cell's center.
// The process is explained in more detail here:
//
// Minimal Hexagon Grid - Shane
// https://www.shadertoy.com/view/Xljczw
//
vec4 getGrid(vec2 p){
    
    vec4 ip = floor(vec4(p/s, p/s - .5));
    vec4 q = p.xyxy - vec4(ip.xy + .5, ip.zw + 1.)*s.xyxy;
    // The ID is multiplied by 12 to account for the inflated neighbor IDs above.
    //return dot(q.xy/gSc, q.xy/gSc)<dot(q.zw/gSc, q.zw/gSc)? vec4(q.xy, ip.xy*12.) : vec4(q.zw, ip.zw*12. + 6.);
    return getHex(q.xy)<getHex(q.zw)? vec4(q.xy, ip.xy*12.) : vec4(q.zw, ip.zw*12. + 6.);

}

/////////////////////

// Unsigned distance to the segment joining "a" and "b".
// Based on IQ's line algorithm.
float distLine(vec2 p, vec2 a, vec2 b){
    p -= a; b -= a;
    float h = clamp(dot(p, b)/dot(b, b), 0., 1.);
    return length(p - b*h);
}


// Adx's considerably more concise version of Fizzer's circle solver.
// On a side note, if you haven't seen it before, his "Quake / Introduction" 
// shader is well worth the look: https://www.shadertoy.com/view/lsKfWd
void solveCircle(vec2 a, vec2 b, out vec2 o, out float r){
    
    vec2 m = a + b;
    o = dot(a, a)/dot(m, a)*m;
    r = length(o - a);
    
}

// Poloidal line shape. Round, hexagon, etc.
float dist2(in vec2 p){
    
    #if CURVE_TYPE == 0
        // Circular.
        return length(p);
    #elif CURVE_TYPE == 1
        // Sharp edged hexagon. 
        p = abs(p);
        #ifdef FLAT_TOP
        return max(p.y*.8660254 + p.x*.5, p.x);
        #else
        return max(p.x*.8660254 + p.y*.5, p.y);
        #endif    
    #else
       // Sharp edge dodecahedron.
        p = abs(p);
        vec2 hx = max(p*.8660254 + p.yx*.5, p.yx);
        return max(hx.x, hx.y);
    #endif
}

// Render a straight line between opposite edge vertices,
// or an arc between the others -- All lines cut perpendicularly
// to each edge.
float doLine(vec2 p, vec2 p0, vec2 p1){
     float ln;
     // Straight line.
     if(p0 == -p1) ln = distLine(p, p0, p1); 
     else {
        // Arc.
        vec2 o; float r;
        solveCircle(p0, p1, o, r);   
        // Circular distance.
        float arc = dist2(p - o) - r;
        arc = abs(arc); 
        ln = arc;
    }
    
    return ln;    
}
                