// Common (common) — Subdivided Hexagon Floret by Shane
// https://www.shadertoy.com/view/3fcfWl


//////////////////

//Color scheme -- Brown and blue: 0, Spectrum paint palette: 1.
#define COLOR_SCHEME 0

// Subdivision. Subdivided florets or just the florets.
#define SUBDIV

// Random decorative holes.
#define HOLES

// Material -- Dielectric: 0, Metal (Anisotropic): 1. 
#define MATERIAL 0

// Global tile scale.
const float gSc = 1./1.5;

///////////////////

// PI and 2PI.
#define PI 3.14159265
#define TAU 6.28318530718

 

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }

 
// Hash without Sine -- Dave Hoskins
// https://www.shadertoy.com/view/4djSRW
// 1 out, 2 in...
float hash21(vec2 p) {
    p = fract(p*vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x*p.y);
}

/*
float hash21F(vec2 p){
    // Used, in some cases, to ensure nearly identical
    // float values are identical.
    p = floor(p*4096. + .001)/4096.;
    p = fract(p*vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x*p.y);
}
*/
 
// Commutative smooth maximum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smax(float a, float b, float k){
    
   float f = max(0., 1. - abs(b - a)/k);
   return max(a, b) + k*.25*f*f;
}


// Signed distance to a line passing through "a" and "b".
float distLineS(vec2 p, vec2 a, vec2 b){

   b -= a; 
   return dot(p - a, vec2(-b.y, b.x)/length(b));
}

// Line step only. No distance involved.
float lineStep(vec2 p, vec2 a, vec2 b){ 

   // Cheap, line stepping. I tend to use this when I need the cycles.
    b -= a; 
    return dot(p - a, vec2(-b.y, b.x));

}

 
//////////////////
 

/////////////////////////////
/////////////////////////////
// Just a line check; Negative on one side and positive on the other.
float lineCheck(vec2 p, vec2 a, vec2 b){

    b -= a; p -= a;
    return b.x*p.y - b.y*p.x;
	//return ((b.x - a.x)*(p.y - a.y) - (b.y - a.y)*(p.x - a.x));
    //return determinant(mat2(b - a, p - a));
}

/*
#define aN 6

float sdPolygon(in vec2 p, in vec2[aN] v, int num){
 
    //const int num = v.length();
    float d = dot(p - v[0], p - v[0]);
    float s = 1.;
    for( int i = 0, j = num - 1; i<num; j = i, i++ )
    {
        // distance
        vec2 e = v[j] - v[i];
        vec2 w =    p - v[i];
        vec2 b = w - e*clamp( dot(w, e)/dot(e, e), 0.0, 1.0 );
        d = min( d, dot(b,b) );
        
         
        // winding number from http://geomalgorithms.com/a03-_inclusion.html
        bvec3 cond = bvec3( p.y >= v[i].y, 
                            p.y < v[j].y, 
                            e.x*w.y > e.y*w.x );
        if( all(cond) || all(not(cond)) ) s = -s;  
         
    }
    
    return s*sqrt(d);
}
*/



// Flat top hexagon, or pointed top.
const vec2 s = vec2(1.732, 1)*gSc;


// Hexagon vertex IDs. They're useful for neighboring edge comparisons, etc.
// Multiplying them by "s" gives the actual vertex postion.

// Vertices: Clockwise from the left.
                     
// Multiplied by 12 to give integer entries only.
const vec2[6] vID = vec2[6](vec2(-4, 0), vec2(-2, 6), vec2(2, 6), 
                      vec2(4, 0), vec2(2, -6), vec2(-2, -6)); 

const vec2[6] eID = vec2[6](vec2(-3, 3), vec2(0, 6), vec2(3), 
                      vec2(3, -3), vec2(0, -6), vec2(-3));
 

