// Image (image) — Islamic Decagon Star Pattern by Shane
// https://www.shadertoy.com/view/3cffDB

/*

    Islamic Decagon Star Pattern
    ----------------------------
    
    I've been meaning to post one of these patterns for a while. In terms of
    interesting symmetry and aesthetics, it's one of my favorites. There are
    many variations. However, I've covered the classic 10-fold symmetry version 
    that adorns the walls of many buildings around the world.
    
    There are countless Islamic patterns based on the symmetry of hexagons, 
    octagons, etc., but I like the standard 10-fold version, since it produces 
    the perfect five-pointed stars reminiscent of Penrose imagery. It also forms 
    the basis for the more complex decorative Girih patterns, and a lot of the 
    science associated with it.
    
    Girih patterns are described as polygon based design templates that consist 
    of a mixture of geometric shapes including decagons, pentagons, rhomboids
    (lonzenges), elongated hexagons and bowties. Historians theorize that they 
    became popular on account of their versatility, decorative qualities, and 
    the fact that they work well with complex large-scale geometric 
    installations. 
    
    The online material relating to these designs is immense. However, for my 
    part, I needed to construct a very simple one in realtime in order to 
    raymarch it. Geometrically speaking, this is nothing more than a bunch of
    decagon-base objects rendered inside the cells of a repeat diamond grid. 
    The decagon object itself is constructed using the usual polar coordinate 
    techniques.
    
    If you were to create a line-only version, far less work would be required.
    However, I wanted to render individual polygons, which meant constructing 
    polygon vertex lists and so forth. It required more work, but not 
    necessarily hard work. I also needed this information for a raymarched 
    traversal version that I'll post later. I'd also like to post a couple of 
    other versions that feature more traditional material design. Raw steel and 
    powder coated ceramics look interesting, but don't have an ancient 
    architecture feel. :)
    
    
    
    Other examples:
    
    // A nice clean line version. Far less code required.
    Islamic Pattern - wyatt
    https://www.shadertoy.com/view/3fB3Wy
    //
    // The same pattern is used in the background of this
    // beautiful refractive glass example.
    Path traced shader - wyatt
    https://www.shadertoy.com/view/w3B3Dy
    
    // A nice 2D version with interlaced lines.
    Islamic ornaments00 - knighty
    https://www.shadertoy.com/view/XlscWf
    
    // One of my favorite static architectural interior 
    // renderings on Shadertoy.
    Islamic Art - Klems
    https://www.shadertoy.com/view/ltdXRr
    
    
    References:
    
    Islamic Tile History and Inspiration
    https://whytile.com/tile-history/islamic-tile-history-and-inspiration/

*/


#define FAR 20.

// Apply trim to the larger objects.
#define TRIM
    
 
// Not effective here, so disabled. 
//#define SOFT_RELECTIONS


// Dave Hoskins's hash function.
float hash21(vec2 p){

    p = fract(p*vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x*p.y);

    /*
    // Dean_the_coder's configuration.
    p = fract(p*vec2(5.3983, 5.4427));
    p += dot(p.yx, p + vec2(21.5351, 14.3137));
	return fract(p.x*p.y*95.4337);
    */
}

// IQ's "uint" based uvec3 to float hash with Fabrice's modification.
float hash31(vec3 f){

   
    uvec3 p = floatBitsToUint(f);
    p = 1664525U*((p >> 2U)^(p.yzx>>1U)^p.zxy);
    uint h32 = 1103515245U*(((p.x)^(p.y>>3U))^(p.z>>6U));

    uint n = h32^(h32 >> 16);
    return float(n & uint(0x7fffffffU))/float(0x7fffffff);
    
}


