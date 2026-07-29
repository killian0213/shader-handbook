// Buffer A (buffer) — Icosahedral Spiral Weave  by Shane
// https://www.shadertoy.com/view/7dyfRc

/*

    Animated Icosahedral Weave
    --------------------------
    
    This is a common polyhedral weave that you may have seen around. I'm not 
    sure what it's officially called, but it's some kind of double layered
    three pronged star weave. They're normally precalculated using multiple 
    steps involving Beziers, etc, inside 3D applications like Blender, then 
    loaded into realtime applications after construction, but I thought it'd
    be fun attempting to produce one in realtime on Shadertoy.
    
    I'm stating the obvious here, but pixel shader restrictions coupled with
    realtime constraints meant that it was a bit difficult to produce the
    equivalent of an elegantly lit static path traced image, or prerecorded
    video. However, I employed a few cheap realtime tricks to at least convey 
    that feel.
    
    It would have been nice to make it better, faster, stronger, and all that, 
    but I ran out of time. There are definitely faster ways to render this 
    scene, but I figured I'd post it in its current form then try for something 
    nicer later. If I produced this with Bezier curves, it'd be a more 
    geometrically interesting looking object, but would also be way more 
    expensive.
    
    I put more effort into the background and color scheme than the icosahedral 
    sphere construction itself, which involved obtaining the nearest 
    icosahedral triangle face information, then using that to render two set of 
    three pronged arcs emminating from the center to offset midpoints.    
    
    For those of you experiencing ridiculous compile times, you have my apologies,
    but it really is beyond my control. All I can say is, I miss the days when
    everyone looked forward to compiler updates. :)

	
    Other examples:
    
  
    // In terms of aesthetics and sheer technical ability, this would
    // have to be one of my favorites.
    heavy metal squiggle orb - mattz
    https://www.shadertoy.com/view/wsGfD3
    
    // The flat plane version.
    Triangle Grid Spiral Weave - Shane
    https://www.shadertoy.com/view/7syfWz


*/
 

// Max ray distance.
#define FAR 20.


// Scene object ID to separate the mesh object from the terrain.
int objID;
vec4 vID;


// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.609, 57.583)))*43758.5453); }

// IQ's vec3 to float hash.
float hash31(in vec3 p){
    return fract(sin(dot(p, vec3(91.537, 151.761, 72.453)))*435758.5453);
}

// 3D rotation via two axis rotations. I should probably drop in a
// more concise 3D rotation formula from one of my other examples.
vec3 rotObj(in vec3 p){
   
    p.xz *= rot2(iTime/3./2.);
    p.yz *= rot2(iTime/6./3.); 
    
    return p;
    
}

// Tri-Planar blending function. Based on an old Nvidia tutorial by Ryan Geiss.
vec3 tex3D(sampler2D t, in vec3 p, in vec3 n){ 
    
    n = max(abs(n) - .2, .001); // max(abs(n), 0.001), etc.
    //n /= dot(n, vec3(.8)); 
    n /= length(n);
    
    // Texure samples. One for each plane.
    vec3 tx = texture(t, p.yz).xyz;
    vec3 ty = texture(t, p.zx).xyz;
    vec3 tz = texture(t, p.xy).xyz;
    
    // Multiply each texture plane by its normal dominance factor.... or however you wish
    // to describe it. For instance, if the normal faces up or down, the "ty" texture sample,
    // represnting the XZ plane, will be used, which makes sense.
    
    // Textures are stored in sRGB (I think), so you have to convert them to linear space 
    // (squaring is a rough approximation) prior to working with them... or something like that. :)
    // Once the final color value is gamma corrected, you should see correct looking colors.
    return mat3(tx*tx, ty*ty, tz*tz)*n; // Equivalent to: tx*tx*n.x + ty*ty*n.y + tz*tz*n.z;

}



// Commutative smooth minimum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
vec2 smin(vec2 a, vec2 b, float k){

   vec2 f = max(vec2(0), 1. - abs(b - a)/k);
   return min(a, b) - k*.25*f*f;
}

// Commutative smooth maximum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
vec2 smax(vec2 a, vec2 b, float k){
    
   vec2 f = max(vec2(0), 1. - abs(b - a)/k);
   return max(a, b) + k*.25*f*f;
}
 