// Vertices and mid edge points.
vec2[6] v, e;

 
// Hexagonal grid coordinates. This returns the local coordinates and the cell's center.
// The process is explained in more detail here:
//
// Minimal Hexagon Grid - Shane
// https://www.shadertoy.com/view/Xljczw
//
vec4 getGrid(vec2 p){
    
    // The two mutually offset coordinate systems. One for each hexagon.
    //
    // Two sets of repeat hexagons are required to fill in the space, and the two 
    // sets are stored in a "vec4" in order to group some calculations together. 
    // The hexagon center we'll eventually use will depend upon which is closest to the 
    // current point. Since the central hexagon point is unique, it doubles as the unique
    // hexagon ID.
    vec4 h = vec4(p, p - s/2.);
    // Their respective IDs. iC*s.xyxy represent the cell centers.
    vec4 iC = floor(h/s.xyxy) + .5;
     
    // Centering the coordinates with hexagon centers above to
    // produce respective local coordinates.
    h -= iC*s.xyxy; 

 
    // Determine the nearest hexagon cell, then return the local coordinates
    // and the integer IDs. Multiplying the ID by "s" will give you the
    // position based hexagon center.
    //
    // The ID is multiplied by 12 to account for the inflated neighbor IDs above.
    return dot(h.xy, h.xy)<dot(h.zw, h.zw)? 
           vec4(h.xy, iC.xy*12.) : vec4(h.zw, iC.zw*12. + 6.);
}


int polyID; // Polygon ID.
int pID; // Vertex number ID.

int tID; // Floret petal ID.

// Vertex point holders and local coordinates.
vec2[6] vP;
vec2 gP;