// Tri-Planar blending function: Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: http://http.developer.nvidia.com/GPUGems3/gpugems3_ch01.html
vec3 tex3D(sampler2D tex, in vec3 p, in vec3 n){    
    
    // Abosolute normal with a bit of tightning.
    n = max(n*n - .2, .001); // max(abs(n), 0.001), etc.
    n /= dot(n, vec3(1)); 
    //n /= length(n); 
    
    // Texure samples. One for each plane.
    vec3 tx = texture(tex, p.zy).xyz;
    vec3 ty = texture(tex, p.xz).xyz;
    vec3 tz = texture(tex, p.xy).xyz;
    
    // Multiply each texture plane by its normal dominance factor.... or however you wish
    // to describe it. For instance, if the normal faces up or down, the "ty" texture 
    // sample, represnting the XZ plane, will be used, which makes sense.
    
    // Textures are stored in sRGB (I think), so you have to convert them to linear space 
    // (squaring is a rough approximation) prior to working with them... or something like
    // that. :) Once the final color value is gamma corrected, you should see correct 
    // looking colors.
    return mat3(tx*tx, ty*ty, tz*tz)*n;
}


// The path is a 2D sinusoid that varies over time, depending upon the frequencies, 
// and amplitudes.
vec2 path(in float z){ 
    
    //return vec2(0); // Straight line.
    
    // Curved path.
    float a = sin(z*.13);
    float b = cos(z*.17);
    return vec2(a*3. - b*1.5, b*.1 + a*.1); 
} 


// IQ's extrusion formula.
float opExtrusion(in float sdf, in float pz, in float h, in float sf){

    // Slight rounding. A little nicer, but slower.
    vec2 w = vec2(sdf, abs(pz) - h) + sf;
  	return min(max(w.x, w.y), 0.) + length(max(w, 0.)) - sf;
}

////////////////////////////////
 
// Diamond grid dimensions for a classic 10-fold Islamic pattern.
// It's deduced by rendering the smallest possible diamond (rhomboid)
// around a flat-top decagon. Obviously "PI/5" will be a factor.
//
const float gSc = 3.; // Scale.
const vec2 s = vec2(1./tan(PI/5.), 1.)*gSc;


// Diamond grid.
vec4 getGrid(vec2 p){
    
    vec4 ip = floor(vec4(p/s, p/s - .5)) + .5;
    vec4 q = p.xyxy - (vec4(ip.xy, ip.zw + .5))*s.xyxy;
    vec2 d = vec2(dot(abs(q.xy), 1./s), dot(abs(q.zw), 1./s));

    return d.x<d.y? vec4(q.xy, ip.xy) : vec4(q.zw, ip.zw + .5);

}

// Vertex holder. A little redundant here, but needed for
// the traversal version.
vec2[10] vP; 

// Decahedron vertex and mid-edge points.
vec2[10] vPDec, ePDec; 
// Star vertices.
vec2[10] starVP;

// Inner star vertices.
//vec2[20] vPInner;

// Needed for traversal, which we're not doing here.
// Inner star points.
//vec2[20] inStarP; 

// Star center point.
vec2 starCntr;


    
 
// Precalculation the required polygon vertices outside the raymarching loop.
void polygonSetup(){

    
    float minuLength = length(s)/4.; // Half the side length.
    float decaRad = minuLength;
 
    // Decagon vertices and mid edge points.
    for(int i = 0; i<10; i++) vPDec[i] = r2(-PI*2./10.*float(i))*vec2(-decaRad, 0);
    for(int i = 0; i<10; i++) ePDec[i] = mix(vPDec[i], vPDec[(i + 1)%10], .5);
    
    
    // Side length.
    float sL = length(vPDec[1] - vPDec[0]);
    
     // The decagon side length runs from tip to second star tip. By looking
    // at the five pointed star, the radius follows.
    float starR = sL/2./cos(PI/10.);
    //float starR = length(normalize(eP[0])*starCntrD - vP[0]);
    
    // Distance to star center.
    float starCntrD = length(ePDec[0]) + starR*sin(PI/10.);
    //float starCntrD = rad/cos(PI/10.);  
    
    // Star center point.
    starCntr = normalize(ePDec[0])*starCntrD;
 
    
    // Star inner radius ratio.
    float inStarRad = starR*(3. - sqrt(5.))/2.;
    

    // Outer star points.
    for(int i = 0; i<5; i++){
         
        vec2 starPntPos = r2(-TAU/5.*float(i) - TAU/20.)*vec2(starR, 0);
        starVP[i*2 + 1] = starCntr*0. + starPntPos;
          
        starPntPos = r2(-TAU/5.*float(i) + TAU/20.)*vec2(inStarRad, 0);
        starVP[i*2] = starCntr*0. + starPntPos;
    } 
    
    /*
    // Needed for traversal.
    vec2 quad1 = vec2(s.x/2. - length(vPDec[0])*2., 0);
    float quad0 = length(quad1)*tan(PI/5.);
        
    // Inner star points.            
    for(int i = 0; i<10; i++){
                     
       inStarP[i*2] = normalize(vPDec[i])*length(quad1);
       inStarP[i*2 + 1] = normalize(ePDec[i])*(quad0);
    }
    */
                
 

}
 

