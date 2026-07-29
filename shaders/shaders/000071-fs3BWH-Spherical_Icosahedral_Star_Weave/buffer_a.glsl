// Buffer A (buffer) — Spherical Icosahedral Star Weave by Shane
// https://www.shadertoy.com/view/fs3BWH

/*

    Spherical Icosahedral Star Weave
    --------------------------------
    
    Placing an interwoven 3D polyhedral star pattern onto the surface of a
    sphere. It's a broad description, since there doesn't appear to be a 
    general concensus on what to call these things. :)
    
    An interwoven 3D polyhedral star pattern is really cool to look at. 
    You may have seen it in static image form on the internet. I noticed
    that it's a favorite amongst the 3D printed art crowd too. However, due 
    to realtime constraints and the long drawn out construction process 
    within 3D tools like Blender, they're not very common on Shadertoy.
    
    I remember putting in a request years ago after looking at one of Paul 
    Nylander's images, and Djinn Kahn put together an unlisted one which was 
    based on interlinked triangulated Beziers between an icosahedron and its 
    dual dodecahedron... 
    
    Like I said, it's a drawn out process, and that is without subdivision.
    Unfortunately, the really cool looking objects are based on subdivided 
    icosahedrons, which consist of irregular triangles, and that complicate
    things further. The star weave usually involves multiple point Beziers,
    which theoretically is as simple as inputting a larger number, but slows 
    things down even further.
    
    Therefore, I had to abandon my realtime 3D plans for the moment and 
    settle for a textured version. You may have noticed there's a bit of 
    code here, which may be a little off putting to someone who'd like to 
    make one of these. Just remember that a lot of it is prettying up, and 
    conceptually speaking, this is merely the rendering of a pattern onto a 
    curved triangle face.
    
    I'm going to produce a proper 3D version in static path traced form as a 
    compromise, and will upload that later. Without subdivision, a realtime 
    version is already possible, and with compromises a subdivided one would 
    be possible too, but I would like to produce a nice smooth looking one. 
    I have some ideas that I'll try out.
    
    As for for why the final design resembles a tacky Louis Vuitton knockoff, 
    I'm not sure how I arrived there, but I've visited a lot of tourist
    markets in my time. :D
   
    

	Other examples:
    
    // Star objects are annoying to model at the best of times, not fun to 
    // code, and are even less fun to produce inside a pixel shader 
    // environment, so only one person has even bothered to try. Djinn Kahn 
    // has an awesome grasp of geometry, but unfortunately, not a lot of 
    // spare time, so he doesn't post often. The link is unlisted, due to the 
    // compile time being very long on some machines.
    //
    surface knot starting point - DjinnKahn 
    https://www.shadertoy.com/view/lly3DK

*/

#define ZERO min(0, iFrame)

// Max ray distance.
#define FAR 20.

// Star weaves on the internet consist of five and six pronged stars over the 
// top of tri-pronged shapes, but sometimes the reverse pattern will appear.
//#define REVERSE_PATTERN
           
// I've called it a scheme because I plan to expand on it, but for now
// it's just a representation of the amount of subdisions, which is 
// one, two or none at all. The latter looks pretty boring, but allows
// you to study the pattern and joins more closely.
//
// No subdivsions: 0, One subdivision: 1, Two subdivisions: 2.
#define SCHEME 1

// Scene object ID to separate the mesh object from the terrain.
int objID;
vec4 vID;


// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.609, 57.583)))*43758.5453); }


// Commutative smooth minimum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smin(float a, float b, float k){

   float f = max(0., 1. - abs(b - a)/k);
   return min(a, b) - k*.25*f*f;
}




/////////
////////
// A 2D triangle partitioning. I've dropped in an old routine here.
// It works fine, but could do with some fine tuning.

// Skewing coordinates. "s" contains the X and Y skew factors.
vec2 skewXY(vec2 p, vec2 s){ return mat2(1, -s.yx, 1)*p; }

// Unskewing coordinates. "s" contains the X and Y skew factors.
vec2 unskewXY(vec2 p, vec2 s){ return inverse(mat2(1, -s.yx, 1))*p; }