// Polygon center.
vec2 gCntr;
// Direction ray. One of the annoyances of traversal methods is having
// to rotate the direction ray to match local coordinate direction.
vec3 svRd;

 
// The subdivided octagon, diamond pattern.
vec4 distField(vec2 p){

/////////

    
    const float ang = atan(sqrt(3.)/5.); // Rotation angle.
    const float invR = 2./sqrt(7.); // Scaling factor.
    const float cA = cos(ang), sA = sin(ang);
    const mat2 mR = mat2(cA, sA, -sA, cA);
    const mat2 mRInv = mat2(cA, -sA, sA, cA);


    // The vertex and edge IDs are multiplied by 12, so we're factoring that in.
    const vec2 sDiv12 = s/12.;
    
    /*
    // Precalculate.
    mat2x2 v, e;

    // Vertices and mid edge points. 
    
    for(int i = 0; i<2; i++){
        v[i] = vID[i]*sDiv12;
        e[i] = mR*(eID[i]*sDiv12);     
    } 
    */
    // We're using repeat polar tricks, so only two of the six
    // vertex and edge points are required.
    const mat2x2 v = mat2x2(vID[0]*sDiv12, vID[1]*sDiv12);
    const mat2x2 e = mat2x2(mR*(eID[0]*sDiv12), mR*(eID[1]*sDiv12));  
  
    
    // The five petal vertices -- Running clockwise from the center.
    // Note the dummy sixth vertex, which is set to the first one.
    // It's a simple trick to avoid using modulos in the calculations.
    //
    vP[0] = vec2(0); // Petal tip (hexagon center).
    vP[1] = v[0]*invR; // Shorter outer petal vertex.
    vP[2] = mRInv*v[0]; // Longer inner petal vertex.
    vP[3] = mR*v[1]; // Longer inner petal vertex.
    vP[4] = v[1]*invR; // Shorter outer petal vertex.
    vP[5] = vec2(0); // Back to the start. Not a sixth vertex.
      
    
    // Hexagonal grid coordinates.
    vec4 p4 = getGrid(p);
    vec2 id = p4.zw; 
  
    
    // Rotate the local hexagon cell coordinates.
    p4.xy = mR*p4.xy;
    
    // Rotate the unit direction ray to match. Traversal related.
    svRd.xy = (mR)*svRd.xy;

 
     
    // Subdivided polygon ID.
    pID = 5;
    
    
    // Loop through the petals.
    // for(int i = 0; i<6; i++){

  
    // Using the partitioning angle to determine which of the six floret 
    // radial domains the pixel is inside of.
    int i = int(floor(fract(atan(p4.x, p4.y)/TAU)*6. - .5) + 2.)%6;//281
    // Rotating the local coordinates to match the domain.
    p4.xy = rot2(TAU/6.*float(i))*p4.xy;
   
    /// Unit direction ray.
    svRd.xy = rot2(TAU/6.*float(i))*svRd.xy;
    
 
    tID = i; 


    // Completing the florets.
    float lnI2 = lineCheck(p4.xy, vP[1], vP[2]);
    float lnI2B = lineCheck(p4.xy, vP[3], vP[4]);
    // Floret on the left sloped partition line.
    if(lnI2>0.){

        p4.xy -= e[0]*2.;
        p4.xy = rot2(-TAU/2.)*p4.xy;
        //p4.xy = p4.xy*vec2(-1, 1);

        id += eID[tID]*2.; 
        tID = (tID + 3)%6;
   
        svRd.xy = rot2(-TAU/2.)*svRd.xy;

    }

     // Floret on the right sloped partition line.
    if(lnI2B>0.){

        int ip1 = (tID + 1)%6;
    
        p4.xy -= e[1]*2.;
        p4.xy = rot2(-TAU*2./6.)*p4.xy;
    
        tID  = (tID + 4)%6;
        id += eID[ip1]*2.; 
   
        svRd.xy = rot2(-TAU*2./6.)*svRd.xy;
        
    }
       
     // Polygon center.
    vec2 oCntr = mix(vP[1], vP[4], .5);
    //vec2 cntr = vec2(0);
    //for(int i = 0; i<pID; i++) cntr += rot2(float(i)*TAU/6.)*vP[i]/float(pID);
    //id += cntr*12.;
    
    
    
    
    #ifndef SUBDIV 
    // No subdividion ID.
    id = id*sDiv12 + rot2(-float(tID)*TAU/6.)*oCntr;
    #endif
    
    
    // Subdivide the floret (petal) into five pie-slice sections.
    #ifdef SUBDIV
    
    pID = 4;
    
    // Vertex mid-way positions.
    vec2[6] eP;
    eP[0] = mix(vP[0], vP[1], .75);
    eP[1] = mix(vP[1], vP[2], .5);
    eP[2] = mix(vP[2], vP[3], .5);
    eP[3] = mix(vP[3], vP[4], .5);
    eP[4] = mix(vP[0], vP[4], .75);
    eP[5] =  eP[0]; // First point.
    
    // Lines eminating from the center to the outer cell positions.
    float[6] divLn;
    for(int i = 0; i<6; i++){
       divLn[i] = lineStep(p4.xy, oCntr, eP[i]);
    }    
    
    // Determining which pie-slice polygon we're inside of.
    // I could use polar coordinates to speed this up, but this 
    // is easier to read.
    for(int i = 0; i<5; i++){
        
        float div = max(divLn[i], -divLn[(i + 1)]);  
        
        if(div<0. || i==4){
            
            // CSG. Not used here.
            //poly = max(poly, -div);
            
            // New polygon vertices.
            vP[2] = vP[(i + 1)]; // Set this one first to avoid overwriting.
            vP[0] = oCntr;
            vP[1] = eP[i];            
            vP[3] = eP[(i + 1)];
            vP[4] = vP[0]; // Dummy first vertex.
            
            // Polygon center.  
            oCntr = (vP[0] + vP[1] + vP[2] + vP[3])/4.;
            // New polygon center-based ID. Each are globally rotated
            // according to which floret we're subdividing.
            id = id*sDiv12 + rot2(-float(tID)*TAU/6.)*oCntr;
            
            // Polygon ID -- Zero for the large center one.
            polyID = 4 - i;
            
            break;
        }
    
    } 
    #endif
    
    
    // Use the polygon vertices to render the shape.
    
    //float poly = sdPolygon(p4.xy, vP, pID);
    
    // Hacky rounded polygon calculation. IQ's specialized function
    // would be better, but this will do.
    float poly = -1e5;
    float smF = .02;
    for(int i = 0; i<pID; i++){
       poly = smax(poly, distLineS(p4.xy, vP[i], vP[(i + 1)]), smF);
    }
     
    // Global polygon center.
    gCntr = oCntr;
    
    
    #ifdef HOLES
    // Decorative holes to break things up.
    float ew = .018*gSc;
    if(polyID==0) ew *= 1.5;
    if(hash21(id + .11)<.5) poly = max(poly, -(length(p4.xy - oCntr) - ew));
    #endif
     
    // Saving the local coordinates.
    gP = p4.xy;
    
   
    // Distance, ID and vertex number.
    return vec4(poly, id, pID);
}

