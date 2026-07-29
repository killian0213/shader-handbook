// Common (common) — Mondrian Style Overlay by Shane
// https://www.shadertoy.com/view/33ByDw

// PI and 2PI.
#define PI 3.14159265
#define TAU 6.28318530718


// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }

// Hash without Sine -- Dave Hoskins
// https://www.shadertoy.com/view/4djSRW
// 1 out, 2 in...
float hash21(vec2 p){

    p = fract(p*vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x*p.y);
}

 
// Signed distance to a line passing through "a" and "b".
float distLineS(vec2 p, vec2 a, vec2 b){

   if(b==a) return 1e5; // For the zero case in this example.
   b -= a;
   return dot(p - a, vec2(-b.y, b.x)/length(b));
}


// IQ's 2D box function.
float sBox(in vec2 p, in vec2 b){
  
  vec2 d = abs(p) - b;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.));
    
}
 

// Return the distance of ray origin to the line intersection point
// in the direction of the unit direction ray. The line is infinite,
// meaning it exceeds the "a" and "b" boundary points.
//
// In this case, the intersection is guaranteed, so we can take 
// some shortcuts.
float lineIntersect(vec2 ro, vec2 rd, vec2 a, vec2 b){

    vec2 v1 = ro - a;
    vec2 v2 = b - a;
    vec2 v3 = vec2(-rd.y, rd.x);

    float dotP = dot(v2, v3);
    
    return(v2.x*v1.y - v2.y*v1.x)/dotP;

}

// IQ's nicely coded polygon function -- that has been 
// modified and stripped back to suit this example.
//
// Other distances here:
// https://iquilezles.org/articles/distfunctions2d
//
#define NV 16
//

float sdPoly(in vec2 p, in vec2[NV] v, int num){

    //const int num = v.length() - 1;
    float d = dot(p - v[0], p - v[0]);
    float s = 1.;
    for( int i = 0, j = num - 1; i < num; j = i, i++){
    
        // distance
        vec2 e = v[j] - v[i];
        vec2 w =    p - v[i];
        vec2 b = w - e*clamp(dot(w, e)/dot(e, e), 0., 1. );
        //if(e==vec2(0)) b = vec2(1e5);
        d = min( d, dot(b,b));
    }
    
    // IQ's original contains winding information, but it's not
    // necessary in this example, so we can save some calculations.
    return -sqrt(d);
}

/*
// Commutative smooth minimum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smin(float a, float b, float k){

   float f = max(0., 1. - abs(b - a)/k);
   return min(a, b) - k*.25*f*f;
}

// A hacky modification to IQ's polygon function to produce smooth edges. 
float sdPolySm(in vec2 p, in vec2[NV] v, int num){

    //const int num = v.length() - 1;
    float d = sqrt(dot(p - v[0], p - v[0]));
    float s = 1.;
    for( int i = 0, j = num - 1; i < num; j = i, i++){
    
        // distance
        vec2 e = v[j] - v[i];
        vec2 w =    p - v[i];
        vec2 b = w - e*clamp(dot(w, e)/dot(e, e), 0., 1. );
        //if(e==vec2(0)) b = vec2(1e5);
        d = smin( d, sqrt(dot(b,b)), .01);
       
        
        // winding number from http://geomalgorithms.com/a03-_inclusion.html
        bvec3 cond = bvec3( p.y>=v[i].y, 
                            p.y <v[j].y, 
                            e.x*w.y>e.y*w.x );
        if( all(cond) || all(not(cond)) ) s=-s; 

    }
    
    return (d)*s;
}
*/ 
 


