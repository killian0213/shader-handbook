// Buffer A (buffer) — Rhombic Dodecahedral Traversal by Shane
// https://www.shadertoy.com/view/lccyR2

/*

    Rhombic Dodecahedral Traversal
    ------------------------------
    
    Traversing a rhombic dodecahedon field. There are already a few
    examples on Shadertoy, but I like this particular 3D polyhedral 
    packing, so wanted to post one. I started this way too long ago, 
    but was inspired to complete it after looking at Gelami's really
    nice rhombic dodecahedral traversal efforts. The dark tones with 
    colorfully lit block material scheme directly influenced the 
    aesthetics here.
     
    This differs from other examples in the sense that it's a raymarched 
    traversal, but packed polyhedral examples tend to be the same. In 
    particular, you determine the best way in which the 3D objects pack 
    togther, then perform a ray to object intersection in order to jump 
    the ray from cell to cell.    
    
    Rhombic dodecahedrons pack together in a very similar way to which
    hexagons fit together in a 2D grid. Hexagon grids consist of two
    overlapping rectangle grids spaced out by a half cell, whereas a 
    rhombic dodecahedral grid consists of two overlapping cuboid grids
    spaced out by half a cell dimension.
    
    A 2D hexagon traversal involves additionl ray to polygon edge 
    intersections, and a rhombic dodecahedral traversal involves ray
    to polyhedron wall intersections... It's all very similar, but you'd
    probably want to become acquainted with the 2D traversal first. :)
    
    The traveral and intersection code itself was written from scratch
    some time ago, so I don't know how it compares to other methods on 
    here, but it feels reasonably efficient, if that counts. :D For all 
    I know, there might be some really cool skewed grid method out 
    there that I'm not aware of that is faster and more elegant. 
    
    I'm aware that the code is drawn out. However, the raymarched 
    traversal itself is pretty straight forward. At some stage, I'll 
    post a much, much simpler version. I'll also make a few changes here
    to increase the frame rate a bit.
    
    I've provided links to examples below. All, including mine, have
    similar names. I guess there are only so many ways in which you can
    name a popular generic process. :)
    
    
    
    Other examples:
    
    // Awesome visuals, and the inspiration for the color scheme I'm
    // using. It also runs faster on account of the fact that it's a
    // straight up traversal... and, more than likely, coded better. :D
    Rhombic Dodecahedron Traversal - gelami
    https://www.shadertoy.com/view/mlK3DD
    
    // I've always admired this shader. Cleverly written too.
    Packed Spheres SDF - blackle
    https://www.shadertoy.com/view/3djBDh
    
    // A really nice straight forward traversal.
    Rhombic Dodecahedral Honeycomb - Polygon
    https://www.shadertoy.com/view/tl2BD3
    
    // If you're not sure how rhombic dodecahedrons pack together,
    // this is definitely the best way to understand it.
    rhombic dodecahedra offset grids - jt
    https://www.shadertoy.com/view/mlfczN
    
    // I think Spalmer may have taken a neighbor approach, which
    // comes in handy when requiring neighbor information. I'll be
    // consulting it when making a more difficult variation.
    Rhombic Dodecahedron Voxels - spalmer
    https://www.shadertoy.com/view/WdXBR8
 

*/


vec4 gObjD;
 
// Maximum ray distance.
#define FAR  15.

// Global cell scale. Values of about "1./2." to "1./6" work, 
// but it's designed to work with the currect value.
vec3 GSCALE = vec3(1, sqrt(2.), 1)/2.;

// Light type: Point: 0, Direct: 1
#define LIGHT_TYPE 0

// Square holes, or round holes. I forgot to include the 
// no hole version, but I'll code that in later.
#define SQUARE_HOLES

 