// IQ's box routine.
float sBox(in vec2 p, in vec2 b, float r){

  vec2 d = abs(p) - b + r;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - r;
}


/*
// hash based 3d value noise
vec4 hash41T(vec4 p){
    
    return fract(sin(p)*43758.5453);
}

// Compact, self-contained version of IQ's 3D value noise function.
float n3DT(vec3 p){
    
	const vec3 s = vec3(27, 111, 57);
	vec3 ip = floor(p); p -= ip; 
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    p = p*p*(3. - 2.*p); 
    //p *= p*p*(p*(p*6. - 15.) + 10.);
    h = mix(hash41T(h), hash41T(h + s.x), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z); // Range: [0, 1].
}

// Two layers of noise.
float fBm(vec3 p){ return n3DT(p)*.57 + n3DT(p*2.)*.28 + n3DT(p*4.)*.15; }
*/ 

/////////
// A concatinated spherical coordinate to world coordinate conversion.
vec3 sphericalToWorld(vec3 sphCoord){
   
    vec4 cs = vec4(cos(sphCoord.xy), sin(sphCoord.xy));
    return vec3(cs.w*cs.x, cs.y, cs.w*cs.z)*sphCoord.z;
}
  

// Useful polyhedron constants. 
#define PI 3.14159265359
#define TAU 6.2831853
#define PHI 1.618033988749895 

//
// Since all triangles are the same size, etc, any triangles on
// a known icosahedron will do. The angles we need to determine are
// the angle from the top point to one of the ones below, the top
// point to the mid point below, and the angle from the top point
// to the center (centroid) of the triangle.
const vec3 triV0 = normalize(vec3(-1, PHI,  0));
const vec3 triV1 = normalize(vec3(-PHI, 0,  1));//0,  1,  PHI
const vec3 triV2 = normalize(vec3(0,  1,  PHI));//0,  1,  PHI
const vec3 mid = normalize(mix(triV1, triV2, .5));
const vec3 cntr = normalize(triV0 + triV1 + triV2);

// Angle between vectors: cos(a) = u.v/|u||v|. 
// U and V are normalized. Therefore, a = acos(u.v).
const float ang = acos(dot(triV0, triV1)); // Side length angle.
const float mAng = acos(dot(triV0, mid)); // Height angle.
const float cAng = acos(dot(triV0, cntr)); // Centroid angle.

// The latitude (in radians) of each of the top and bottom blocks is
// the angle between the top point (north pole) and one of the points below, 
// or the bottom point (south pole) and one of the ones above.
const float latBlock = ang;
const vec2 lat = vec2(cAng, mAng*2. - cAng);

//

