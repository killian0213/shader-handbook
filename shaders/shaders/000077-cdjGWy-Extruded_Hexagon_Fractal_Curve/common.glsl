// Common (common) — Extruded Hexagon Fractal Curve by Shane
// https://www.shadertoy.com/view/cdjGWy


// Fractal iteration depth. I'm only prividing 2 here, so the
// numbers are 0 for the base object or 1.
int cInd = 1;

// Display the closed curve... Technically, the dark edges are the closed
// curve, but this presents it more fully.
#define CURVE

// Arc shape. Circular: 0, Hexagon: 1.
#define SHAPE 0

// Color: Terracotta: 0, Lime: 1, Blue: 2, White: 3.
#define COLOR 0


//////////////
// Background pattern code.
// vec2 to float hash.
float hash21( vec2 p ){ 

    return fract(sin(dot(p, vec2(1, 113)))*45758.5453); 
    // Animation, if preferred.
    //p.x = fract(sin(dot(p, vec2(1, 113)))*45758.5453);
    //return sin(p.x*6.2831853 + iTime)*.5 + .5; 
}

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// Arc or blob shape.
float dist(vec2 p){
  
    #if SHAPE == 0
    return length(p); // Circle.
    #else
    p = abs(p);
    return max(p.y*.8660254 + p.x*.5, p.x); // Hexagon.
    #endif

}


// Helper vector. If you're doing anything that involves regular triangles or hexagons, the
// 30-60-90 triangle will be involved in some way, which has sides of 1, sqrt(3) and 2.
const vec2 s = vec2(1, 1.7320508);


// This function returns the hexagonal grid coordinate for the grid cell, and the corresponding 
// hexagon cell ID -- in the form of the central hexagonal point. That's basically all you need to 
// produce a hexagonal grid.
vec4 getHex(vec2 p){
    
    // The hexagon centers.

    vec4 hC = floor(vec4(p, p - vec2(.5, 1))/s.xyxy) + .5;
    
    // Centering the coordinates with the hexagon centers above.
    vec4 h = vec4(p - hC.xy*s, p - (hC.zw + .5)*s);
    
    // Nearest hexagon center (with respect to p) to the current point. 
    return dot(h.xy, h.xy)<dot(h.zw, h.zw) ? vec4(h.xy, hC.xy) : vec4(h.zw, hC.zw + .5);

}

// A pretty simple hexagon Truchet pattern.
//
// I'm using the standard arc pattern for the fractal hexagon curve option, 
// and the blob equivalent for the non-curve (or blob) option.
float bgPat(vec2 p){

    // The hexagon grid.
    vec4 h = getHex(p + vec2(0, s.y/3.));
    
     // Unique random number.
    float rnd = hash21(h.zw + .11);
    #ifdef CURVE
    h.xy *= rot2(3.14159/3.*floor(rnd*72.));
    #else
    if(rnd<.5) h.y = -h.y;
    #endif
    
    // Distances from three equispapced hexagon vertices.
    vec2 v = vec2(0, s.y/3.);
    
    // Three circles at the vertices.
    vec3 cDist = vec3(dist(h.xy - v), 
                      dist(h.xy - rot2(6.2831/3.)*v), 
                      dist(h.xy - rot2(2.*6.2831/3.)*v)); 
    
    
    // Random circle size.
    vec3 r = vec3(s.y/6.);
    #if SHAPE != 0
    r *= .8660254; // Readjusting the radius for hexagonal shapes.
    #endif
    
    #ifdef CURVE
    // Randomly replace some of the arcs with end point dots.
    for(int i = 0; i<3; i++){
       
        if(hash21(h.zw + float(i + 1)/6.)<.2){

            r.x = 0., 
            cDist.x = dist(h.xy - rot2(-6.2831/12. + float(i)*6.2831/3.)*v*.8660254);
            cDist.x = min(cDist.x, dist(h.xy - rot2(6.2831/12. + float(i)*6.2831/3.)*v*.8660254));
        }
        
        r = r.yzx;
        cDist = cDist.yzx;
    }
    #endif
   
    cDist -= r;
    
    float d = min(min(cDist.x, cDist.y), cDist.z);
    #ifdef CURVE
    d = abs(d) - .15; // Circles to arcs.
    #else
    if(rnd<.5) d = -d; // Flip the pattern for the blob version.
    #endif
    
    
    return d;

}

