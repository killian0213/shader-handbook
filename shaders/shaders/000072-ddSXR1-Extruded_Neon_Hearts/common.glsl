// Common (common) — Extruded Neon Hearts by Shane
// https://www.shadertoy.com/view/ddSXR1

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }



float hash21(vec2 p){ 
    
    return fract(sin(dot(p, vec2(27.617, 57.643)))*43758.5453); 
    
    /*
    // Attempting to fix accuracy problems on some systems by using
    // a slight variation on Dave Hoskin's hash formula, here:
    // https://www.shadertoy.com/view/4djSRW
    vec3 p3 = fract(vec3(p.xyx)*.1031);
    p3 += dot(p3, p3.yzx + 43.123);
    return fract((p3.x + p3.y)*p3.z);
    */
    
    /*
    // IQ's vec2 to float hash.
    // An accuracy hack for this particular example. Unfortunately, 
    // "1. - 1./3." is not always the same as "2./3." on a GPU.
    p = floor(p*32768.)/32768.;
    return fract(sin(dot(p, vec2(27.617, 57.743)))*43758.5453); 
    */
}

// IQ's vec2 to float hash.
float hash31(vec3 p){  
    return fract(sin(dot(p, vec3(113.619, 57.583, 27.897)))*43758.5453); 
}


// Commutative smooth minimum function. Provided by Tomkh and taken from 
// Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smin(float a, float b, float r)
{
   float f = max(0., 1. - abs(b - a)/r);
   return min(a, b) - r*.25*f*f;
}

// Commutative smooth maximum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smax(float a, float b, float k){

   float f = max(0., 1. - abs(b - a)/k);
   return max(a, b) + k*.25*f*f;
}
// Signed distance to a line passing through A and B.
float distLineS(vec2 p, vec2 a, vec2 b){

   b -= a; 
   return dot(p - a, vec2(-b.y, b.x)/length(b));
}


// Flat top hexagon, or pointed top.
#ifdef FLAT_TOP
const vec2 s = vec2(1.732, 1);
#else
const vec2 s = vec2(1, 1.732);
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
/*
// Hexagonal bound: Not technically a distance function, but it's
// good enough for this example.
float getHex(vec2 p){
    
    // Flat top and pointed top hexagons.
    #ifdef FLAT_TOP
    return max(dot(abs(p.xy), s/2.), abs(p.y*s.y));
    #else   
    return max(dot(abs(p.xy), s/2.), abs(p.x*s.x));
    #endif
}
*/

// Signed distance to a regular hexagon, with a hacky smoothing variable thrown
// in. -- It's based off of IQ's more exact pentagon method.
float getHex(in vec2 p, float r, in float sf){
   
      #ifdef FLAT_TOP
      // Flat top.
      const vec3 k = vec3(-.8660254, .5, .57735); // pi/6: cos, sin, tan.
      #else
      // Pointed top.
      const vec3 k = vec3(.5, -.8660254, .57735); // pi/6: cos, sin, tan.
      #endif
     
      // X and Y reflection.  
      p = abs(p); 
      p -= 2.*min(dot(k.xy, p), 0.)*k.xy;

      r -= sf;
      // Polygon side.
      #ifdef FLAT_TOP
      // Flat top.
      return length(p - vec2(clamp(p.x, -k.z*r, k.z*r), r))*sign(p.y - r) - sf;
      #else
      // Pointed top.
      return length(p - vec2(r, clamp(p.y, -k.z*r, k.z*r)))*sign(p.x - r) - sf;
      #endif
    
}

// IQ;s signed distance to an equilateral triangle.
// https://www.shadertoy.com/view/Xl2yDW
float getTri(in vec2 p, in float r){

    const float k = sqrt(3.0);
    p.x = abs(p.x) - r;
    p.y = p.y + r/k;
    if(p.x + k*p.y>0.) p = vec2(p.x - k*p.y, -k*p.x - p.y)/2.;
    p.x -= clamp(p.x, -2.*r, 0.);
    return -length(p)*sign(p.y);
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
    return dot(q.xy, q.xy)<dot(q.zw, q.zw)? vec4(q.xy, ip.xy*12.) : vec4(q.zw, ip.zw*12. + 6.);
    //return getHex(q.xy)<getHex(q.zw)? vec4(q.xy, ip.xy) : vec4(q.zw, ip.zw + .5);

}



// Standard polar partitioning.
vec2 polRot(vec2 p, inout float na, float aN){

    float a = atan(p.y, p.x);
    na = mod(floor(a/6.2831*aN), aN);
    float ia = (na + .5)/aN;
    p *= rot2(-ia*6.2831);

    return p;
}
 