////////////////////////////////
////////////////////////////////


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

//////////////////////////////////////
//////////////////////////////////////

// This is a nice color wheel palette designed to emulate physical paint 
// colors. I can thank MLA for the reference. I went to the trouble to code 
// this up via color cube vertex interpolation methods from original sources, 
// which allows for shade control and so forth, but this is much easier to use.
vec3 paintPalette(float h){

    vec3 col[] = vec3[](
        vec3(254, 39, 18),  // Red
        vec3(252, 96, 10),  // Red-Orange
        vec3(251, 153, 2),  // Orange
        vec3(252, 204, 26), // Yellow-Orange
        vec3(254, 254, 51), // Yellow
        vec3(178, 215, 50), // Yellow-Green
        vec3(102, 176, 50), // Green
        vec3(52, 124, 152), // Blue-Green
        vec3(2, 71, 254),   // Blue
        vec3(68, 36, 214),  // Blue-Purple
        vec3(134, 1, 175),  // Purple
        vec3(194, 20, 96)); // Red-Purple
    
    int index = int(mod(floor(h*12.), 12.));
    vec3 col0 =  col[index];
    vec3 col1 =  col[(index + 1)%12];
    return mix(col0, col1, fract(h))/255.;
    
    // Float modulo to deal with potential negatives.
    //return col[int(mod(h*12., 12.))]/255.;
}


/////////////////////
/////////////////////

// Dave's hash function. More reliable with large values, but will still eventually 
// break down.
//
// Hash without Sine.
// Creative Commons Attribution-ShareAlike 4.0 International Public License.
// Created by David Hoskins.
// vec3 to vec3.
vec3 hash33G2(vec3 p){

    
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

// Gradient noise. Just a rewriting of IQ's function.
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
    
    // I rewrote this in loop form, for fun... There'd be better ways
    // to do this. I'll rethink it later.
    const mat4x2 v = mat4x2(vec2(0), vec2(0, 1), vec2(1, 0), vec2(1));
    vec4 a, b, h;
    for(int j = 0; j<4; j++){
        
        a.x = dot(hash33G2(i + vec3(v[j], 0)), p - vec3(v[j], 0)); // Front.
        b.x = dot(hash33G2(i + vec3(v[j], 1)), p - vec3(v[j], 1)); // Back.
        a = a.yzwx; b = b.yzwx;
    }
    
    // Interpolate between the front and back plane vertex gradient-based values.
    h = mix(a, b, u.z);
    // Interpolate the results between the bottom and top.
    h.xy = mix(h.xz, h.yw, u.y);
    // Finally, interpolate from left to right, then normalize.
    return mix(h.x, h.y, u.x)*.5 + .5;

}

// Layered noise function.
float fBm(in vec3 p, float lacu, float fallofff, int N){
    
    // Rewriting the fBm function to lower compile times.
    float ns = 0., sum = 0., a = 1.;
    vec3 offs = vec3(-.002, .001, -.001);
    for(int i = 0; i<N; i++){    
        ns += gradN3D(p + offs)*a;
        sum += a;
        p *= lacu;
        a *= fallofff;
        // Sometimes, a minor offset on each iteration can help.  
        offs = offs.yzx;  
    }
    
    return ns/sum;
 
}


 