// Number of polygon vertices.
int pID;

// Polygon region ID.
int regionID = 0;


// Diamond grid cell vertex IDs and vertices. Not used here.
//const mat4x2 eID = mat4x2(vec2(-.5, 0), vec2(0, .5), vec2(.5, 0), vec2(0, -.5));
//const mat4x2 vPCell = mat4x2(eID[0]*gSc, eID[1]*gSc, eID[2]*gSc, eID[3]*gSc);


// The diamond distance field.
vec3 distField(inout vec2 p){
     
    vec2 oP = p;
    // Diamond grid ID and local coordinates.
    vec4 p4 = getGrid(p);
    p = p4.xy; // Local coordinates.
    vec2 ip = p4.zw; // Diamond central ID.
    
  
    /*
    // Debug diamond grid.
    #if 0
    float dia = dot(abs(p4.xy), 1./s);
    dia = ((dia - .5)*length(s/2.));
    #else                    
    float dia = -1e5;
    // Diamond grid.
    for(int i = 0; i<4; i++){
      // abs(p) will allow for half the iterations.
      dia = max(dia, distLineS(p, vPCell[i], vPCell[(i + 1)%4]));
    }    
    #endif
    */
 
 
    
    // A hacky optimization trick. The stars lie outside this
    // circle, so don't check the pixels inside.
    int outerRing = length(p) - length(starCntr + starVP[1])<0.? 0 : 1;
    
    // It would be pretty slow looping through every star, quad, etc.
    // Thankfully, you can use a polar symmetry trick to deal with 
    // just one object per pass.
    //
    float a = fract(atan(p.y, -p.x)/TAU); // Cell pixel angle.
    // Star and small quad index.
    int index = int(a*10.)%10;
    // Large quad index.
    int index2 = int(a*10. + .5)%10;   
    
    
    // Rather than save all ten star points, then check each star, we'll
    // rotate our local coordinates to the zero star position, then check
    // that. It's a cute repeat space trick that's made possible on account
    // of the fact that every star has identical dimensions.
    mat2x2 rM = r2(float(index)*TAU/10.);
     
    mat2x2 rM2 = r2(float(index2)*TAU/10.);
    
    // Extra turns required to line up the star vertex points with neighboring 
    // diamond cells... Yeah, this stuff can be annoying to code. :)
    mat2 rMI = r2(float(index*4)*TAU/10.);
 
    ///////
   
    
    // Polygon distances.
    float poly = -1e5;
    float polyI = 1e5;
    
     // Holding place for coordinates.
    vec2 q;
    
 
    // If outside the ring border, calculate the star distances.
    // It's a waste of GPU power checking inside were they don't reside.
    if(outerRing==1){
 
        q = rMI*(rM*(p) - starCntr);
    
        if(index==2 || index==7){ // Partial star indices.


            // Partial stars.

            // Change the vertex number to 6, then reset the starting
            // vertex to the 8th one... Trial and errror got me there. :)
            vP = starVP;
            vP[0] = vP[8];

            pID = 6;
            
            polyI = sdPoly(q, vP, pID);

        } 
        else {
            
            // Full stars.
            vP = starVP;
            pID = 10;
            
            //polyI = sdPoly(q, vP, pID);
            // Using IQ's specialized pentagram distance field, which is
            // way faster than the function above.
            polyI = sdPentagram(q, length(starVP[1]));
        }
    
    }
    
    // Positional ID scaling.
    ip *= s;
     
    // Use the calculated star distances to see if we're inside a star.
    if(polyI<0.){
    
        poly = polyI;
        
        ip += inverse(rM)*starCntr;
        //ip += ePDec[(index + 0)%10]; 
        
        p = q; 
          
        regionID = 4;
        pID = 10; // 10 vertices.
        
        //  Partial stars.
        if(index==2 || index==7){
           regionID = 5;
           // Moving the center just slightly on the half stars.
           float dir = index == 2? -1. : 1.;
           ip += vec2(0, dir*s.y*.01);
           
           pID = 6;
            
           
        }
    
    }
    else {
        
        // Not inside.
        poly = -polyI;//max(poly, -polyI);
        pID = -1; // Undetermined vertex number.
        
        regionID = 0;
 
    }
    
    
    // The pointed arrow-like hexagons.
    if(pID == -1){
          
        // Middle, up, across.
        vP[3] = vPDec[0];
        vP[4] = starCntr + starVP[2];
        vP[5] = starCntr + starVP[1];
        // Flipping below the X-axis. 
        vP[2] = vP[4]*vec2(1, -1);
        vP[1] = vP[5]*vec2(1, -1);
        
        // The far right diamond vertex, minus the decagon diameter.
        vP[0] = vec2(s.x/2. - length(vPDec[0])*2., 0);
        
        
        q = rM2*p;
        
        float ln0 = lineStep(q, vP[0], vP[1]);
        float ln1 = lineStep(q, vP[0], vP[5]);
        float ln2 = length(p4.xy) - length(vPDec[0]);
        
        // If we're beyond these partitioning lines, we're inside
        // a hexagon.
        if(max(ln0, -ln1)<0.){
        
            // Hexagon distance.
            poly = sdPoly(q, vP, 6); 
            
            // Update the ID.
            ip += normalize(vPDec[index2])*length(mix(vP[3], vP[0], .4));
            
            p = q;
   
            pID = 6;  // Six vertices.         
            
            regionID = 3;
        
        }
        else {
        
            // Outside the hexagon boundaries.
            poly = max(poly, -polyI);
            pID = -1;
            
            regionID = 1;
            
   
        }
        
        // The two outer hexagons.
        //
        // If we're outside the inner decagon, then we've hit one 
        // of the hexagons on the far left and right of the diamond.
        if(ln2>0.){
            
            // Move the coordinates to the correct position, then 
            // recalculate the hexagon from the new coordinates.
            // This is a cheap trick that can save a lot of hassle.
            q = reflect(q - vP[3]*2., vec2(1, 0));
               
            float polyI2 = sdPoly(q, vP, 6);
            // Far left and right hexagons.
            if(polyI2<0.){
                
                // Inside the outer hexagons.
                poly = polyI2;

                ip += normalize(vPDec[index2])*length(mix(vP[3], vec2(-s.x/2., 0), .4));
                
                p = q;
                pID = 6; // Six vertices.
                
                
                regionID = 2;

            }
            else {
                
                // Outside.
                poly = max(poly, -polyI2);
                pID = -1;
                
                regionID = 0;

            }
            
            
        
        }
        
        // Quads.
        if(pID == -1){
        
            // Same as the bottom tip of the hexagon above.
            vP[1] = vec2(s.x/2. - length(vPDec[0])*2., 0);
            vP[3] = r2(-PI/5.)*vP[1];
            
            vP[2] = starCntr + starVP[1];
            vP[0] = normalize(vP[2])*length(vP[1])*tan(PI/5.);
              
            q = rM*p;
      
            polyI = sdPoly(q, vP, 4);

            // Check to see if we're inside the inner quads.
            if(polyI<0.){

                poly = polyI;

                ip += normalize(ePDec[index])*length(mix(vP[0], vP[2], .35));

                p = q;
               
                pID = 4; // Four vertices.
                
                regionID = 1;

            }
            else {
                
                // Not inside the quad, so the remainder is the 20
                // vertex inner star.
                poly = max(poly, -polyI);
                
                
                pID = 20; // Twenty vertices. 
                
                //Thankfully, we don't have to calculate this polygon, since
                // it has already been done using CSG above.
                //vPInner = inStarP;                 
                //poly = sdPoly(p, inStarP);
                //p = p4.xy;
                  
                regionID = 0;
 
            } 
        
        
        }
    
    }
 
  
    // Floating point numbers aren't quite reliable enough for IDs, since the 
    // same points calculated from different cells (the stars, for instance) might 
    // be virtually identical, but not quite. The following is a hacky fix for that.
    ip = floor(ip*16384. + .001)/16384.;
    
    
    // Debug circles.
    //float cir = length(oP - ip) - .04;
    //poly = max(poly, -cir);
    
     
    // Minium object distance and its ID.
    return vec3(poly, ip);
}


