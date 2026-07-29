// Common (common) — Hexagon Grid Arc Subdivision by Shane
// https://www.shadertoy.com/view/WcVXz1

//#define STATIC

// PI and 2 PI.
#define PI 3.14159265
#define TAU 6.2831853 


///// DEFINES ////////

// Subdivide the curved pillar objects.
#define SUBDIV_PILLAR

// Subdivide the curved vertex triangles.
#define SUBDIV_TRI

// Two color schemes: Pink and green: 0, Blue and purple: 1.
#define COLOR 1

// Displaying the underlinig hexagon grid and vertices upon which the pattern
// is built upon. This isn't part of the design, but merely a visual aid to 
// help decipher the construction, for anyone who's interested.
//#define SHOW_GRID



//////////////////////////////

// Global time variable.
float tm;

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21(vec2 f){

    // The first line relates to ensuring that icosahedron vertex identification
    // points snap to the exact same position in order to avoid hash inaccuracies.
    uvec2 p = floatBitsToUint(f + 16384.);
    p = 1664525U*(p>>1U^p.yx);
    return float(1103515245U*(p.x^(p.y>>3U)))/float(0xffffffffU);
}

/*
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
*/

////////////////////////////////
////////////////////////////////

// More correct signed line distance. Based on IQ's original, but with
// a sign addition.
float distLineS(vec2 p, vec2 a, vec2 b){ 
  
    //if(a == b) return -1e5;
    p -= a, b -= a;
    float h = clamp(dot(p, b)/dot(b, b), 0., 1.);
    // JT's GPU determinant-based sign. Not sure if it's faster, or not.
    //float s = determinant(mat2(b, p))<0.? -1. : 1.;
    // Unfortunately, the GPU "sign" function returns zero for certain pixel.
    // which we can't have for this function, so this is the workaround.
    float s = b.x*p.y<b.y*p.x? -1. : 1.;
    return length(p - b*h)*s;
     
}

/*
// Signed distance to a line passing through A and B.
float distLineSF(vec2 p, vec2 a, vec2 b){

   //if(a == b) return -1e5;
   b = min(b - a, 1.);
   return dot(p - a, vec2(-b.y, b.x)/length(b));
}



// IQ's 2D line formula.
float distLine(vec2 p, vec2 a, vec2 b){ 

    p -= a, b -= a;
    float h = clamp(dot(p, b)/dot(b, b), 0., 1.);
    return length(p - b*h); 
}
*/

const float gSc = 1./2.;

//#define FLAT_TOP

// Flat top hexagon, or pointed top.
#ifdef FLAT_TOP
const vec2 s = vec2(1.732, 1)*gSc;
#else
const vec2 s = vec2(1, 1.732)*gSc;
#endif


// Vertices and mid edge points.
vec2[6] v, e;

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


vec2 gP;
float gPoly;
float gVert;