//////////////

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }

 
// Tri-Planar blending function: Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: http://http.developer.nvidia.com/GPUGems3/gpugems3_ch01.html
vec3 tex3D(sampler2D tex, in vec3 p, in vec3 n){    
    
    // Ryan Geiss effectively multiplies the first line by 7. It took me a while to realize that 
    // it's largely redundant, due to the division process that follows. I'd never noticed on 
    // account of the fact that I'm not in the habit of questioning stuff written by Ryan Geiss. :)
    n = max(n*n - .2, .001); // max(abs(n), 0.001), etc.
    n /= dot(n, vec3(1)); 
    //n /= length(n); 
    
    // Texure samples. One for each plane.
    vec3 tx = texture(tex, p.yz).xyz;
    vec3 ty = texture(tex, p.zx).xyz;
    vec3 tz = texture(tex, p.xy).xyz;
    
    // Multiply each texture plane by its normal dominance factor.... or however you wish
    // to describe it. For instance, if the normal faces up or down, the "ty" texture sample,
    // represnting the XZ plane, will be used, which makes sense.
    
    // Textures are stored in sRGB (I think), so you have to convert them to linear space 
    // (squaring is a rough approximation) prior to working with them... or something like that. :)
    // Once the final color value is gamma corrected, you should see correct looking colors.
    return mat3(tx*tx, ty*ty, tz*tz)*n; // Equivalent to: tx*tx*n.x + ty*ty*n.y + tz*tz*n.z;

}

/*
// 3D texture lookup. Sometimes faster.
float hash31(vec3 f){
 
    return texture(iChannel2, f/32.).x;
}
*/

// IQ's "uint" based uvec3 to float hash with Fabrice's modification.
float hash31(vec3 f){

   
    uvec3 p = floatBitsToUint(f);
    p = 1664525U*((p >> 2U)^(p.yzx>>1U)^p.zxy);
    uint h32 = 1103515245U*(((p.x)^(p.y>>3U))^(p.z>>6U));

    uint n = h32^(h32 >> 16);
    return float(n & uint(0x7fffffffU))/float(0x7fffffff);
    
}


// Texture sample.
//
vec3 getTex(sampler2D iCh, vec2 p){
    
    // Strething things out so that the image fills up the window. You don't need to,
    // but this looks better. I think the original video is in the oldschool 4 to 3
    // format, whereas the canvas is along the order of 16 to 9, which we're used to.
    // If using repeat textures, you'd comment the first line out.
    //p *= vec2(iResolution.y/iResolution.x, 1);
    vec3 tx = texture(iCh, p/8.).xyz;
    return tx*tx; // Rough sRGB to linear conversion.
}



// The path is a 2D sinusoid that varies over time, depending upon the frequencies, 
// and amplitudes.
vec2 path(in float z){ 

    //return vec2(0);
    float s = sin(z/9.);
    float c = cos(z/13.); 
    return vec2(s*c*8., (s + c)*4.); 
}

// Height map value.
float hm(in vec3 p){ 

    // This is a very basic 3D surface with a camera-path directed tunnel
    // carved out of it. Pretty standard for tunnels.
    vec2 pth = path(p.z);
    float h = (dot(sin(p - cos(p.yzx*2.)), vec3(1./6.)) + .5)*8. - 0.;
    
    // Carving out the tunnel.
    h = max(h, -(length(p.xy - pth) - 5.5));
    return h; // floor(h/GSCALE.y)*GSCALE.y;

 
}

vec3 getCol(vec3 id){

    vec3 col = .5 + .45*cos(6.2831*hash31(id + .12)/12. + vec3(0, 1, 2)*1.6 + 3.35);
    
    // Leftover effect from another shader. Interesting... but I'll pass. :)
    //id = floor(id/2.);
    //if(mod(id.x + id.y + id.z, 2.)<.5) col = col.zxy;
      
    return col;
}