// Back plane triangle pattern scale.
const float scale = 1./2.5;


const vec2 rect = (vec2(1./.8660254, 1))*scale;
// Skewing half way along X, and not skewing in the Y direction.
const vec2 sk = vec2(rect.x*.5, 0)/scale;


float gTri;
vec4 getTriVerts(vec2 p, inout vec2[3] vID, inout vec2[3] v){

    p = skewXY(p, sk);
    
    // Unique position-based ID for each cell. Technically, to get the central position
    // back, you'd need to multiply this by the "rect" variable, but it's kept this way
    // to keep the calculations easier. It's worth putting some simple numbers into the
    // "rect" variable to convince yourself that the following makes sense.
	vec2 id = floor(p/rect) + .5; 
    // Local grid cell coordinates -- Range: [-rect/2., rect/2.].
	p -= id*rect; 
    
    
    // Equivalent to: 
    //float tri = p.x/rect.x < -p.y/rect.y? 1. : 0.;
    // Base on the bottom (0.) or upside down (1.);
    gTri = dot(p, 1./rect)<0.? 0. : 1.;
   
    p = unskewXY(p, sk);
    
    const vec2[4] vertID = vec2[4](vec2(-.5, .5), vec2(.5), vec2(.5, -.5), vec2(-.5));


    if(gTri>.5){
        vID = vec2[3](vertID[0], vertID[2], vertID[1]);
    }
    else {
        vID = vec2[3](vertID[2], vertID[0], vertID[3]);
    }
    
    //id -= (vID[0] + vID[1] + vID[2])/3.;
    
    for(int i = 0; i<3; i++) v[i] = unskewXY(vID[i]*rect, sk); // Unskew.
    
    // Centering at the zero point.
    vec2 ctr = v[2]/3.; // (v[0] + v[1] + v[2])/3.;
    p -= ctr;
    v[0] -= ctr;
    v[1] -= ctr;
    v[2] -= ctr;

    // Centered at the zero point.
    return vec4(p, id);
}

//////////
/*
float getTriVerts(vec2 p){

    
    // Rectangle grid vertices.
    const vec2[4] vert = vec2[4](vec2(-.5, .5)*rect, vec2(.5)*rect, vec2(.5, -.5)*rect, vec2(-.5)*rect);

    // Skew the rectangular grid.
    p = skewXY(p, sk);

    // Local grid cell coordinates -- Range: [-rect/2., rect/2.].
	p -= (floor(p/rect) + .5)*rect; 
    
    // Base on the bottom (0.) or upside down (1.);
    gTri = dot(p, 1./rect)<0.? -1. : 1.;
   
    // Unskew.
    p = unskewXY(p, sk);
    
    // Triangle vertex points.
    vec2[3] v;
    // 
    if(gTri>.0){
        v = vec2[3](vert[0], vert[2], vert[1]);
    }
    else {
        v = vec2[3](vert[2], vert[0], vert[3]);
    }
    
    for(int i = 0; i<3; i++) v[i] = unskewXY(v[i], sk); // Unskew.
    
    // Centering at the zero point.
    p -= v[2]/3.; // Equivalent to: (v[0] + v[1] + v[2])/3.;


    // Centered at the zero point.
    return length(p);
}
*/

// Faster, more compiler friendly version for equilateral triangles.
float getTriVerts(vec2 p){

    
    // Skew the rectangular grid.
    p = skewXY(p, sk);

    // Local grid cell coordinates -- Range: [-rect/2., rect/2.].
	p -= (floor(p/rect) + .5)*rect; 
    
    
    // Triangle offset point.
    vec2 v = dot(p, 1./rect)<.0? -rect/2. : rect/2.;
    v = unskewXY(v, sk); // Unskew.
    
    
    // Unskew.
    p = unskewXY(p, sk);
    // Centering at the zero point.
    p -= v/3.;

    // Centered at the zero point.
    return length(p);
}
//////////


// 3D rotation via two axis rotations. I should probably drop in a
// more concise 3D rotation formula from one of my other examples.
vec3 rotObj(in vec3 p){
   
    p.xz *= rot2(iTime/3.);
    p.yz *= rot2(iTime/6.); 
    
    return p;
    
}