vec4 getPattern(vec2 p){

 
    // Hexagonal grid coordinates.
    vec4 p4 = getGrid(p);

    vec2 id0 = p4.zw;
 
    
    
    
    // Smoothly rotating back and forth between two angles. How to arrange
    // to do this, and what angles are choosen is up to the user.
    float ttm = tm/8. + .5;
    float a = (mod(floor(ttm), 2.) + smoothstep(0., .2, fract(ttm)))/2.;
    if(fract(ttm/2.)<.5) a = 1. - a;
 
    
    // This entire pattern is based on randomly rotating vectors from the center
    // of each hexagon to a point beyond the hexagon boundary, then rendering arcs 
    // from that point in such a way that it intersects one of the boundary vertices. 
    // The following is the random matrix that will act on the hexagon's mid-edge 
    // points to create the point... By the way, the aforemention process is pretty 
    // easy, but not so easy to comprehend without a picture.
    mat2 mR = rot2(-PI/7.*a)*1.8;
    
    // Calculating the radius of the circle arcs. All are the same, so you only
    // need to determine one. The first one will do, which is the distance from
    // the first random offset point to the second neighboring vertex:
    // e[0]*2. + v[2] = v[1]*2;
    float cirR = length(mR*e[0] - v[1]*2.);
    
    
    // All six inner arcs.
    float[6] vArc;  
    
    for(int i = 0; i<6; i++){
    
        // Constructing the inner arc subdivision lines. Create a random line from 
        // the hexagon center to the inside of the neighboring hexagon. The line's 
        // end point will represent the circle center, and the distance from it to 
        // one of the neighboring vertices (see above) will be its radius.
        vec2 rndOffsPnt = mR*e[i];
        //float cirR = length(rndOffsPnt - v[(i + 1)%6]*2.);
        vArc[i] = length(p4.xy - rndOffsPnt) - cirR;
        
    }
    
    float poly = -1e5;
       
    int pID = 0;
    
    // Set the polygon ID to the inner hexagon.
    int polygonID = 6;
    
 
    //for(int k = -1; k<2; k++){
    //    int i = int(mod((atan(p4.x, p4.y)/TAU + .25)*6. + float(k), 6.));
    
    for(int i = 0; i<6; i++){
    
       // Using two neighboring arc lines to partition off this segment.
       float arcI = max(vArc[i], -vArc[(i + 5)%6]);
      
       // Wedge partitioning.
       if(arcI<0.){
       
           poly = arcI;
           pID = i;
         
          //p4.zw += vID[(i + 1)%6];
          
           // We're on the outside of the inner hexagon, so we 
           // have some partitioning to do.
           polygonID = i;
           
           pID = pID%12; 
  
           
           break;
       }
       else {
       
           // Central hexagon.
           // Cut away the next side.
           poly = max(poly, -arcI);
            
       }
 
    }   
    
    
    if(polygonID<6){
    
        int i = polygonID;
    
        // Pillar and vertex triangle partitioning.
        //
        // The outer line arcs involves moving the center to that of a neighboring
        // hexagon (the one on the left, in this case), then rendering the arc 
        // (the third one, "e[(i + 2)%6]") from there.
        vec2 cC = mR*e[(i + 2)%6]; //5 //3
        cC += e[i]*2.;
        float lnOuter = -(length(p4.xy - cC) - cirR);
   
        // Inner and outer arc subdivion.
        if(lnOuter<0.){
            // Inside (pillar).
            poly = max(poly, lnOuter);
            p4.zw = id0 + eID[(i + 0)%6];
            pID = 1;
        }
        else {
            // Outside (triangle).
            poly = max(poly, -lnOuter);
  
            /* 
            // Completing the triangle arcs. We don't seem to need
            // them, but I'm keeping them around for later.
            
            // First neighbor, fourth arc.
            vec2 cC = mR*e[(i + 4)%6]; //5 //3
            cC += e[(i + 1)%6]*2.;
            float lnn = length(p4.xy - cC) - cirR;
            poly = max(poly, (lnn));
            // Second neighbor, first arc.
            cC = mR*e[(i + 2)%6]; //5 //3
            cC += e[i]*2.;
            lnn = length(p4.xy - cC) - cirR;
            poly = max(poly, (lnn)); 
            */  

            // Edge ID.
            //p4.zw = id0 + eID[i];
            
            // Vertex ID.
            p4.zw = id0 + vID[(i + 1)%6];

            pID = 2;

        }
      
        

        #ifdef SUBDIV_PILLAR
        // Pillar subdivision. 
        if(pID==1)
        {

            // Fifth neighbor, first arc.
            vec2 cC = mR*e[(i + 1)%6]; 
            cC += e[(i + 5)%6]*2.;
            float lnn = length(p4.xy - cC) - cirR;
            float ln2 = -lnn; 

            //float ln2  = -vArc2[(i + 5)%6]; // Horizontal.
            //float ln2 = hexagon;//vArc[(i + 1)%6]+.059; // Vertical.
            // float ln2  = min(vArc2[(i + 2)%6], -vArc[(i + 2)%6]);
            //float ln2  = min(vArc2[(i + 2)%6], vArc[(i + 2)%6]);
            // float ln2  = max(vArc2[(i + 2)%6], vArc[(i + 2)%6]);
            //ln2 = max(ln2, max(hexagon, vArc[(i + 2)%6]));
            if(ln2<0.){
                   // Inner
                   poly = max(poly, ln2);
                   p4.zw += eID[(i + 4)%6]/2. + vID[(i + 3)%6]/8.; // Horizontal.
                  // p4.zw += float(i)/6.;  // Vertical.
            }
            else {

                poly = max(poly, -ln2);

                // Upper bound   
                // First neighbor, fourth arc. 
                vec2 cC = mR*e[(i + 4)%6]; //5 //3
                cC += e[(i + 1)%6]*2.;
                float lnn = length(p4.xy - cC) - cirR;
                poly = max(poly, (lnn));          

                //p4.zw +=  eID[(i + 1)%6]/2.;
               //p4.zw += float((i + 3)%6)/6.;  // Vertical.

                 pID = 3;
           }

           //poly = max(poly, hexagon);

        }
        #endif
          
        
        #ifdef SUBDIV_TRI
        // Triangle sudivision.
        if(pID==2){
        
            //poly = max(poly, hexagon);
 
            // Subdividing the triangular partitions that are positioned around the
            // hexagonal vertices. Essentially, we're looking at the neighboring
            // hexagonal cells, then deciding which central arcs cuts the triangle 
            // into three. They all originate from neighboring hexagon grids, so it's 
            // necessary to decipher which ones. You can follow these with your eyes, 
            // which gets easier, once you get the hang of it. :)
           
            // Neighbors are clockwise, starting from the left. Go to the left neighbor, 
            // then move to the first neighbor above that. -- This one threw me for a 
            // while.
            
            
            vec3 lnV; vec2 cC; float lnn; 
            
            // Left neighbor, the up from that. Third central arc. 
            cC = (mR)*e[(i + 3)%6]; 
            cC += e[i]*2. + e[(i + 1)%6]*2.; 
            lnn = length(p4.xy - cC) - cirR;
            lnV.x = lnn;

            // Fifth neighbor, first arc. 
            cC = (mR)*e[(i + 1)%6];
            cC += e[(i + 5)%6]*2.;
            lnn = length(p4.xy - cC) - cirR;
            lnV.y = lnn;
            
            // Second neighbor, first arc.
            cC = (mR)*e[(i + 5)%6];
            cC += e[(i + 2)%6]*2.;
            lnn = length(p4.xy - cC) - cirR;
            lnV.z = lnn;

            // Use the three arcs above to partition the triangle: First arc
            // minus the one behind it, etc.
            lnV = max(lnV, -lnV.zxy);
            ivec3 ind = ivec3(3, 1, 5);
            // Only the last two checks are necessary, but due to paranoia, 
            // I'll test all three. :D
            for(int j = 0; j<3; j++){
              
              float ln2 = lnV[j];
              if(ln2<0.){
                   // Inner
                   poly = max(poly, ln2);
                   p4.zw += eID[(i + ind[j])%6]/4.5;//0
                   break;
              }
            } 
 

        }  
        #endif
    
    
    
    }// End partition.
    
    
 
    
    // Experiments. Not this time.
    //if(pID==0) poly = abs(poly + .02) - .02;
    //if(pID==2) poly = abs(poly + .02) - .02;
    //if(hash21(p4.zw + .06)<.5) poly = abs(poly + .025) - .025;
    
    // More experiments.
    //float cir2 = length(p - s/2. - p4.zw*s/12.) - .005;
    //poly = max(poly, -cir2);
    
    
    
    #ifdef SHOW_GRID
    // Overlying hexagons and vertices. This isn't part of the pattern. 
    // It's merely a visual aid to help decipher the design, for anyone
    // who's interested.
    float vert = 1e5;
    float hexagon = -1e5; 

     
    // Iterate through all six sides of the hexagon cell.
    for(int i = 0; i<2; i++){
    int ii = int(mod((atan(p4.x, p4.y)/TAU + 1./3.)*6. + float(i), 6.));
         
        // Produce the edge for this particular side.
        hexagon = max(hexagon, distLineS(p4.xy, v[ii], v[(ii + 1)%6]));
    
        // Vertices for this edge.
        vert = min(vert, length(p4.xy - v[ii]) - .02); 
    }
   
    
    
    gPoly = min(abs(hexagon) - .005, vert);
    gPoly = max(gPoly, -vert - .01);
    #else
    gPoly = 1e5;
    #endif
    
    // Saving the local coordinates. Not used.
    gP = p4.xy;

    
    return vec4(poly, p4.zw, pID);

}

////////////////

// Microfaceted normal distribution function.
float D_GGX(float NoH, float roughness) {
    float alpha = pow(roughness, 4.);
    float b = (NoH*NoH*(alpha - 1.) + 1.);
    return alpha/(3.14159265*b*b);
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
  return (col*diff + spec*3.14159265);
  
}