// Rhombic dodecahedron, edges and face centers: I put this together
// without much of a plan, so there'd definitely be better ways to 
// achieve the same. The logic is all over the place, so I wouldn't
// pay too much attention to it. Normally, you'd just render the main
// shape, which is just a few lines.
//
vec2 rhomDodeca(vec3 p, vec3 sc, int type){

    // Construction vectors: It's probably helpful to look at a 
    // rhombic dodecahedron with labelled vertices and so forth.
    const vec3 v0 = normalize(vec3(0, 1, 1));
    const vec3 v1 = normalize(vec3(1, 0, 1));
    const vec3 v2 = normalize(vec3(1, 1, 0));
    
    const vec3 v00 = vec3(1, 0, 0);
    const vec3 v11 = vec3(0, 1, 0);
    const vec3 v22 = vec3(0, 0, 1);
  
    // The rhombic dodecahedron is rotated inside the cuboid 
    // about the XZ axis by 45 degrees to fit into it nicely. 
    // I'll attempt to get rid of this at some stage.
    const float a = sqrt(.5);
    const mat2 m2 = mat2(a, a, -a, a);// rot2(3.14159265/4.);
    p.xz *= m2;
    // Taking advantage of the polyhedron's symmetry. Doing this
    // allows us to render a few sides at once. You use a similar
    // trick when rendering cuboids, etc.
    p = abs(p);
   
    float r = sc.x*.5;
    //float r2 = r/sqrt(2.);
    
    // Mid face points distance.
    float face;
    
   
    #ifndef SQUARE_HOLES
    face = min(min(length(p - v0*r), length(p - v1*r)), 
                     length(p - v2*r));
    face -= sc.x*.1;
    #endif
    
    // Rhombic dodecahedron plane distances. Relying on
    // mirroring, which is possible on account of the
    // object's symmetry.
    vec3 d3 = vec3(dot(p, v0), dot(p, v1), dot(p, v2));
    
    // Rhombic dodecahedron.
    float d;
    
    // Edge lines.
    vec3 e3 = vec3(max(d3.x, d3.y), max(d3.y, d3.z), max(d3.z, d3.x)) - r;
    
    
    #ifdef SQUARE_HOLES
    if(type==0){
       // Thick edges, or holes carved out, depending on your take.
       e3 = abs(e3 + .05) - .05;
       d = max(max(e3.x, e3.y), e3.z); 
       face = 1e5;
    }
    else {
       // The colored cubes aren't transparent, but they're designed
       // to look that way.
       d = max(max(d3.x, d3.y), d3.z) - r; 
       e3 = abs(e3 + .05) - .05;
       // The main polyhedron husk with edges taken away, make 12
       // squarish dots for each face... After a bit of confusion, I
       // was able to figure that out.
       face = max(abs(d + .05) - .05, -max(max(e3.x, e3.y), e3.z) + .01);
       d = max(max(e3.x, e3.y), e3.z); 
    }
    #else
    d = max(max(d3.x, d3.y), d3.z) - r; 
    #endif
   
    // Edges.
    e3 = abs(e3);
    float edge = max(max(e3.x, e3.y), e3.z) - .005;
  
  
    //if(type==0) edge = min(edge, max(-d, abs(face)) - .005); // Adding the face line to the edge. 
    //else edge = min(edge, abs(face) - .005); // Adding the face cup to the edge.
    edge = min(edge, abs(face) - .005); // Adding the face cup to the edge.
       
    
    d = max(d, -face); // Carving out the face point.
 
    return vec2(d, edge);
    
}

// The rhombic dodecahedron grid: The objects fit into two overlapping cuboid 
// grids (of dimension vec3(1, sqrt(2.), 1)*scale) that are spaced out by half 
// a dimension. Produce them then determine the closest one. Hexagons are 
// calculated in very similar fashion.
//
// I could group a lot of this and make it much faster, but I'll leave it as
// is for readability sake.
vec3 getGrid(inout vec3 p, inout vec3 sc){    

    // Coordinate copy.
    vec3 oP = p;
    
    // First grid. ID and local coordinates.
    vec3 ip = floor(p/sc) + .5;
    p -= ip*sc;
    float d = dot(p, p); // Distance.
    vec3 id = ip;        // Position based ID.
    vec3 gP = p;         // Local coordinates.
    
    // Second grid. ID and local coordinates.
    p = oP - .5*sc;
    ip = floor(p/sc) + .5;
    p -= ip*sc;
    float d2 = dot(p, p);
    
    // Determine the closest and update the 
    // ID and local coordinates if necessary.
    if(d2<d){
       d = d2;
       id = ip + .5;
       gP = p;
    
    }
    
    // Update the local coordinates. 
    p = gP;
    
    // Return the position based ID.
    return id;
    
    
}


// Plane function.
float plane(vec3 p, vec3 n, float d){ return dot(p, n) + d; }