// Object distance container.
vec4 vObj;

vec3 gRd; // Global ray direction.
vec3 gDir; // Global step direction.
float gCD; // Global cell wall distance.

// Storage for values used outside the raymarching function.
vec4 gVal;
vec3 gSc3;
vec2 gP;


// The extruded image.
float map(vec3 p3){
    
    // Floor.
    float fl = p3.y;// - .25;
    
    // A cheap trick to eliminate calculations a certain distance
    // above the plane.
    if(p3.y - .5>0.){ gCD = .25; return 1e5; }
    
    

    // Local 2D coordinates.
    vec2 p = p3.xz;

    // Local coordinates and cell ID.
    vec3 sc = vec3(s.x, 1, s.y);
    vec3 d3 = distField(p); 
    
    // 2D polygon distance and its ID.
    float d2 = d3.x;
    vec2 id = d3.yz;
    
 
    // The extruded block height. See the height map function, above.
    float h = .25;
    
    // Raise some of the objects just a little above the others.
    if(regionID<4 ) h += .03;
     
    #ifdef TRIM
    // Apply trim to the larger objects.
    float trim2D = 1e5;
    float trim = 1e5;
    if(regionID==0 || regionID==2 || regionID==3){
      
       trim2D = max(d2, abs(d2 + .078) - .078);
       trim = opExtrusion(trim2D, p3.y - h/2., h/2. - .06, .0);
    }
    #endif
    
    
    
    // Turning the 2D field into grooved borders.
    float ew = regionID<4? .055 : .045;
    d2 = abs(d2 + ew) - ew;
    d2 = max(d2, -(d2 + ew + .01));
    
    // Extruded 3D polygon distance.
    float d = opExtrusion(d2, p3.y - h/2., h/2., .0);
    
    // Slight beveling.
    d += max(d2, -.025)*.2;
    //d += d2*.125;
    
    #ifdef TRIM
    // Trim.
    if(trim<d){ d = trim; d2 = trim2D;  h -= .06; }
    #endif
 
    // Raising the floor beneath the star shapes.
    if(regionID>=4) d = min(d, max(d3.x, p3.y - .15));
 
 
    // Saving the box dimensions and local coordinates.
    gSc3 = vec3(sc.x - .005, h, sc.z - .005);
    gP = p;
    
    
    gVal = vec4(d2, id, h); // Individual block ID.
    
 
    // Overall object ID.
    vObj = vec4(d, fl, 0, 0);
    
    // Combining the floor with the extruded image
    return  min(fl, d);
 
}