// Returns the local world coordinates to the nearest triangle and the three
// triangle vertices in spherical coordinates.
vec3 getIcosTri(inout vec3 p, inout vec3[3] gVertID, const float rad){
       
 
    // Longitudinal scale.
    const float scX = 5.;


    // The sphere is broken up into two sections. The top section 
    // consists of the top row, and half the triangle in the middle
    // row that sit directly below. The bottom section is the same,
    // but on the bottome and rotated at PI/5 relative to the top. 
    // The half triangle rows perfectly mesh together to form the 
    // middle row or section.

    // Top and bottom section coordinate systems.The bottom section is 
    // rotated by PI/5 about the equator.
    vec3 q = p; // Top section coordinates.
    //vec3 q2 = vec3(rot2(-PI/scX)*p.xz, p.y).xzy; // Bottom section coordinates.

    // Converting to spherical coordinates.
    // X: Longitudinal angle -- around XZ, in this case.
    // Y: Latitudinal angle -- rotating around XY.
    // Z: The radius, if you need it.

    // Longitudinal angle for the top and bottom sections.
    ////vec4 sph = mod(a + vec4(0, 0, PI/5., PI/5.), TAU);
    vec4 sph = mod(atan(q.z, q.x) + vec4(0, 0, PI/5., PI/5.), TAU);
    sph = mod((floor(sph*scX/TAU) + vec4(.5, .5, 0, 0))/scX*TAU, TAU);


    float dist = 1e5;


    // Top and bottom block latitudes for each of the four groups of triangle to test.
    vec4 ayT4 = vec4(0, PI - latBlock, PI, latBlock);
    vec4 ayB4 = vec4(latBlock, latBlock, PI - latBlock, PI - latBlock);
    float ayT, ayB;

    int id;

    // Iterating through the four triangle group strips and determining the 
    // closest one via the closest central triangle point.
    for(int i = 0; i<4; i++){


        // Central vertex postion for this triangle.        
        int j = i/2;
        // The spherical coordinates of the central vertex point for this 
        // triangle. The middle mess is the lattitudes for each strip. In order,
        // they are: lat[0], lat[1], PI - lat[0], PI - lat[1]. The longitudinal
        // are just the polar coordinates. The bottom differ by PI/5. The final
        // spherical coordinate ranges from the sphere core to the surface.
        // On the surface, all distances are set to the radius.                
        vec3 sc = vec3(sph[i], float(j)*PI - float(j*2 - 1)*lat[i%2], rad);
 
        // Spherical to world, or cartesian, coordinates.
        vec3 wc = sphericalToWorld(sc);


        float vDist = length(q - wc);
        if(vDist<dist){
           dist = vDist;
           ayT = ayT4[i]; // Top triangle vertex latitude.
           ayB = ayB4[i]; // Bottom triangle vertex latitude.
           id = i;
        }


    }


    float ax = sph[id];
    // Flip base vertex postions on two blocks for clockwise order.
    float baseFlip = (id==0 || id==3)? 1. : -1.;

    // The three vertices in spherical coordinates. I can't remember why
    // I didn't convert these to world coordinates prior to returning, but
    // I think it had to do with obtaining accurate IDs... or something. :)
    gVertID[0] = vec3(ax, ayT, rad);
    gVertID[1] = vec3(mod(ax - PI/5.*baseFlip, TAU), ayB, rad);
    gVertID[2] = vec3(mod(ax + PI/5.*baseFlip, TAU), ayB, rad);

    // Top and bottom poles have a longitudinal coordinate of zero.
    if (id%2==0) gVertID[0].x = 0.;
 
     
    return q;
}




/////////
// Nimitz's simple basis function. I'll take people's word for it that it
// fails at the negative one Z point, so I've attempted to put in a hacky fix.
mat3 basis(in vec3 n){
    
    float a = min(1./(1. + n.z), 1e6);
    float b = -n.x*n.y*a;
    return mat3(1. - n.x*n.x*a, b, n.x, b, 1. - n.y*n.y*a, n.y, -n.x, -n.y, n.z);
}

// Readjusting the points to the surface of the sphere in question. The function here
// is the same as the one below, but that's not always the case.
vec3 size(in vec3 p, in float rad){

    //return p;
    return normalize(p)*rad;
}

vec3 sSize(in vec3 p, in float rad){
    
    return normalize(p)*rad;
}

// Sphere position: A little redundant, in this case.
vec3 sphPos = vec3(0);