// Ray origin, ray direction, point on the line, normal. 
float rayLine(vec3 ro, vec3 rd, vec3 p, vec3 n){
   
   // This it trimmed down, and can be trimmed down more. Note that 
   // "1./dot(rd, n)" can be precalculated outside the loop.
   //return dot(p - ro, n)/dot(rd, n);
   float dn = dot(rd, n);
   return dn>0.? dot(p - ro, n)/dn : 1e8;   

} 

vec3 lp, ld;

// Global cell boundary distance variables.
vec3 gDir; // Cell traversing direction.
vec3 gRd; // Ray direction.
float gCD; // Cell boundary distance.
// Box dimension and local XY coordinates.
vec3 gSc; 
vec3 gP;
vec4 gID;


// A simple glow variable.
vec3 glow;

float map(vec3 q3) {


    // Floor. Redundant here.
    vec2 pth = path(q3.z);
    float fl = q3.y + 1.5 - pth.y;
 
 
    vec3 sc = GSCALE; // Scale.
    // Local coordinates and cell ID.
    vec3 p = q3;
    vec3 p3 = getGrid(p, sc); 
  
    vec3 id = p3;
      
    
    // CELL INTERSECTION.
    
    
    // The 3D equivalent of the following.
    const float a = sqrt(.5);
    // const mat2 m2 = mat2(a, a, -a, a);// rot2(3.14159265/4.);
    const mat3 m3 = mat3(a, 0, a, 0, 1, 0, -a, 0, a);

    // Vector directions and normals to the object's planes...
    // In this case, it's half of all 12 planes, since we intend 
    // to take advantage of the object's symmetrical nature to 
    // double up on some intersection calculations.
    //
    // By the way, I vaguely recall that it's possible to cut this 
    // down to three or even two checks by using some step trickery 
    // on the direction ray... which I'll attempt later, but not now. :)
    //
    // The rhombic dodecahedron is rotated inside the cuboid about 
    // the XZ axis by 45 degrees to fit into it properly. Hence, the
    // "m3" rotation. 
    const vec3[6] fP = vec3[6](

        m3*vec3(0, 1, 1), m3*vec3(0, -1, 1), m3*vec3(1, 0, 1),
        m3*vec3(-1, 0, 1), m3*vec3(1, 1, 0), m3*vec3(-1, 1, 0)
    );

    // Maximize the ray distance.
    float t = 1e8;

    // You could calculate the field distance to the object
    // inside the following loop, but we'll use other methods.
    //float rh2 = -1e5; 
    

    for(int i = 0; i<6; i++){

         vec3 fR = fP[i];
      
        // Using a traversal trick for symmetric objects. In particular
        // reversing the point direction if the ray is heading in the
        // opposite direction. This cuts down calculations from 12
        // to six in this case, which is pretty helpful inside a 
        // raymarching loop.
        fR = dot(gRd, fR)<0.? -fR : fR;
        
        // Distance to the cell wall of the plane in the direction of
        // the ray.
        //
        // Ray origin, ray direction, point on the line, normal. 
        float ti = rayLine(p, gRd, fR*sc.x/2./sqrt(2.), normalize(fR));
        // Record the minimum distance.
        t = min(ti, t);

        // Object field distance... Not to be confused with the
        // directional ray to cell wall intersection above.
        //rh2 = max(rh2, -plane(p, normalize(fR), sc.x/2.));
    }


    // Distance to the next cell in the direction of the ray.
    gCD = max(t, 0.) + .0015;


    // RAYMARCHING.
    
    
    // The rhombic dodecahedron, or something similar that fits into
    // the cell space.
    float d = 1e5;
 
    // A thin frame that encased the object above.
    float dFrame = 1e5;
   
    // Block type. Opaque, or faux transparent.
    int type = hash31(id + .22)<.9? 0 : 1;

   
    // The 3D field value.
    float h = hm(id*sc);
    
    // Using the field value to perturb the floor a little.
    fl += h*.1;
    //fl = 1e5; // Taking the floor out.
  

    // Floor height, if you wich to replace the floor with
    // blocks for a purer voxel aesthetic.
    //float flH = id.y*sc.y - path(id.z*sc.z).y + 1.5;
    
    // Render blocks for anything under the field value threshold.
    if(h<4.){
    // Taking out the raymarched floor, if you're strickly voxel. :)
    //if(h<4.|| flH<0.){ 


        // Rouding factor: Between zero and one, 
        // but things like ".05" make more sense.

        vec2 vrh = rhomDodeca(p, sc - .0, type);
        //float rh = rhomDodeca(p, sc - .025, .2);//sBoxS(p, sc/2. - .0, 0.);
        //float rh = length(p) - sc.x/2.;
        d = vrh.x + .005 + .0015;
        
        // The thin frame that encases the object.
        dFrame = vrh.y - .005 + .0015;
 
    }
       

    
   

    // Add some gradient glow to faux transparent blocks.
    if(h<4. && type==1){
        //float dd = d;
        vec3 oCol = getCol(id);
        float dd = length(p);//length(q3 - id*sc);
        
        // Glow color.
        // Sometimes, "pow(vec3(2.71828), x)" can be faster than "exp(x)".
        // I'm not sure why.
        // The exponential stuff related to Beer's law. It's fake in this
        // context, but adds a bit of refractive color variation.
        oCol = exp(-oCol*(dd - d)*18.); 
        oCol = oCol*(1. - oCol);
        // Adding the glow.
        glow += oCol/(.1 + dd*dd*4.);//max(1. - dd, 0.);  
        
        d = 1e5;
    } 
     
    
    
    // Saving the object dimensions, local coordinates and ID.
    gSc = sc; 
    gP = p;
    gID = vec4(1e5, id);
    
    // Saving the individual distance fields for sorting later.
    // Sorting things inside the loop can sometimes be more costly.
    // Not always, but with lots of objects, it usually is.
    gObjD = vec4(fl, d, dFrame, 1e5);
 
 
    // Scene distance.
    return min(fl, min(d, dFrame));
}