// Raymarch function.
float trace(vec3 ro, vec3 rd){

    gRd = rd; // Global ray direction.
    gDir = step(0., gRd) - .5; // Step direction.

    float t = 0.;
    
    const int maxSteps = 96;

    for(int i = 0; i < maxSteps; i++) {
        
        // Scene distance.
        float d = map(ro + rd*t);
        
        // Surface check.
        if(abs(d)<.001 || t>FAR) break;        
        
        // Limit the ray jump distance to ensure that it
        // doesn't go any further than the next cell.
        t += min(d*.8, gCD);
    }
    
    // Return the distance.
    return min(t, FAR);

}

// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with 
// limited iterations is impossible... However, I'd be very grateful if someone could 
// prove me wrong. :)
float softShadow(vec3 ro, vec3 rd, vec3 n, float lDist, float k){
     
    float shade = 1.;
    float t = 0.; 
 
    // Coincides with the hit condition in the "trace" function. I've added in 
    // a touch of jittering to alleviate banding.
    ro += n*.0015 + rd*hash31(ro + rd + n)*.05;

    gRd = rd; // Global ray direction.
    gDir = step(0., gRd) - .5; // Step direction.


    // Max shadow iterations - More iterations make nicer shadows, but slow things down. 
    // Obviously, the lowest number to give a decent shadow is the best one to choose. 
    for (int i = min(0, iFrame); i<64; i++){

        float d = map(ro + rd*t);
        shade = min(shade, k*d/t);
        
        // Early exit, if necessary.
        if (d<0. || t>lDist) break;       

        //shade = min(shade, smoothstep(0., 1., k*d/t)); // Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += clamp(d, .01, stepDist), etc.
        t += clamp(min(d, gCD), .005, .15); 
        
    }

    // Shadow.
    return max(shade, 0.); 
}


