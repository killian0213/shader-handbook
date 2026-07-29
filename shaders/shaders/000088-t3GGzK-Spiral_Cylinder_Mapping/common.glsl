// Common (common) — Spiral Cylinder Mapping by Shane
// https://www.shadertoy.com/view/t3GGzK

#define TAU 6.2831853
#define PI 3.14159265
 
 
float tm;

 // Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21(vec2 f){

    // Wrapping to match the polar map on the cylinder. For this example only.
    f.y = mod(f.y, 6.); 
    
    uvec2 p = floatBitsToUint(f + 16384.);
    p = 1664525U*(p>>1U^p.yx);
    return float(1103515245U*(p.x^(p.y>>3U)))/float(0xffffffffU);
}


// Commutative smooth maximum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smax(float a, float b, float k){
    
   float f = max(0., 1. - abs(b - a)/k);
   return max(a, b) + k*.25*f*f;
}


////////////////////

// Unsigned distance to the segment joining "a" and "b".
float distLine(vec2 p, vec2 a, vec2 b){

    p -= a; b -= a;
    float h = clamp(dot(p, b)/dot(b, b), 0., 1.);
    return length(p - b*h);
}

 

// Signed line distance.
float distLineS(vec2 p, vec2 a, vec2 b){ 

 /* 
    // More correct signed line distance. Based on IQ's original, but with
    // a sign addition.
    
    //if(a == b) return -1e5;
    p -= a, b -= a;
    float h = clamp(dot(p, b)/dot(b, b), 0., 1.);
    // JT's GPU determinant-based sign. Not sure if it's faster, or not.
    //float s = determinant(mat2(b, p))<0.? -1. : 1.;
    // Unfortunately, the GPU "sign" function returns zero for certain pixel.
    // which we can't have for this function, so this is the workaround.
    float s = b.x*p.y<b.y*p.x? -1. : 1.;
    return length(p - b*h)*s;
  */ 
  
    // Cheap, line stepping. I tend to use this when I need the cycles.
    b -= a; 
    return dot(p - a, vec2(-b.y, b.x)/length(b));

}

// IQ's rectangle distance.
float sBox(in vec2 p, in vec2 b){
  
  vec2 d = abs(p) - b;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.));
}

// Global tile scale.
const vec2 gSc = vec2(1)/2.;


int polyID; // Polygon ID.
int pID; // Vertex number ID.

// Vertex point holders and local coordinates.
vec2[8] vP, gVP;
vec2 gP;

// Grid square vertex and mid edge ID.
const mat4x2 vID = mat4x2(vec2(-.5), vec2(-.5, .5), vec2(.5), vec2(.5, -.5));
const mat4x2 eID = mat4x2(vec2(-.5, 0), vec2(0, .5), vec2(.5, 0), vec2(0, -.5));

// Vertex and edge points.
//mat4x2 v, e;
//for(int i = 0; i<4; i++){ v[i] = vID[i]*gSc; e[i] = eID[i]*gSc; }
//
const mat4x2 v = mat4x2(vec2(-.5)*gSc, vec2(-.5, .5)*gSc, 
                        vec2(.5)*gSc, vec2(.5, -.5)*gSc);
const mat4x2 e = mat4x2(vec2(-.5, 0)*gSc, vec2(0, .5)*gSc, 
                        vec2(.5, 0)*gSc, vec2(0, -.5)*gSc);

// Octagon vertices. Precomputed prior to the raymarching loop.
void octagon(){
    
    float eL = .3;
    for(int i = 0; i<4; i++){
    
        // Clockwise from the bottom left.
        int ip1 = (i + 1)&3;
        vec2 eI0 = mix(v[i], v[ip1], 1. - eL);
        vec2 eI1 = mix(v[ip1], v[(i + 2)&3], eL);
        
        gVP[i*2] = eI0;
        gVP[i*2 + 1] = eI1; 
       
    }

}


// The subdivided octagon, diamond pattern.
vec4 distField(vec2 p){


    // Square grid ID and local coordinates.
    vec2 ip = floor(p/gSc);
    p -= (ip + .5)*gSc;
    
    // ID, set to the square's center.
    vec2 id = ip;
    
    
    // Edge length, as a percentage of the side length.
    float eL = .3;
 
    
    float poly = -1e5, oct = -1e5;
    
    // Vertices. Set them to the precomputed ones.
    vP = gVP;
    
    int sqIndex = -1;
    //float dia = 1e5;
    
    // Checking to see if we're inside a diamond. Usually, you'd break the
    // second you were inside a diamond, but doing it that way was slower...
    // Not sure why. I'll take another look later.
    for(int i = 0; i<4; i++){
    
        // Side diamonds.
        float ln4I = distLineS(p, vP[i*2], vP[i*2 + 1]);
        
        if(ln4I>0.){ sqIndex = (i + 1)&3; /*dia = -ln4I; break;*/ }
        
        oct = max(oct, ln4I);
       
    }
    
    
    // Octagon.
    float sq = sBox(p, gSc/2.);
    oct = max(oct, sq);
 
   
    if(sqIndex==-1){

        // Octahedron.
        poly = oct; //max(sq, -dia);//
        polyID = 1;
        pID = 8; 
        
    }
    else {
    
        //  Diamond.
    
        poly = -oct;//dia;//
        polyID = 0;
        pID = 4;
        
        id += vID[sqIndex];
        
         //vec2 cntr = vec2(0);
        for(int i = 0; i<4; i++){
            vP[i] = v[sqIndex] + eID[i]*eL*gSc*2.;
            //cntr += vP[i]/4.;
        }
        
        // Adjusting the local coordinate to the diamond center. If 
        // it were not for the rivots, this would not be necessary.
        vec2 cntr = v[sqIndex];
    
        vP[0] -= cntr; vP[1] -= cntr; vP[2] -= cntr; vP[3] -= cntr;
        p -= cntr;    
    }
    
 
    /*
    // Smooth polygons.
    poly = -1e5;
    for( int j = 0, i = pID - 1; j < pID; i = j, j++){
        poly = smax(poly, distLineS(p, vP[i], vP[j]), .02);
    }
    */
 
    // Saving the polygon coordinates for later use.
    gP = p;
    
    // Distance ID and vertex ID. 
    return vec4(poly, id, pID);
    
}
 