float gEdge;

float rayMarch(vec3 ro, vec3 rd) {
    
    float d, t = hash31(ro + rd)*.25; // Glow jitter.
    //const float tol = TOLERANCE;
    vec2 dt = vec2(1e8, 0); // IQ's edge desparkle trick.


    // Set the global ray direction varibles -- Used to calculate
    // the cell boundary distance inside the "map" function.
    gDir = step(0., rd) - .5; // sign(rd)*.5;
    gRd = rd;
    
    #define EDGE_THICKNESS .03
    gEdge = 1.;
    float edgeLength = 1.;//1e5;
    
    // Initialize the glow to zero.
    glow = vec3(0);

    const int iter = 128;
    int i = 0;
     
    for (i = 0; i<iter; i++) {
       
        d = map(ro + rd*t);
        
 
            
        //if(edgeLength<EDGE_THICKNESS && d>edgeLength) gEdge = edgeLength;
        //edgeLength = min(d, edgeLength);

        
        // IQ's clever edge desparkle trick. :)
        if (d<dt.x) { dt = vec2(d, t); } 

        if (d<.001 || t > FAR) {
            break;
        }
        
    
        t += min(d*.9, gCD);//min(min(d*.9, gCD), .1);
    }
    
    if(i == iter - 1) { t = dt.y; }


    return min(t, FAR);
}

float softShadow(in vec3 p, in vec3 ld, in float lDist, in float k) {
    
    float res = 1.;
    float t = 0.;

    // Set the global ray direction varibles -- Used to calculate
    // the cell boundary distance inside the "map" function.
    gDir = step(0., ld) - .5;
    gRd = ld; 

    for (int i=0; i<64; i++){

        float d = map(p + ld*t);
        res = min(res, k*d/t);
        if (d<0. || t>lDist) break;

        t += clamp(min(d*.9, gCD), .01, .25);
    }
    return clamp(res, 0., 1.);
}

// Normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 normal(in vec3 p) {
	
    //return normalize(vec3(map(p + e.xyy) - map(p - e.xyy), map
    //                      map(p + e.yxy) - map(p - e.yxy),	
    //                      map(p + e.yyx) - map(p - e.yyx)));
    
    // This mess is an attempt to speed up compiler time by contriving a break... It's 
    // based on a suggestion by IQ. I think it works, but I really couldn't say for sure.
    float sgn = 1.;
    vec3 e = vec3(.002, 0, 0), mp = e.zzz; // Spalmer's clever zeroing.
    for(int i = min(iFrame, 0); i<6; i++){
		mp.x += map(p + sgn*e)*sgn;
        sgn = -sgn;
        if((i&1)==1){ mp = mp.yzx; e = e.zxy; }
    }
    
    return normalize(mp);
}

// A slight variation on a function from Nimitz's hash collection, here: 
// Quality hashes collection WebGL2 - https://www.shadertoy.com/view/Xt3cDn
vec2 hash23(vec3 f){

    uvec3 p = floatBitsToUint(f);
    p = 1103515245U*((p >> 2U)^(p.yzx>>1U)^p.zxy);
    uint h32 = 1103515245U*(((p.x)^(p.y>>3U))^(p.z>>6U));

    uint n = h32^(h32>>16);

    uvec2 rz = uvec2(n, n*48271U);
    // Standard uvec2 to vec2 conversion with wrapping and normalizing.
    return vec2((rz>>1)&uvec2(0x7fffffffU))/float(0x7fffffff);
}

 
// A nice random hemispherical routine taken out of one of IQ's examples.
// The routine itself was written by Fizzer.
vec3 cosDir(in vec3 p, in vec3 n){

    vec2 rnd = hash23(p);
    float u = rnd.x;
    float v = rnd.y;
    
    // Method 1 and 2 first generate a frame of reference to use with an arbitrary
    // distribution, cosine in this case. Method 3 (invented by fizzer) specializes 
    // the whole math to the cosine distribution and simplfies the result to a more 
    // compact version that does not depend on a full frame of reference.

    // Method by fizzer: http://www.amietia.com/lambertnotangent.html
    float a = 6.2831853*v;
    u = 2.*u - 1.;
    return normalize(n + vec3(sqrt(1. - u*u)*vec2(cos(a), sin(a)), u));
    
}

 
// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float calcAO(in vec3 p, in vec3 n){
 
	float sca = 2., occ = 0.;
    for(int i = 0; i<12; i++){
    
        float hr = (float(i) + 1.)*.35/12.; 
        //float fi = float(i + 1);
        //vec3 rnd = vec3(hash31(p + fi), hash31(p + fi + .1), hash31(p + fi + .3)) - .5;
        //vec3 rn = normalize(n + rnd*.15);
        vec3 rn = cosDir(p + n*hr, n); // Random half hemisphere vector.
        float d = map(p + rn*hr);
        
        occ = occ + max(hr - d, 0.)*sca;
        sca *= .7;
    }
    
    return clamp(1. - occ, 0., 1.);    
    
}
 
/*
// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float calcAO(in vec3 p, in vec3 n){

	float sca = 2., occ = 0.;
    for( int i = 0; i<5; i++ ){
    
        float hr = float(i + 1)*.15/5.;        
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
        
        // Deliberately redundant line that may or may not stop the 
        // compiler from unrolling.
        //if(sca>1e5) break;
    }
    
    return clamp(1. - occ, 0., 1.);
}
*/
	


float lDist;
float t0;
float objRefF;

vec2 svUV;