// Standard normal function. It's not as fast as the tetrahedral calculation, 
// but more symmetrical.
vec3 nr(in vec3 p){
	
    //const vec2 e = vec2(.001, 0);
    //return normalize(vec3(map(p + e.xyy) - map(p - e.xyy),
    //                      map(p + e.yxy) - map(p - e.yxy),	
    //                      map(p + e.yyx) - map(p - e.yyx)));
    
    // This mess is an attempt to speed up compiler time by contriving a break... It's 
    // based on a suggestion by IQ. I think it works, but I really couldn't say for sure.
    float sgn = 1.;
    vec3 e = vec3(.001, 0, 0), mp = e.zzz; // Spalmer's clever zeroing.
    for(int i = min(iFrame, 0); i<6; i++){
		mp.x += map(p + sgn*e)*sgn;
        sgn = -sgn;
        if((i&1)==1){ mp = mp.yzx; e = e.zxy; }
    }
    
    return normalize(mp);
}


// Ambient occlusion. Based on IQ's original.
float cao(in vec3 p, in vec3 n){

	float sca = 2., occ = 0.;
    for( int i = 0; i<6; i++ ){
    
        float hr = .01 + float(i)*.25/6.;        
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
        //if(occ>1e5) break;
    }
    
    return clamp(1. - occ, 0., 1.);  
    
} 


///////////////////////////
// A rough interpretation of the following.
// Sky Gradient Improved -- fishy
// https://www.shadertoy.com/view/Dsf3RH
vec3 skyTex(vec3 ray, vec3 ld){

    //ray.y = abs(ray.y); // Sun and sea.
    float raySun = dot(ray, ld);
    
    vec3 col = exp2(-(ray.y - raySun*.5)/vec3(.3,.4,.6)); // Base gradient.
    // Darken the sky the lower the sun is.
    col *= sqrt(max(1e-5, dot(ld + vec3(0, .3, 0), vec3(0, 1, 0)))); 
    return mix(col, vec3(10, 3, .2), smoothstep(0.9995, 1.0, max(0.0, raySun)))
               *(smoothstep(-.125, .65, ray.y));
}

///////////////////////////