// Sphere position: A little redundant, in this case.
vec3 sphPos = vec3(0);


// Scene distance function.
float map(vec3 p){
    
    // Back wall.
    //
    // Using a large sphere to create a slightly curved back wall.
    float wall = -(length(p - sphPos - vec3(0, 0, -(16. - 2.))) - 16.);
    //float wall = -(length(p.xz - sphPos.xz - vec2(0, -(16. - 2.))) - 16.);
    // Flat plane back wall.
    //float wall = -p.z + 2.;// + length(p - sphPos - vec3(0, 0, 0))*.25;

    // Adding subtle spherical curves in a triangle pattern on the 
    // back wall to allow more intersting light reflection.
    float tr = getTriVerts(p.xy - vec2(0, .075));
    wall += tr*.25;

    /////    

    // Rotate the sphere.
    vec3 q = rotObj(p - sphPos);

    // Sphere.
    float sph = length(q) - .5;


    // Overall object ID -- There are two rundundant slots there.
    vID = vec4(sph, wall, 1e5, 1e5);

    // Shortest distance.
    return  min(sph, wall);
 
}

 
// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    // Overall ray distance and scene distance.
    float t = 0., d;
    
    for(int i = ZERO; i<80; i++){
    
        d = map(ro + rd*t);
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, as
        // "t" increases. It's a cheap trick that works in most situations... Not all, though.
        if(abs(d)<.001 || t>FAR) break; // Alternative: 0.001*max(t*.25, 1.), etc.

        t += d*.9; 
    }

    return min(t, FAR);
}


// Normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 getNormal(in vec3 p, float t) {
	
    const vec2 e = vec2(.001, 0);
    
    //return normalize(vec3(m(p + e.xyy) - m(p - e.xyy), m(p + e.yxy) - m(p - e.yxy),	
    //                      m(p + e.yyx) - m(p - e.yyx)));
    
    // This mess is an attempt to speed up compiler time by contriving a break... It's 
    // based on a suggestion by IQ. I think it works, but I really couldn't say for sure.
    float sgn = 1.;
    float mp[6];
    vec3[3] e6 = vec3[3](e.xyy, e.yxy, e.yyx);
    for(int i = ZERO; i<6; i++){
		mp[i] = map(p + sgn*e6[i/2]);
        sgn = -sgn;
        if(sgn>2.) break; // Fake conditional break;
    }
    
    return normalize(vec3(mp[0] - mp[1], mp[2] - mp[3], mp[4] - mp[5]));
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
    float end = max(length(rd), .0001);
    //float stepDist = end/float(maxIterationsShad);
    rd /= end;

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. Obviously, 
    // the lowest number to give a decent shadow is the best one to choose. 
    for (int i = ZERO; i<maxIterationsShad; i++){

        float d = map(ro + rd*t);
        shade = min(shade, k*d/t);
        //shade = min(shade, smoothstep(0., 1., k*h/dist)); // Subtle difference. Thanks to IQ for 
        // this tidbit. So many options here, and none are perfect: dist += min(h, .2), 
        // dist += clamp(h, .01, stepDist), etc.
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
    for( int i = ZERO; i<5; i++ ){
    
        float hr = float(i + 1)*.15/5.;        
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
        if(occ>1e5) break; // Fake break for compiler reasons.
    }
    
    return clamp(1. - occ, 0., 1.);  
    
}

///////