vec4 render(inout vec3 ro, inout vec3 rd, int iter){

    
    // Surface distance.
    float t = rayMarch(ro, rd);
    
    // Saving the first pass hit distance for things like fog, and so forth.
    if(iter==0) t0 = t;

    // Saving the global scale, local cell coorinates and cell ID.
    vec3 svSc = gSc;
    vec3 svP = gP;
    vec4 svGID = gID;
    
    
    // Object ID: The block, the block frame and the floor.
    int objID = gObjD.x<gObjD.y && gObjD.x<gObjD.z? 0 : gObjD.y<gObjD.z? 1 : 2;
    
    
    float svEdge = (gEdge);
    
    vec3 svGlow = glow;
    
    vec3 gAtt = vec3(0);

    // Initializing.
    vec3 fog = vec3(1.2, .48, .3); // Background fog.
    vec3 col = fog;
    
    // Position.
    vec3 p = ro + rd*t;
   
    if (t < FAR){
  
        // Normal.
        vec3 n = normal(p);
        
        // Light: Point or directional. The directional light
        // doesn't really belong in this particular dark cavernous
        // setting, but it's there anyway.
        #if LIGHT_TYPE == 0
        ld = lp - p;
        lDist = length(ld);
        ld /= lDist;
        #else
        lDist = FAR;
        #endif
        
         
        // Shadow and ambient occlusion.
        float shd = softShadow(p + n*.0015, ld, lDist, 8.);
        float ao = calcAO(p, n);
        
 
        // Block ID and corresponding height.
        vec3 id = svGID.yzw;
     

    
        // Polyhedral color. 
        vec3 oCol = getCol(id);
        oCol = exp(-oCol*length(svP)*18.);
        oCol = oCol*(1. - oCol)*4.;
 
        // Object reflectance variables for multipasses. I'm pretty sure
        // they're not used here, but I'll leave them in, just in case. :)
        objRefF = 1.;
        //float lD = length(p - id*gSc);
        //gAtt = oCol/(.01 + lD*.2);
        
        // Darkening about 90 percent of the polyhedral blocks.
        if(hash31(id + .22)<.9 && objID!=0){
        
           oCol = vec3(.15)*dot(oCol, vec3(.299, .587, .114));
           objRefF = 0.; //hash31(id + .32)*.25;
           gAtt *= 0.;
         
        }
        
        // Darkening the raymarched edge strip object... I should probably
        // find a way to take the edges out of the raymarhing loop to speed
        // things up, but it's easier like this for now.
        if(objID==2) oCol = vec3(.02)*dot(oCol, vec3(.299, .587, .114)); 
        
        if(objID==0){ 
        
            // Floor.
        
            oCol = vec3(.025)*dot(oCol, vec3(.299, .587, .114)) + .025;  
            objRefF = .5; 
            gAtt *= 0.; 
        }
        
     
        // Texture coordinates.
        vec3 tx = tex3D(iChannel0, p/2. + .5, n);
        


        float difSt = .5;
        // Diffuse value.
        float dif = max(dot(ld, n), 0.);
        //dif = pow(dif, 2. + 2.*tx.x); // Diffusivity based on texture.
        
        // Specular value.
        float spe = pow(max(dot(reflect(ld, n), rd), 0.), 16.);

  
    
        //oCol += gAtt/8.;//
        
        // Subtle texture color.
        oCol *= tx*3. + .1;
        
        
        /*
        // Dark rhombic dodecahedron edges.
        // Block type. Opaque, or faux transparent.
        int type = hash31(id + .22)<.9? 0 : 1;

        vec2 vrh = rhomDodeca(svP, gSc, type);
        float frame = vrh.y;// + .0015;
        oCol = mix(oCol, vec3(0), 1. - smoothstep(0., .01, frame));
        */
    
      
       
        // Cheap specular reflections.
        float speR = pow(max(dot(normalize(ld - rd), n), 0.), 5.);
        vec3 rf = reflect(rd, n); // Surface reflection.
        vec3 rTx = texture(iChannel1, rf).xyz; rTx *= rTx;
        oCol += oCol*speR*rTx*2.;
        
        
       
        
        // I wanted to use a little more than a constant for ambient light this 
        // time around, but without having to resort to sophisticated methods, then I
        // remembered Blackle's example, here:
        // Quick Lighting Tech - blackle
        // https://www.shadertoy.com/view/ttGfz1
        //
        // Studio.
        float am = pow(length(sin((n)*3.14159/4.)*.5 + .5)/sqrt(3.), 2.)*1.5; 
        // Outdoor.
        //float am = length(sin(sn*2.)*.5 + .5)/sqrt(3.)*smoothstep(-1., 1., -sn.z); 
        


        // Lit color.
        col = oCol*(am + dif*shd + vec3(1, .7, .4)*spe*shd*4.)*ao;
        

 
        // Applying the edges to the prism.
        //col = mix(col, col*.05, 1. - smoothstep(0., .005, objEdge));
        //objRefF = mix(objRefF, 0., 1. - smoothstep(0., .005, objEdge));
       


        // Light attenuation. Barely visible, but it's there
        float rt = t/FAR;
        col *= 1.5/(1. + rt*.2); 
        
        
        ro = p + n*.0015;
        rd = reflect(rd, n);

    }
    
    svGlow = mix(svGlow.xzy, svGlow, smoothstep(.2, .8, svUV.y + .5));
   
    
    col += svGlow/16.;
    //fog = exp(-fog*t/FAR/1.5); fog = fog*(1. - fog)*3.;
    fog = mix(fog.xzy, fog, smoothstep(.2, .8, svUV.y + .5));
    
    // Fog.
    col = mix(col, fog, smoothstep(.3, .99, t0/FAR));
    
     //    col = mix(col.xzy, col, smoothstep(.2, .8, svUV.y + .5));
       
    // Returning the final color for this pass... There's only one
    // pass here, but a render function is useful when you want to
    // bounce light around.
    return vec4(col, t0);
  
}