// Scene distance function.
float map(vec3 p){
    
    
    
    // Rotate the sphere.
    vec3 q = rotObj(p - sphPos);

            
    // Icosahedron vertices and vertex IDs for the current cell.
    vec3[3] v, vertID;

    // Obtaining the local cell coordinates and spherical coordinates
    // for the icosahedron cell.
    const float rad = .5;
    vec3 lq = getIcosTri(q, vertID, rad);

    vec3 vAng = vertID[0];//(vertID[0] + vertID[1] + vertID[2])/3.;

    v[0] = sphericalToWorld(vertID[0]);//vec3(0, rad, 0);
    v[1] = sphericalToWorld(vertID[1]);
    v[2] = sphericalToWorld(vertID[2]);


     // The cell center, which doubles as a cell ID,
    // due to its uniqueness, which can be used for 
    // randomness, etc.
    //vec3 id = (v[0] + v[1] + v[2])/3.;
    vec3 tCntr = sSize(v[0] + v[1] + v[2], rad);


     // Icosahedral cell boundary.
    mat3 mEdge = mat3(cross(v[0], v[1]), cross(v[1], v[2]), cross(v[2], v[0]));
    vec3 ep = abs(normalize(lq)*mEdge)/length(v[0] - v[1]);  
    // Icosahedral triangle cell boundary. If you wanted the triangle, take the
    // "abs" above away.
    float line = min(min(ep.x, ep.y), ep.z);   


    float mOffs = .5/((sin(iTime/2.)*.5 + .5)*16.75 + 1.25); // Edge mid point offset. Smaller means wider.
    //float mOffs = .5/1.5;

    // Edge mid points, edge tangents and exit and entry points.
    vec3[3] mid, midA, midB;

    // Resizing the mid points.
    mid[0] = sSize(mix(v[0], v[1], .5), rad);
    mid[1] = sSize(mix(v[1], v[2], .5), rad);
    mid[2] = sSize(mix(v[2], v[0], .5), rad);



    // Dividing the cell triangles into three regions.
    vec3 quadSect;

    for(int i = 0; i<3; i++){

        int ip2 = (i + 2)%3;
        // Sectioning off the triangle into three seperate quads.
        float edg = dot((lq/rad), cross(tCntr, mid[i])/length(tCntr - mid[i]));
        float edg2 = dot((lq/rad), cross(mid[ip2], tCntr)/length(mid[ip2] - tCntr));
        quadSect[i] = min(edg, edg2); // Boundary for this region.

    }

    ////////////
    ////////////
    // Orthonormal basis calcultion.

    mat3 mB = basis(normalize(tCntr));
    vec3 qq = lq -  tCntr;
    vec3 blq = mB*qq;

    // Sizing the vertex points.
    v[0] = size(mB*v[0], rad);
    v[1] = size(mB*v[1], rad);
    v[2] = size(mB*v[2], rad);


    // The triangle cell center with sizing.
    tCntr = sSize(v[0] + v[1] + v[2], rad);

    
    // Midpoints, and midpoint offsets.
    for(int i = 0; i<3; i++){

        int ip1 = (i + 1)%3;
        int ip2 = (i + 2)%3;

        // Edge midpoints.
        mid[i] = size(mix(v[i], v[ip1], .5), rad);

        // Edge entry points -- One on each side of the mid point.                
        midA[i] = size(mix(v[i], v[ip1], .5 - mOffs), rad);
        midB[i] = size(mix(v[i], v[ip1], .5 + mOffs), rad);

    } 


    // Rendering the curves between entry and exit points. There are six
    // alltogether.
    float object = 1e5, bord = 1e5;

    // Normalizing Z values. It's a bit hacky and needs improvement, but it'll do. 
    float minDist = length(tCntr.xy - mid[0].xy); // Center to shortest side.
    float lnN = line/minDist;
    float lnN2 = max(1. - length(blq.xy - tCntr.xy)/minDist*.8660254, 0.);
    float lnNew = mix(lnN, lnN2, smoothstep(.1, .9, lnN));
 
    float rA = length(midA[0].xy - tCntr.xy);
    float rB = rA; //length(midB[0].xy - tCntr.xy); // Same distance.

    float zOffs = .2; 
    
    // Three pronged spirals. Unfortunately, animating the curves meant that I've had to 
    // render all three on the top and bottom, which is obviously slower. There are certain 
    // configurations that allow for repeat space tricks which are much faster, and I'll
    // demonstrate that at some stage.
    for(int i = 0; i<3; i++){

            // The next index.
            int ip1 = (i + 1)%3;
           

            // Top spiral prongs and borders.
            float obj = length(blq.xy - midB[i].xy) - rA; // rA
            vec2 oVec = vec2(obj, length(lq) - rad + lnNew*zOffs*rad);

            // There are some subtleties that I sometimes forget about. When partitioning
            // off an ofject, it should effectively be zero along the dimensions in which
            // you're doing it. Otherwise, there will be inconsistancies across boundaries.
            obj = sBox(oVec, vec2(.03*(1. + lnN*lnN), .025), .01) + .025;

            float tObj = sBox(oVec, vec2(.03*(1. + lnN*lnN) + .02, .025 - .015), .005) + .025;
            tObj = max(tObj, -quadSect[i]);
            obj = max(obj, -quadSect[i]);

            //if(obj<ln[0]) minI = i;
            object = min(object, obj);
            bord = min(bord, tObj);


            // Top spiral and border.
            obj = length(blq.xy - midA[i].xy) - rB; //rB
            oVec = vec2(obj, length(lq) - rad - lnNew*zOffs*rad);
            obj = sBox(oVec, vec2(.03*(1. + lnN*lnN), .025), .01) + .025;

            tObj = sBox(oVec, vec2(.03*(1. + lnN*lnN) + .02, .025 - .015), .005) + .025;
            tObj = max(tObj, -quadSect[ip1]);


            //obj = max(obj, -(svObj - .02));
            obj = max(obj, -quadSect[ip1]);
            object = min(object, obj);
            bord = min(bord, tObj);




    }
        
    // Giving the spiral prongs and borders some thickness.
    object -= .025;
    bord -= .025;


    // The top and bottom vertices.
    /*
    vec2 ve2;
    vec2 oVec = vec2(length(blq.xy), blq.z - (zOffs*rad - .0075));
    ve2.x = sBox(oVec, vec2(.025, .045), .015);
    oVec.y = blq.z + (zOffs*rad - .0075);
    ve2.y = sBox(oVec, vec2(.025, .045), .015);
    // Vertices and border. They're using the same material, so it
    // makes sense to group them together.
    float vert = min(min(ve2.x, ve2.y), bord);
    */
    
    // The top and bottom vertices -- Equivalent to above.
    vec2 oVec = vec2(length(blq.xy), abs(blq.z) - (zOffs*rad - .0075));
    float vert = sBox(oVec, vec2(.025, .045), .015);
    //
    // Vertices and border. They're using the same material, so it
    // makes sense to group them together.
    vert = min(vert, bord);
    

    //////////////////
    // The background wall and wavy background.
    //
    // Using a large sphere to create a slightly curved back wall.
    //float wall = -(length(p - sphPos - vec3(0, 0, -(48. - 3.))) - 48.);
    // Flat plane back wall.
    float wall = -p.z + 3.;
    
    // Perturbation.
    p.xy += sin(p.xy*4.)*.1;
    float px = p.x;
    p.xy = rot2(-3.14159/4.)*p.xy;

    // Subtle wall ridges to reflect the light in a more interesting way.
    const float s = 1./2.;
    float f = abs(fract(p.x/s) - .5)*2.;
    wall -= f*.05 - .05;


    // The repeate extruded wavy lines.
    vec2 q2 = p.xy;
    float ix = floor(q2.x/s) + .5;
    q2.x -= ix*s;
    q2 = vec2(q2.x, p.z - 3.);
    //float tube = length(q2) - .05 - cos(px*4.)*.02; // Round tubes.
    float tube = sBox(q2, vec2(.05 + cos(px*4.)*.0125, .1), .025); // Rounded square tubes.


    ////////////////////////////////    

    // Overall object ID -- There in one rundundant slot there.
    vID = vec4(tube, wall, vert, object);

    // Shortest distance.
    return  min(min(tube, wall), min(vert, object));
 
}

 
// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    // Overall ray distance and scene distance.
    float t = 0., d;
    
    for(int i = min(iFrame, 0); i<80; i++){
    
        d = map(ro + rd*t);
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, as
        // "t" increases. It's a cheap trick that works in most situations... Not all, though.
        if(abs(d)<.001 || t>FAR) break; // Alternative: 0.001*max(t*.25, 1.), etc.

        t += d*.7; 
    }

    return min(t, FAR);
}


// Normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 getNormal(in vec3 p, float t) {
	
    //return normalize(vec3(map(p + e.xyy) - map(p - e.xyy), map(p + e.yxy) - map(p - e.yxy),	
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



// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with limited 
// iterations is impossible... However, I'd be very grateful if someone could prove me wrong. :)
float softShadow(vec3 ro, vec3 lp, vec3 n, float k){

    // More would be nicer. More is always nicer, but not really affordable... Not on my slow test 
    // machine anyway.
    const int maxIterationsShad = 24; 
    
    ro += n*.0015;
    vec3 rd = lp - ro; // Unnormalized direction ray.
    

    float shade = 1.;
    float t = 0.;//.0015; // Coincides with the hit condition in the "trace" function.  
    float end = max(length(rd), 0.0001);
    //float stepDist = end/float(maxIterationsShad);
    rd /= end;

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. Obviously, the lowest 
    // number to give a decent shadow is the best one to choose. 
    for (int i = min(iFrame, 0); i<maxIterationsShad; i++){

        float d = map(ro + rd*t);
        shade = min(shade, k*d/t);
        //shade = min(shade, smoothstep(0., 1., k*h/dist)); // Subtle difference. Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += min(h, .2), dist += clamp(h, .01, stepDist), etc.
        t += clamp(d, .01, .25); 
        
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (d<0. || t>end) break; 
    }

    // Sometimes, I'll add a constant to the final shade value, which lightens the shadow a bit --
    // It's a preference thing. Really dark shadows look too brutal to me. Sometimes, I'll add 
    // AO also just for kicks. :)
    return max(shade, 0.); 
}


// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float calcAO(in vec3 p, in vec3 n)
{
	float sca = 2., occ = 0.;
    for( int i = min(0, iFrame); i<5; i++ ){
    
        float hr = float(i + 1)*.15/5.;        
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
        if(occ>1e5) break;
    }
    
    return clamp(1. - occ, 0., 1.);  
    
}




void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    // Frame blend value for the sphere.
    float fBlend = 0.;
    
    // Screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
	
	// Camera Setup.
	vec3 lk = vec3(0, 0, 0); // Camera position, doubling as the ray origin.
	vec3 ro = lk + vec3(cos(iTime/3.)*.1 + .0, .25, -2);//vec3(0, -.25, iTime);  // "Look At" position.
 
    // Light positioning. One is just in front of the camera, and the other is in front of that.
 	vec3 lp = ro + vec3(.25, .75, -1);// Put it a bit in front of the camera.
	

    // Using the above to produce the unit ray-direction vector.
    float FOV = .75; // FOV - Field of view.
    vec3 fwd = normalize(lk - ro);
    vec3 rgt = normalize(vec3(fwd.z, 0., -fwd.x)); 
    // "right" and "forward" are perpendicular, due to the dot product being zero. Therefore, I'm 
    // assuming no normalization is necessary? The only reason I ask is that lots of people do 
    // normalize, so perhaps I'm overlooking something?
    vec3 up = cross(fwd, rgt); 

    // rd - Ray direction.
    //vec3 rd = normalize(fwd + FOV*uv.x*rgt + FOV*uv.y*up);
    vec3 rd = normalize(uv.x*rgt + uv.y*up + fwd/FOV);
    
 	 
    
    // Raymarch to the scene.
    float t = trace(ro, rd);
    
    
    // Object identification: For two objects only, this is overkill,
    // but handy when using more.
    objID = 0;
    float obD = vID[0];
    for(int i = 0; i<4; i++){ 
        if(vID[i]<obD){ obD = vID[i]; objID = i; }
    }
    
	
    // Initiate the scene color to black.
	vec3 col = vec3(0);
	
	// The ray has effectively hit the surface, so light it up.
	if(t < FAR){
        
  	
    	// Surface position and surface normal.
	    vec3 sp = ro + rd*t;
	    //vec3 sn = getNormal(sp, edge, crv, ef, t);
        vec3 sn = getNormal(sp, t);
        
        
            	// Light direction vector.
	    vec3 ld = lp - sp;

        // Distance from respective light to the surface point.
	    float lDist = max(length(ld), .001);
    	
    	// Normalize the light direction vector.
	    ld /= lDist;

        
        
        // Shadows and ambient self shadowing.
    	float sh = softShadow(sp, lp, sn, 8.);
    	float ao = calcAO(sp, sn); // Ambient occlusion.
       
	    
	    // Light attenuation, based on the distances above.
	    float atten = 1./(1. + lDist*.05);

    	
    	// Diffuse lighting.
	    float diff = max( dot(sn, ld), 0.);
        //diff = pow(diff, 4.)*2.; // Ramping up the diffuse.
    	
    	// Specular lighting.
	    float spec = pow(max(dot(reflect(ld, sn), rd ), 0.), 32.); 
	    
	     
        
		// Schlick approximation. I use it to tone down the specular term. It's pretty subtle,
        // so could almost be aproximated by a constant, but I prefer it. Here, it's being
        // used to give a hard clay consistency... It "kind of" works.
		float Schlick = pow( 1. - max(dot(rd, normalize(rd + ld)), 0.), 5.);
		float freS = mix(.2, 1., Schlick);  //F0 = .2 - Glass... or close enough.        
        
          
        // Texel color. 
	    vec3 texCol = vec3(0); 
        
        
        // Frame blending hack to mitigate alliasing on the sphere edges.
        fBlend = 1. - smoothstep(-.2, .2, abs(dot(rd, sn)) - .2);
        
        // Specular reflection.
        vec3 hv = normalize(-rd + ld); // Half vector.
        vec3 ref = reflect(rd, sn); // Surface reflection.
        vec3 refTx = texture(iChannel1, ref).xyz; refTx *= refTx; // Cube map.
        float spRef = pow(max(dot(hv, sn), 0.), 16.); // Specular reflection.
        vec3 rCol = spRef*refTx*1.; //smoothstep(.03, 1., spRef)  
        
        // Texturing position and normal.
        vec3 txP = sp, txN = sn;


        // Object patterns, coloring, etc.        
        if(objID==0){ 
        
            // The wavy background lines.
            txP/= 2.;
            txP.xy *= rot2(-3.14159/4.);
             
            texCol = vec3(.7, .3, .1);
            texCol += rCol;
            
            // Metallic trick.
            diff = pow(diff, 4.)*2.;
           
        }
        else if(objID==1){ 
        
           
            //  The background itself.
            txP /= 1.;
            txP.xy = mix(txP.xy*1.5, txP.xy + sin(txP.xy*4. - vec2(0, iTime*0.))*.1, .35);
            txP.xy *= rot2(-3.14159/4.);
         
             // Color and reflection.
            texCol = vec3(.65);    
            texCol += rCol*.25; 

        }
        else if(objID==2){ 
        
            // The icosahedral border trim and vertices.
        
            // Texture position and normal.
            txP -= sphPos;

            // Rotation to match the scene movement.
            txP = rotObj(txP);
            txN = rotObj(txN);



            // Color and reflection.
            texCol = vec3(.7, .3, .1); 
            texCol += rCol;

            // Cheap metallic trick.
            diff = pow(diff, 4.)*2.;

        }
        else { 
        
            // Icosahedral color.
        
            // Texture position and normal.
            txP = sp - sphPos;
             
            // Rotation to match the scene movement.
            txP = rotObj(txP);
            txN = rotObj(txN);
             
            
             // Color and reflection.
            
            texCol = vec3(.85, .75, .57); // Pearl.
            //texCol = vec3(.4, .15, .8); diff = pow(diff, 4.)*2.; // Purple.
            //texCol = vec3(.5); diff = pow(diff, 4.)*2.; // Silver.
            //texCol = vec3(.07); diff = pow(diff, 4.)*2.; // Graphite.
            texCol += rCol;
            
            
        }
        

        vec3 tx; 
        if(objID==1){ 
            // Background wood grain.
            tx = tex3D(iChannel3, txP + .5, txN);
            texCol *= tx*2. + .06;
           
        }
        else { 
            // Metal and powder coat enamel.
            tx = tex3D(iChannel2, txP + .5, txN);
            texCol *= tx*2. + .3;
        }
        
        // Debug frame blending region.
        //texCol = mix(texCol, vec3(4, .2, .1), fBlend);
    	
        //texCol = mix(texCol, vec3(dot(texCol, vec3(.299, .587, .114))), .1);
        // Combining the above terms to procude the final color.
        col = texCol*(diff*sh + .3 + vec3(1, .7, .4)*spec*freS*sh*2.);
 


        // Shading.
        col *= ao*atten;
        
       
	
	}
    
    // Background fog: Normally you wouldn't have it, but I accidently left it in
    // and I don't want to reshade everything. :)
    col = mix(col, vec3(0), smoothstep(0., .99, t/FAR));
    
    // Mix the previous frames in with no camera reprojection. It's OK, but full 
    // temporal blur will be experienced. By the way, the fringes of the sphere are
    // blended more in a hacky attempt to reduce edge aliasing... It needs work. :)
    vec4 preCol = texelFetch(iChannel0, ivec2(fragCoord), 0);
    float blend = (iFrame < 2) ? 1. : 1./(1. + fBlend*8.); 
    fragColor = mix(preCol, vec4(clamp(col, 0., 1.), 1), blend);
    
    // No temporal blur, for comparison.
    //fragColor = vec4(max(col, 0.), 1);
	
}