/* 
// Commutative smooth minimum function. Provided by Tomkh and taken from 
// Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smin(float a, float b, float r){

   float f = max(0., 1. - abs(b - a)/r);
   return min(a, b) - r*.25*f*f;
}
*/
/////////

 

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
    for(int i = ZERO; i<4; i++){


        // Central vertex postion for this triangle.        
        int j = i/2;
        // The spherical coordinates of the central vertex point for this 
        // triangle. The middle mess is the latitudes for each strip. In order,
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
    float baseFlip = (id==0 || id==3)? 1. : - 1.;

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


// IQ's line distance formula.
float distLine(vec3 p, vec3 a, vec3 b){

    p -= a; b -= a;
    float h = clamp(dot(p, b)/dot(b, b), 0., 1.);
    return length(p - b*h);
}

// Standard cubic Bezier interpolation.
vec4 bezierT(in float t){ 
    float u = 1. - t;
    return vec4(u*u*u, t*u*u*3., t*t*u*3., t*t*t);
}

// Cubic Bezier spline -- Not cheap, unfortunately, but thankfully,
// it's good enough for this example. I was hoping there'd be a better way,
// but so far, it appears to be the only way.
float distSpline(vec3 p, vec3 p0, vec3 p1, vec3 p2, vec3 p3){

    // Distance.
    float d = 1e5, t = 0.;
    
    mat4x3 m43 = mat4x3(p0, p1, p2, p3);
    
    // It's not absolutely necessary, but I'm mapping the points
    // to the surface of the sphere as I go along.
    vec3 bc1 = normalize(p0)*.5;//normalize(m43*bezierT(0.))*.5;

    // Several lines to approximate a smooth curve. Ouch! :) It's being called
    // outside the raymarching loop, so we can get away with it.
    const int N = 16;
    for(int i = ZERO; i<N; i++){ 
    
        vec3 bc2 = m43*bezierT(float(i + 1)/float(N));
        bc2 = normalize(bc2)*.5; // Mapping to the surface of the sphere.
        
        //d = min(d, distLine(p, bc1, bc2));
        float w = float(i)/float(N);
        float l = length(p - bc1)/length(bc1 - bc2);
        // Variable thickness. More at the start, but you can do it
        // the other way around, or not at all.
        const float th = .0075;
        d = min(d, distLine(p, bc1, bc2) - (1. - (w + l/float(N)))*th);
        bc1 = bc2;
        
        //if(d<-1e5) break;
    }
   
    return d;
}


// Incircle of a 3D triangle: Basically the 3D extension of
// the 2D version... I was in a hurry, but it seems about right.
// Let me know if the logic doesn't follow.
// 
vec3 inCircle(in vec3 v0, in vec3 v1, in vec3 v2){
    
    // Side lengths.
    vec3 len = vec3(length(v2 - v1), length(v0 - v2), length(v1 - v0));
    return mat3(v0, v1, v2)*len/dot(len, vec3(1));
}

/*
// Angle between 3D vectors. Similar to the 2D version. It's easy to derive
// this yourself, or look it up on the internet.
float angle(vec3 p0, vec3 p1){

    return acos(dot(p0, p1)/(length(p0)*length(p1)));
}
*/

void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    float fBlend = 0.;
    
    // Screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
	
	// Camera Setup.
	vec3 lk = vec3(0, 0, 0); // Camera position, doubling as the ray origin.
	vec3 ro = lk + vec3(cos(iTime/3.)*.1, .25, -1.75);//vec3(0, -.25, iTime);  // "Look At" position.
 
    // Light positioning. One is just in front of the camera, and the other is in front of that.
 	vec3 lp = ro + vec3(.25, .75, -1);// Put it a bit in front of the camera.
	

    // Using the above to produce the unit ray-direction vector.
    float FOV = .75; // FOV - Field of view.
    vec3 fwd = normalize(lk-ro);
    vec3 rgt = normalize(vec3(fwd.z, 0., -fwd.x)); 
    // "right" and "forward" are perpendicular, due to the dot product being zero. Therefore, I'm 
    // assuming no normalization is necessary? The only reason I ask is that lots of people do 
    // normalize, so perhaps I'm overlooking something?
    vec3 up = cross(fwd, rgt); 

    // rd - Ray direction.
    //vec3 rd = normalize(fwd + FOV*uv.x*rgt + FOV*uv.y*up);
    vec3 rd = normalize(uv.x*rgt + uv.y*up + fwd/FOV);
    
    // Swiveling the camera about the XY-plane.
	//rd.xy *= rot2( sin(iTime)/32. );
 	 
    
    // Raymarch to the scene.
    float t = trace(ro, rd);
    
    
    /*
    // Object identification: For two objects only, this is overkill,
    // but handy when using more.
    objID = 0;
    float obD = vID[0];
    for(int i = 0; i<4; i++){ 
        if(vID[i]<obD){ obD = vID[i]; objID = i; }
    }
    */
    
    // Object identification.
    objID = vID[0]<vID[1]? 0 : 1;
	
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
	    
	    // Fresnel term. Good for giving a surface a bit of a reflective glow.
        float fre = pow(clamp(1. + dot(sn, rd), 0., 1.), 2.);
        
        
		// Schlick approximation. I use it to tone down the specular term. It's pretty subtle,
        // so could almost be aproximated by a constant, but I prefer it. Here, it's being
        // used to give a hard clay consistency... It "kind of" works.
		float Schlick = pow( 1. - max(dot(rd, normalize(rd + ld)), 0.), 5.);
		float freS = mix(.2, 1., Schlick);  //F0 = .2 - Glass... or close enough.        
        
          
        // Texel color. 
	    vec3 texCol = vec3(0); 
        
        
        // Specular reflection.
        vec3 hv = normalize(-rd + ld); // Half vector.
        vec3 ref = reflect(rd, sn); // Surface reflection.
        vec3 refTx = texture(iChannel1, ref).xyz; refTx *= refTx; // Cube map.
        float spRef = pow(max(dot(hv, sn), 0.), 16.); // Specular reflection.
        vec3 rCol = spRef*refTx*1.; //smoothstep(.03, 1., spRef)   
        
        
        // Frame blending hack to mitigate alliasing on the sphere edges.
        fBlend = 1. - smoothstep(-.2, .2, abs(dot(rd, sn)) - .2);

        // Object patterns, coloring, etc.        
        if(objID==0){ 
        
            // The sphere.
            
            // Texture position and normal.
            vec3 txP = sp - sphPos;
            vec3 txN = sn;
            
            // Rotation to match the scene movement.
            txP = rotObj(txP);
            txN = rotObj(txN);
             
            
            // Icosahedron vertices and vertex IDs for the current cell.
            vec3[3] gVert, gVertID;
            
            // Obtaining the local cell coordinates and spherical coordinates
            // for the icosahedron cell.
            const float rad = .5;
            vec3 lq = getIcosTri(txP, gVertID, rad);
   
            gVert[0] = sphericalToWorld(gVertID[0]);//vec3(0, rad, 0);
            gVert[1] = sphericalToWorld(gVertID[1]);
            gVert[2] = sphericalToWorld(gVertID[2]);
            
            
            vec3[3] v = gVert, vID = gVertID;
            
            // Edge mid points, edge tangents and exit and entry points.
            vec3[3] vE, vN;
            //vec3[6] vE2;
            
            // Edge mid points.
            vE[0] = normalize(mix(v[0], v[1], .5))*rad;
            vE[1] = normalize(mix(v[1], v[2], .5))*rad;
            vE[2] = normalize(mix(v[2], v[0], .5))*rad;
             
            
            /////
            #if SCHEME > 0
            // Triangle subdivision, if desired.
            //
            // Number of subdivisions.
            #if SCHEME == 1
            const int subDivNum = 1;
            #else
            const int subDivNum = 2;
            #endif
            //
            // There'd be faster ways to do this, but this is
            // relatively cheap, and it works well enough.
            for(int i = ZERO; i<subDivNum; i++){
            
                // Create three line boundaries within the triangle to 
                // partition into four triangles. Pretty standard stuff.
                // By the way, there are other partitionings, but this 
                // is the most common. At some stage, I'll include some
                // others, like the three triangle version connecting the 
                // center to the vertices.
                //
                if(dot(lq, cross(vE[0], vE[1]))>0.){
                    v[0] = vE[0]; v[2] = vE[1];
                }
                else if(dot(lq, cross(vE[1], vE[2]))>0.){
                    v[0] = vE[2]; v[1] = vE[1];
                }
                else if(dot(lq, cross(vE[2], vE[0]))>0.){
                    v[1] = vE[0]; v[2] = vE[2];
                }
                else {
                    v[0] = vE[2]; v[1] = vE[0]; v[2] = vE[1];
                }
                
                // Recalculating the edge mid-vectors for the next iteration.
                vE[0] = normalize(mix(v[0], v[1], .5))*rad;
                vE[1] = normalize(mix(v[1], v[2], .5))*rad;
                vE[2] = normalize(mix(v[2], v[0], .5))*rad;                
            }
            #endif
            /////    
            
  
            // The cell center, which doubles as a cell ID,
            // due to its uniqueness.
            vec3 ctr = normalize((v[0] + v[1] + v[2]))*rad;
            // The unique cell ID, which is used for randomness, etc.
            vec3 id = ctr;
            
 


            // Icosahedral cell boundary.
            //
            // Rendering lines onto a sphere is a little different to those on a plane.
            // Lines between points translate to great arcs between points. This is
            // just three triangle edge borders. I normally do these individually, but
            // discovered this matrix short cut in on of Mattz's examples. Quite obvious...
            // once someone else did it. :)
            mat3 mEdge = mat3(cross(v[0], v[1]), cross(v[1], v[2]), cross(v[2], v[0]));
            vec3 ep = abs(normalize(lq)*mEdge)/length(v[0] - v[1]);  
            //
            // Icosahedral triangle cell boundary. If you wanted the triangle, take the
            // "abs" above away.
            float cellLine = min(min(ep.x, ep.y), ep.z) - .0035;
 
            
            
            // Calculating the tangent vectors for each edge, as well as the two
            // entry and exit points on each side of the mid-edge point. All are
            // used to produce the random curves within each triangle cell.
            for(int i = ZERO; i<3; i++){
                
                // Edge tangent vectors.
                vN[i] = normalize(cross(v[(i + 1)%3] - v[i], v[i]));
            } 

            

            // Debug stuff.
            // vec3 fiveStar = vec3(0);

            // Rendering the spline curves between entry and exit points.
            
            float line = 1e5;
            float line2 = 1e5;
            
            vec3 cn = normalize(inCircle(v[0], v[1], v[2]))*rad;
            
            for(int i = ZERO; i<3; i++){
   
                int ip1 = (i + 1)%3;  
                int ip2 = (i + 2)%3; 
                //vec3 cntr0 =  normalize(v[0] + v[1] + v[2])*rad; 
                
                // Edge entry points -- One on each side of the mid point.
                float mOffs = .5/8.; // length(v[i] - v[ip1])/4.; //Edge mid point offset.
                
      
                float spLn, ndg;
                vec3 a, b, aN, bN, tN;
                
                // Three pronged central Bezier lines.
                //tN = normalize(v[ip1] - v[i]);
                // You have to set up four Bezier points to run the lines through. The end points
                // are kind of set, since they need to begin at the center and exit at points
                // near the midpoint of the edges. Where you place the other two points dictates
                // the shape of the curve, and that's up to you. For me, I use vectors aN and bN 
                // that point away from "a" and "b" respectively, then I use them to estimate 
                // where the second and third points should be... Sounds annoying? It is. :D 
                // However, with practice, it gets better. :)
                a = cn; 
                b = normalize(mix(v[i], v[ip1], .5 - mOffs))*rad;  // Just past the mid edge.
                aN = normalize(cross(normalize(v[i] - cn)*rad, v[ip2] - v[ip1]));
                bN = vN[i];

                // How far we wish to nudge out the second and third Bezier points... 
                // That's an artform in its own right, which is just another way to say, 
                // I'm guessing. :)
                ndg = length(a - b)/2.6;

                // Take four points and render a spline curve. Rendering spline curves
                // is simple enough, but if you're not sure, there is plenty of information
                // on them.
                spLn = distSpline(lq, a, normalize(a + aN*ndg)*rad, normalize(b + bN*ndg)*rad, b); 
                line = min(line, spLn);

                // Five and six pronged stars eminating from the triangle vertices.
                //tN = v[ip2] - v[ip1];
                a = v[i];
                b = normalize(mix(v[i], v[ip1], .5 + mOffs))*rad; // Just past the mid edge.
                // Where you place the points is up to you. This was the tweak that I preferred.
                aN = normalize(mix(cn, vE[ip2], .5) - v[i]);//normalize(cross(v[i], vE[ip2] - vE[ip1]));
                bN = vN[i];

                // How far we wish to nudge out the second and third Bezier points.
                ndg = length(a - b)/2.6;


                //vec2 q = p*vec2(-1, 1);
                // Take four points and render a spline curve.
                spLn = distSpline(lq, normalize(a - aN*ndg*.25)*rad, normalize(a + aN*ndg)*rad, 
                                      normalize(b + bN*ndg)*rad, b);  
           
                line2 = min(line2, spLn);
                
                // Using stupid tricks in a futile attempt to get the compile times down.
                //if(line2<-1e8) break;
           
                /*
                // Debug.
                float ang = angle(cross(v[(i + 1)%3], v[i]), cross(v[(i + 2)%3], v[i]));
                if(abs(ang - 6.2831/5.)<.001) fiveStar[i] = 1.;
                */
           }

            // Give the edge some thickness.
            #if SCHEME > 1
            line -= .008;
            line2 -= .008;
            #elif SCHEME == 1
            line -= .014;
            line2 -= .014;
            #else
            line -= .025;
            line2 -= .025;
            #endif
     
            //line = 1e5; line2 = 1e5;
            
            // Cell vertices.
            vec3 v3 = vec3(length(lq - v[0]), length(lq - v[1]), length(lq - v[2])); 
            float vert = min(min(v3.x, v3.y), v3.z);
            
            // Rounding off the centers.
            // Rounding off the centers.
            #if SCHEME == 1
            line = smin(line, length(lq - cn) - .018, .015);
            line2 = smin(line2, vert - .048, .015);
            line2 = min(line2, vert - .05);
            #elif SCHEME == 0
            line = smin(line, length(lq - cn) - .033, .015);
            line2 = smin(line2, vert - .063, .015);
            line2 = min(line2, vert - .065);
            #endif
            
            
            
            // Rendering the vertices, borders and Bezier curvers.
            
            
            // Smoothing factor.
            float sf = .003; 
            
            // Triangle cell lines.
            const float lNum = 80.;
            float tLns = (abs(fract(cellLine*lNum - .333) - .5)*2. - .125)/lNum/2.;
            texCol = mix(vec3(.1), vec3(0), (1. - smoothstep(0., sf, tLns))*.7);
            
            // Cell border lines.
            //texCol = mix(texCol, texCol + .1, (1. - smoothstep(0., sf*2., cellLine)));
            //texCol = mix(texCol, vec3(0), (1. - smoothstep(0., sf, cellLine))*.9);
            
            #ifdef REVERSE_PATTERN
            // Reversing the pattern is as simple as reversing the rendering order.
            float tmp = line; line = line2; line2 = tmp;
            #endif
            
            vec3 lCol = vec3(1, .925, .85);
            // Other colors: vec3(.5, 1, 1.5);//vec3(.75, 1.4, .3);//vec3(1, .925, .85);
            vec3 trCol = vec3(.8, .55, .35)/1.5; // Trim color.
            
  
            // Adding some specular reflection.
            trCol += rCol*.7;
            lCol += rCol*.7;
            texCol += rCol*.1;
 
            // Rendering the bezier curves themselves. 
            
    
            //float sh = max(.05 - ln[i]/.025, 0.);
            texCol = mix(texCol, vec3(0), (1. - smoothstep(0., sf*6., line))*.75);
            texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, line));
            texCol = mix(texCol, lCol, 1. - smoothstep(0., sf, line + .01));
            #if SCHEME <= 1
            texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, abs(line + .00875) - .00175));
            texCol = mix(texCol, trCol, 1. - smoothstep(0., sf, abs(line + .005) - .001));
            #else
            texCol = mix(texCol, trCol, 1. - smoothstep(0., sf, line + .006));
            #endif 

            //sh = max(.05 - ln2[i]/.025, 0.);
            texCol = mix(texCol, vec3(0), (1. - smoothstep(0., sf*6., line2))*.75);
            texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, line2));
            texCol = mix(texCol, lCol, 1. - smoothstep(0., sf, line2 + .01));
            #if SCHEME <= 1
            texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, abs(line2 + .00875) - .00175));
            texCol = mix(texCol, trCol, 1. - smoothstep(0., sf, abs(line2 + .005) - .001));
            #else
            texCol = mix(texCol, trCol, 1. - smoothstep(0., sf, line2 + .006));
            #endif               

            
            // Cell vertices.
            #if SCHEME == 1
            vert -= .0195;
            #elif SCHEME == 0
            vert -= .0275;
            #endif
            texCol = mix(texCol, vec3(0), (1. - smoothstep(0., sf*4., vert))*.35);
            texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, vert));
            texCol = mix(texCol, trCol, 1. - smoothstep(0., sf, vert + .005));
            texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, vert + .0115));
            texCol = mix(texCol, vec3(.18, .15, .12) + rCol*.5, 1. - smoothstep(0., sf, vert + .0165));
 
            
        }
        else { 
        
            //  Wall.
            
            
            // Texture coordinates and normal.
            vec3 txP = sp;
            vec3 txN = sn;
            
            // Moving the pattern down a bit.
            txP.y -= .075;
            
            // Rotating the pattern for a different perspective.
            // Would need to be matched inside the distance function too.
            //txP.xy *= rot2(3.14159/6.);
            
            
            // Cell coordinate, ID and triangle orientation id.
            // Cell vertices and vertex ID.
            vec2[3] v, vID;

            // Returns the local coordinates (centered on zero), cellID, the 
            // triangle vertex ID and relative coordinates.
            vec4 p4 = getTriVerts(txP.xy, vID, v);
            vec2 p = p4.xy;
            vec2 id = p4.zw;
            float tri = gTri;
            vec2 triID = id + (vID[0] + vID[1] + vID[2])/3.;
            
            // Smoothing factor.
            float sf = .003;
            
            // Nearest vertex ID.
            float vert = 1e5;
            
            vec2 vertID;
            for(int i = 0; i<3; i++){
                float vDist = length(p - v[i]);
                if(vDist<vert){
                    vert = vDist;
                    vertID = id + vID[i];
                }
            }
 
             
            // Border triangles, bump highlights, etc. It was made up on the spot, and
            // I'm pretty sure there'd be better ways to do it. 3D bump mapping would
            // be better, but I'm keeping things simple and cheaper.
            vec2 q = tri<.5? p : p*vec2(1, -1);
            float tr = (max(abs(q.x)*.8660254 + q.y*.5, -q.y) - scale/3. + .0125)/1.;
            tr = max(tr, -(vert - .07));
            
            
            
            // Intial background triangle color.
            texCol = mix(texCol, vec3(.085), (1. - smoothstep(0., sf, tr))*.9);
            
            // Subtle reflection.
            texCol += rCol*.1;
            
            // Concentric triangle lines.
            const float lNum = 26.;
            float tLns = (abs(fract(tr*lNum + .25) - .5)*2. - .333)/lNum/2.;
            texCol = mix(texCol, vec3(0), (1. - smoothstep(0., sf, max(tr, tLns)))*.7);
         
            // Vertices with subtle reflection.
            vert -= .0675;
            texCol = mix(texCol, vec3(0), (1. - smoothstep(0., sf*6., vert))*.75);
            texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, vert));
            texCol = mix(texCol, vec3(.18, .15, .12) + rCol*.7, 1. - smoothstep(0., sf, vert + .015));
            texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, vert + .035));
            texCol = mix(texCol, vec3(.085) + rCol*.5, 1. - smoothstep(0., sf, vert + .05));
           
 
            
        }
        /*
        // Extra objects.
        else if(objID==2){ 

            texCol = vec3(1);
        }
        else { // Wall.
   
            texCol = vec3(1);
        }
        */
    
                
        // Debug frame blending region.
        //texCol = mix(texCol, vec3(4, .2, .1), fBlend);
    	
        
        // Combining the above terms to procude the final color.
        col = texCol*(diff*sh + .3 + vec3(1, .7, .4)*spec*freS*sh);
 
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
    //fragColor = vec4(max(aCol, 0.), 1);
	
}