void mainImage(out vec4 O, in vec2 U) {

    // Coordinates.
    #define iRes iResolution.xy
    vec2 u = (U - iRes/2.)/iRes.y;
    
    // Look, ray origin and light position.
    vec3 lk = vec3(0, 2.5, iTime*.5);
    vec3 ro = lk + vec3(0, .6, -.2); // Camera position, doubling as the ray origin.
    vec3 lp = lk + vec3(1, 2, 1)*3.;

	// Using the Z-value to perturb the XY-plane.
	lk.xy += path(lk.z);
	ro.xy += path(ro.z);
  
    float FOV = tan(radians(30.)/2.)*4.; // Field of view.
   
    // Camera.
    vec3 camDir = normalize(lk - ro); 
    vec3 worldUp = vec3(0, 1, 0);
    vec3 camRight = normalize(cross(worldUp, camDir));
    vec3 camUp = cross(camDir, camRight);
    vec3 rd = normalize(camRight*u.x + camUp*u.y + camDir/FOV);
  
    // Swiveling the camera about the XY-plane (from left to right) when turning corners.
    // It's synchronized with the path in some kind of way.
 	rd.xy = r2(-path(lk.z).x/16.)*rd.xy;
    
    //rd.xz *= r2(-TAU/32.);
    //rd.yz *= r2(-TAU/48.);
    
    // Setup the cell polygon structure.
    polygonSetup();
    
    // Raymarching.
    float t = trace(ro, rd);
 
    // Distance, ID and object height.
    vec4 svVal = gVal;
    vec2 svP = gP;
    int svPID = pID;
    
    //vec3 svSc = gSc3;
    //float svCD = gCD;
    
    
    int objID = vObj.x<vObj.y? 0 : 1;
    
    int svRegID = regionID;
    // Quick hack to give the floor a different ID to everything else.
    if(objID==1) svRegID = -1;
    
    // Hit position.
    vec3 sp = ro + rd*t;
    
    // Light. A scene like this would be more accurate using direct lighting, but
    // sometimes, I'll use a far away point light to bring out the SSS a little more.
    #if 0
    vec3 ld = normalize(vec3(1, .65, 1));
    float lDist = FAR;
    #else
    vec3 ld = lp - sp;
    float lDist = max(length(ld), 1e-5);
    ld /= lDist;
    #endif
    
 	
	// The blueish sky color. Tinging the sky redish around the sun. 		
    vec3 sky = skyTex(rd, ld);//sky(rd, ld);
   
    //vec3 sky = mix(vec3(.4, .6, .8), vec3(.2, .4, 1)*2., dot(rd, ld));
    vec3 col = sky;
    
    vec3 sunCol = vec3(1, .9, .7); // Sun color.
  

    if(t<FAR) {
    
        // Surface normal.
        vec3 sn = nr(sp);
        
        // Shadow and ambient occlusion.
        float sh = softShadow(sp, ld, sn, lDist, 16.);
        /*
        #ifdef SOFT_RELECTIONS
        float shR = softShadow(sp, reflect(rd, sn), sn, lDist, 16.);
        #endif
        */
        float ao = cao(sp, sn)*(.5 + .5*sn.y);
        
        //float crv = curve(sp, sn, 3.6);
        
        
        float rnd = hash21(svVal.yz + .22);
        vec3 rCol = .5 + .45*cos(TAU*rnd/4. + vec3(0, 1, 2)*1.2);
        
        vec3 oCol = vec3(1);
        
        // Color up the various polygons based on their IDs.
        if(svRegID==1) oCol *= vec3(1, .7, .3);
        if(svRegID==2 || svRegID==3) oCol *= vec3(2, .9, .7).xzy*.5;

        if(svRegID==0) oCol *= vec3(1, .9, .7);
        if(svRegID==-1 || svRegID==4 || svRegID==5) oCol *= vec3(1, .9, .8);

        if(svRegID==-1) oCol *= vec3(.4, .3, .2);

        if(svRegID==-1 || svRegID==4 || svRegID==5) oCol = mix(oCol, rCol.zyx, .25);
        else  oCol = mix(oCol, rCol, .25);
       
        if(svRegID<4) oCol *= oCol;
         
         
        // Texture.
        vec3 tx = tex3D(iChannel1, sp/2. + vec3(svVal.y, 0, svVal.z), sn);
        if(svRegID<4) oCol *= tx*3. + .35;
        else oCol *= tx*4.;

         
        //////
       
        // Apply some edging.
        float ew = .01;
        float bord = abs(svVal.x);
        float hgt = (sp.y - svVal.w);
        float edge = max(bord, -hgt);
          
        // Apply edging.
        if(objID==1) edge = bord - ew; // Ground borders.
        oCol = mix(oCol, oCol*.25, 1. - smoothstep(0., .004,  edge - ew));

        
        // LIGHTING.
        //float bou = .5 - .5*sn.y; // Bounce light.
        
        // Backscatter.
        float bac = clamp(dot(sn, -normalize(vec3(ld.x, 0, ld.z))), 0., 1.);
        bac = (bac*.5 + .5);//*bou; // Apply the back scatter.
   
        // Material properties.
        float fresRef = .75;  // Reflectivity.
        float type = 0.;     // Dielectric or metallic.
        float rough = .1;   // Roughness.
        
        // Star material.
        if(svRegID>=4){
             type = 1.; // Metallic.
             rough = .25;
             //fresRef = .5;
             //oCol = vec3(1.6, .8, .4)*dot(oCol, vec3(.299, .587, .114))*1.;
             //rough *= dot(tx, vec3(.299, .587, .114))*3.5;
        }
      


        // Standard BRDF dot product calculations.
        vec3 h = normalize(ld - rd); // Half vector.
        float ndl = dot(sn, ld);
        float nr = clamp(dot(sn, -rd), 0., 1.);
        float nl = clamp(ndl, 0., 1.);
        float nh = clamp(dot(sn, h), 0., 1.);
        float vh = clamp(dot(-rd, h), 0., 1.);  
 
        // Specular microfacet (Cook- Torrance) BRDF.
        //
        // F0 for dielectics in range [0., .16] 
        // Default FO is (.16 * .5^2) = .04
        // Common Fresnel values, F(0), or F0 here.
        // Water: .02, Plastic: .05, Glass: .08, Diamond: .17
        // Copper: vec3(.95, .64, .54), Aluminium: vec3(.91, .92, .92), 
        // Gold: vec3(1, .71, .29), Silver: vec3(.95, .93, .88), 
        // Iron: vec3(.56, .57, .58).
        vec3 f0 = vec3(.16*(fresRef*fresRef)); 
        // For metals, the base color is used for F0.
        f0 = mix(f0, oCol, type);
        vec3 FS = f0 + (1. - f0)*pow(1. - vh, 5.); // Fresnel-Schlick reflected light term.
        
        // BRDF style specular and diffuse calculations. There is so little
        // extra work involved, but the lighting quality is much better.
        vec3 spec = getSpec(FS, nh, nr, nl, rough);
        vec3 diff = getDiff(FS, nl, rough, type);

        // An inferior version of IQ's lighting.
        float amb = .5;
       
		vec3 brdf = vec3(0);
        brdf += (diff)*sunCol*sh*ao;
		brdf += (amb)*vec3(.3);
		brdf += (bac)*vec3(1, .97, .92)*ao*.3;
        
        brdf += sky*diff;
        brdf += spec*sunCol*sh*ao;
		
		// Applying the above.
		col = (oCol*brdf);   
         
        
        // Specular reflection.
        vec3 ref = reflect(rd, sn); // Surface reflection.
        vec3 refTx = texture(iChannel0, ref).xyz; refTx *= refTx; // Cube map.
        float spRef = pow(nh, 5.);
        float rf = (objID == 1)? .5 : 1.;//mix(.5, 1., 1. - smoothstep(0., .01, d + .08));
        col = col + col*spRef*refTx*rf*ao; //smoothstep(.03, 1., spRef) 
        
        /* 
        #ifdef SOFT_RELECTIONS
        // Soft reflective lighting.
        if(objID==0){
      
            col += .5*sunCol*spec*shR; // Sun reflection.
            col += sky*shR*FS; // Sky reflection .       
        } 
        #endif
        */

    }
     
    // Horizon fog.
    col = mix(col, sky, smoothstep(.2, 1., t/FAR));   
    
    // Sigmoid tone mapping.
    col = atan(col);
    
    // Rough gamma correction and screen presentation.
    O = vec4(pow(max(col, 0.), vec3(1)/2.2), 1);
    
}
