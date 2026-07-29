// Common (common) — Square Pentagon Tessellation by Shane
// https://www.shadertoy.com/view/WXGGzm

#define TAU 6.2831853
#define PI 3.14159265
 

 // Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21(vec2 f){
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
const vec2 gSc = vec2(1, 1)/1.25;


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
    
    
    if(pID==8){// && hash21(ip + .22)<.75
    
        // Subdividing the octagon.
       
        // Checkered reverse rotation.
        //int check = mod(ip.x + ip.y, 2.)==1.? 0 : 1;
        //int check = hash21(ip + .41)<.5? 0 : 1;
        const int check = 0;
       
    
        // For central square points.
        float eL2 = eL*sqrt(2.);
        // Rotate the points. // atan(1., 1. + 2./sqrt(2.)), or PI/8.
        mat2 mR = check==0? rot2(-PI/8.) : rot2(PI/8.); ////atan(1., 1. + 2./sqrt(2.));
        mat4x2 v2 = mR*v*eL2;
        
        
        vec4 ln4;
        float cSq = -1e5;
        
        for(int i = 0; i<4; i++){
        
            // Square edges.
            float lnI = distLineS(p, v2[i], v2[(i + 1)&3]);
            cSq = max(cSq, lnI);
            
            
            // Lines between the inner square vertices and two outer 
            // square vertices.
            ln4[i] = distLineS(p, v2[i], vP[(i*2 + 6 + check)&7]);
        }
        
        if(cSq<0.){
        
            // Central square.
            poly = cSq;
            pID = 4;
            //polyID = 1;  
            
            // Central square (or diamond), vertices.
            for(int i = 0; i<4; i++){
                vP[i] = v2[i];
            }
        
        }
        else {
             poly = max(poly, -cSq);
             
             // Partition the remainder into pentagons.
             ln4 = max(-ln4, ln4.wxyz);
             for(int i = 0; i<4; i++){
                 
                 if(ln4[i]<0.){
                 
                     // Inside the pentagon. I took everthing outside this loop, 
                     // but the GPU and the compiler didn't care, so I put it all 
                     // back in. :)
                 
                     poly = max(poly, ln4[i]);
                     
                     polyID = i + 2;
                     
                     id += vID[(i + 3)&3]*.5;
                     
                     pID = 5; // Pentagon.
                     
                     
                     // Pentagon vertices.
                    
                     // Outside octagon points. Using a temporary holder in order
                     // to avoid array positions being overwritten.                   
                     vP[0] = gVP[(i*2 + 4 + check)%8];
                     vP[1] = gVP[(i*2 + 5 + check)%8];
                     vP[2] = gVP[(i*2 + 6 + check)%8];
                    
                     // Inside diamond points.
                     vP[3] = v2[i];
                     vP[4] = v2[(i + 3)%4];
                     
                     // Shifting the coordinate system to the new center.
                     vec2 cntr = (vP[0] + vP[1] + vP[2] + vP[3] + vP[4])/5.;
                     //vec2 cntr = vP[1]*eL2*1.5;
                     vP[0] -= cntr;
                     vP[1] -= cntr;
                     vP[2] -= cntr;
                     vP[3] -= cntr;
                     vP[4] -= cntr;
                     p -= cntr;
                    
                     break;
                 
                 }
             
             }
             
       }

    }
    
    /*
    // Rounded polygon override. 
    poly = -1e5;
    for( int j = 0, i = pID - 1; j < pID; i = j, j++){
    
        poly = smax(poly, distLineS(p, vP[i], vP[j]), .025);
    
    }
    */
    
     
    
    //if(pID==5) poly = abs(poly + .015) - .015;
     
    //poly += .005; 
    
    // Saving the local coordinates.
    gP = p;
    
    // Distance ID and vertex ID.
    return vec4(poly, id, pID);
}


/////////////////////
 

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


// Smooth fract function.
float sFract(float x, float sf){
   
    x = fract(x);
    return min(x, (1. - x)*x*sf);
    
}


// The grungey texture -- Kind of modelled off of the metallic Shaderto texture,
// but not really. Most of it was made up on the spot, so probably isn't worth 
// commenting. However, for the most part, is just a mixture of colors using 
// noise variables.
vec3 GrungeTex(vec3 p){
    
    
 	// Some fBm noise.
    //float c = n2D(p*4.)*.66 + n2D(p*8.)*.34;
    float c = gradN3D(p*2.)*.57 + gradN3D(p*4.5)*.28 + gradN3D(p*10.)*.15;
    c = smoothstep(.15, .85, c);
    
    // Noisey bluish red color mix.
    vec3 col = mix(vec3(.35, .2, .02)*.9, vec3(.32, .4, .6), c);
    // Running slightly stretched fine noise over the top.
    col *= gradN3D(p*vec3(150, 350, 150))*.5 + .5; 
    
    // Using a smooth fract formula to provide some splotchiness... Is that a word? :)
    col = mix(col, col*vec3(.75, .95, 1.2), sFract(c*4., 12.));
    col = mix(col, col*vec3(1.2, 1, .8)*.8, sFract(c*5. + .35, 12.)*.5);
    
    // More noise and fract tweaking.
    c = gradN3D(p*8. + .5)*.7 + gradN3D(p*18. + .5)*.3;
    c = c*.7 + sFract(c*5., 16.)*.3;
    col = mix(col*.6, col*1.4, c);
    
    float fineNoise = gradN3D(p*128.);
    col *= sFract(fineNoise*2., 12.)*.3 + .9;
    
    // Clamping to a zero to one range.
    return clamp(col, 0., 1.);
    
}