void mainImage(out vec4 fragColor, in vec2 fragCoord ) {
 
    // Coordinates.
    vec2 u = (fragCoord - iResolution.xy*.5)/iResolution.y;
    svUV = u;
    
    vec3 lSc = GSCALE;
    // Look vector and camera origin.
    vec3 lk = vec3(0, -.6, iTime*2.);
    vec3 ro = lk + vec3(0, 0, -2.5);
    
    
    #if LIGHT_TYPE == 0
    lp = ro + vec3(0, 0, 4);
    lp.xy += path(lp.z);
    #else
    ld = normalize(vec3(0, 4, 4));
    lDist = FAR;
    #endif
    
    lk.xy += path(lk.z);
	ro.xy += path(ro.z);
 
    // Setting up a camera using the usual process. The variable names
    // here suggest that this lot came from one of IQ's examples.
    vec3 ww = normalize(lk - ro);
    vec3 uu = normalize(cross(vec3(0, 1, 0), ww ));
    vec3 vv = cross(ww, uu);
    const float FOV = 3.14159/3.; // Field of view.
    vec3 rd = normalize(u.x*uu + u.y*vv + ww/FOV); // Unit direction vector.
    
    
    // Swiveling the camera from left to right when turning corners.
    rd.xy = rot2(path(lk.z).x/24.)*rd.xy; 
    
   // Mouse movement.
    if(iMouse.z>1.){
        vec2 ms = -(iMouse.xy - iResolution.xy*.5)/iResolution.y;
        rd.yz *= rot2(ms.y*3.1459);  
        rd.xz *= rot2(ms.x*3.1459);  
    } 
     

    // Render... I was going to perform a couple of passes, but decided against 
    // it. However, it's usually a good idea to have a separate render function.
    
    
   
    
    float tt, refF = 1.;
    vec4 c4 = vec4(1);
    vec4 c42 = vec4(1);
    vec4 acc = vec4(0);
    for(int j = 0; j<1; j++){
 
        vec4 layer = render(ro, rd, j);
        
        //c4 *= layer;
        //acc += mix(c4, layer, .5)*refF;
        //acc = acc + layer - acc*layer;
        
        vec4 layer2 = layer;
        if(objRefF>0. && j>0) layer2.xyz = layer2.xyz*2.;
        //if(j>0) layer.xyz += refF*.5;
        c42 *= layer2;

        float oRef = j==0? 1. : objRefF;
        acc += mix(layer, c42, .5)*refF*oRef;
        
        if(j==0) tt = layer.w;
        if(objRefF<.001) break;
        refF *= .75;
        
    }
    
    c4.xyz = acc.xyz;
    
    
    vec3 col = c4.xyz;
    
    
    // Faux anitaliasing trick... Not really necessary here.
    // Requires "Buffer A" in "iChannel2".
    //vec4 tCol = texelFetch(iChannel2, ivec2(fragCoord), 0);
    //col = mix(tCol.xyz, col, 1./3.);
    
    // Rough gamma correction.
    //fragColor = vec4(pow(max(col, 0.), vec3(.4545)), 1);
    fragColor = vec4(max(col, 0.), acc.w);
    
    
}
