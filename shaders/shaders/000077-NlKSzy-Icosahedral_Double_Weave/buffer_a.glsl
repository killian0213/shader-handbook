// Buffer A (buffer) — Icosahedral Double Weave by Shane
// https://www.shadertoy.com/view/NlKSzy

/*

    Icosahedral Double Weave
    ------------------------
    
    Quite some time ago, BigWIngs constructed a Truchet pattern consisting of
    segments that entered and exited from two points on each side of a repeat 
    polygon cell, which I thought was pretty awesome. He also cube mapped the 
    results. After that, a lot of people, including myself, produced a heap of 
    variations. I coded an icosahedral one not long afterwards, but Flockaroo, 
    who codes a lot faster than me, was able to post one straight away, so my 
    version has sat around gathering pixel dust on my hard-drive, as they say. :)
    
    Anyway, I dusted off the code not long ago, addressed a few problems that 
    had been bugging me, prettied it up a bit, and now it's done... two years
    after starting. :D You can never be sure, but as far as I can tell, 
    everything should line up perfectly with no fudge figures, etc. I've 
    rendered it in a similar style to BigWIngs's cube-mapped original to pay 
    hommage, but put some of my own touches in as well. 
    
    Producing one of these patterns, or any icosahedral cell based pattern,
    comes down to how easily you can uniquely identify and obtain the cell 
    information from one of the individual polygons. There are three main ways 
    to go about it: Brute force iteration, folding space, and spherical 
    coordinates. Each have their merits, but I went with the latter.
    
    Working with polyhedra, spherical coordinates, etc, can be a little tricky 
    and offputting, and attaching Beziers can add to the confusion, so 
    unfortunately, there aren't a lot of working examples to refer to. However, 
    if you are new but interested in this kind of thing, I'd suggest looking at 
    Flockaroo's examples.
    
    The algorithm I hacked together to produce the icosahedral cell information 
    is reasonbly fast and it works, but it could definitely be improved. It's 
    not as fast as Flockaroo's new function, and it would have been nice to drop 
    that in, but I think there are some wrapping issues that would need to be 
    ironed out first. TDHooper has a really promising algorithm based on folding 
    techniques, but I wasn't able to use it to correctly produce the cell 
    information I was after. Mattz also has some nicely written stuff, but I 
    haven't really had a chance to peruse through it.
    
    Once you have the triangle information, it's a matter of randomly connecting
    the entry and exit points with curves. I was hoping to find a better way,
    but unfortunately was forced to use piecewise Bezier curves. They get the job 
    done, but I'll be looking for something better when producing more 
    sophisticated examples. 
   

    

	Inspired by:
    
    // The original: I'd imagine BigWIngs is pretty busy these days being
    // YouTube code famous, and all that, but I hope he still finds time 
    // for more posts. :)
    Cube-mapped Double Quad Truchet - BigWIngs
    https://www.shadertoy.com/view/wlSGDD
    
	// I think Flockaroo produced this from inception in a day. It takes me 
    // that long just to choose a color. :D
    tri truch ballala  - flockaroo
	https://www.shadertoy.com/view/tl23DK
    
    // In terms of aesthetics and sheer technical ability, this would
    // have to be one of my favorites.
    heavy metal squiggle orb - mattz
    https://www.shadertoy.com/view/wsGfD3


*/
 

// Max ray distance.
#define FAR 20.

// Color: Green 0, Pinkish Red: 1, Blue: 2.
#define COLOR 0

// I've called it a scheme because I plan to expand on it, but for now
// it's just a representation of the amount of subdisions, which is 
// one, two or none at all. The latter looks pretty boring, but allows
// you to study the pattern and joins more closely.
//
// No subdivsions: 0, One subdivision: 1, Two subdivisions: 2.
#define SCHEME 2

// Scene object ID to separate the mesh object from the terrain.
int objID;
vec4 vID;


// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

/*
// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.609, 57.583)))*43758.5453); }

// IQ's vec3 to float hash.
float hash31(in vec3 p){
    return fract(sin(dot(p, vec3(91.537, 151.761, 72.453)))*435758.5453);
}
*/

// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21(vec2 f){

    uvec2 p = floatBitsToUint(f);
    p = 1664525U*(p>>1U^p.yx);
    return float(1103515245U*(p.x^(p.y>>3U)))/float(0xffffffffU);
    
}

// IQ's "uint" based uvec3 to float hash.
float hash31(vec3 f){

    uvec3 p = floatBitsToUint(f);
    p = 1103515245U*((p >> 2U)^(p.yzx>>1U)^p.zxy);
    uint h32 = 1103515245U*(((p.x)^(p.y>>3U))^(p.z>>6U));

    uint n = h32^(h32 >> 16);
    return float(n & uint(0x7fffffffU))/float(0x7fffffff);
}

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
     // Flat plane back wall.
    //float wall = -p.z + 2.;
    
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
    
    for(int i = min(iFrame, 0); i<80; i++){
    
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
    for(int i = min(iFrame, 0); i<6; i++){
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
        //if(occ>1e5) break;
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

 

// IQ's polynomial-based smooth minimum function.
vec3 smin( vec3 a, vec3 b, float r){

   vec3 f = max(1. - abs(b - a)/r, 0.);
   return min(a, b) - r*.25*f*f;
}
*/
/////////



// vec4 swap.
//void swap(inout vec4 a, inout vec4 b){ vec4 tmp = a; a = b; b = tmp; }

// A swap without the extra declaration -- It works fine on my machine, but I'm
// not game  enough to use it, yet. :)
//void swap(inout vec4 a, inout vec4 b){ a = a + b; b = a - b; a = a - b; }

 

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

    //return abs(dot(cross(a, b)/length(a - b), normalize(p)));

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
    for(int i = 0; i<N; i++){    
        vec3 bc2 = m43*bezierT(float(i + 1)/float(N));
        bc2 = normalize(bc2)*.5; // Mapping to the surface of the sphere.
        d = min(d, distLine(p, bc1, bc2));
        bc1 = bc2;
    }
   
    return d;
}


////////
// A 2D triangle partitioning. I've dropped in an old routine here.
// It works fine, but could do with some fine tuning.

// Skewing coordinates. "s" contains the X and Y skew factors.
vec2 skewXY(vec2 p, vec2 s){ return mat2(1, -s.yx, 1)*p; }

// Unskewing coordinates. "s" contains the X and Y skew factors.
vec2 unskewXY(vec2 p, vec2 s){ return inverse(mat2(1, -s.yx, 1))*p; }
#if SCHEME == 0
const float scale = 1./2.;
#elif SCHEME == 1
const float scale = 1./2.5;
#else
const float scale = 1./3.;
#endif

const vec2 rect = (vec2(1./.8660254, 1))*scale;
// Skewing half way along X, and not skewing in the Y direction.
const vec2 sk = vec2(rect.x*.5, 0)/scale; // 12 x .2


float gTri;
vec4 getTriVerts(vec2 p, inout vec2[3] vID, inout vec2[3] v){

    // Skewing half way along X, and not skewing in the Y direction.
    vec2 sk = vec2(rect.x*.5, 0)/scale; // 12 x .2

    // Skew the XY plane coordinates.
    p = skewXY(p, sk);
    
    // Unique position-based ID for each cell. Technically, to get the central position
    // back, you'd need to multiply this by the "rect" variable, but it's kept this way
    // to keep the calculations easier. It's worth putting some simple numbers into the
    // "rect" variable to convince yourself that the following makes sense.
	vec2 id = floor(p/rect) + .5; 
    // Local grid cell coordinates -- Range: [-rect/2., rect/2.].
	p -= id*rect; 
    
    
    // Equivalent to: 
    //gTri = p.x/rect.x < -p.y/rect.y? 1. : -1.;
    // Base on the bottom (-1.) or upside down (1.);
    gTri = dot(p, 1./rect)<0.? 1. : -1.;
   
    // Puting the skewed coordinates back into unskewed form.
    p = unskewXY(p, sk);
    
    
    // Vertex IDs for each partitioned triangle. These have been expanded 3 fold to 
    // account for GPU inaccuracies when dealing with irrational numbers. On a GPU, 
    // "1./3." and "1. - 2./3." are not the same thing, but they need to be for hash 
    // logic to work. However "1." and "3. - 2." are precisely the same.
    if(gTri<0.){
        vID = vec2[3](vec2(-1.5, 1.5), vec2(1.5, -1.5), vec2(1.5));
    }
    else {
        vID = vec2[3](vec2(1.5, -1.5), vec2(-1.5, 1.5), vec2(-1.5));
    }
    
    // Triangle vertex points.
    for(int i = 0; i<3; i++) v[i] = unskewXY(vID[i]*rect/3., sk); // Unskew.
    
    // Centering at the zero point.
    vec2 ctr = v[2]/3.;//(v[0] + v[1] + v[2])/3.;//
    p -= ctr;
    v[0] -= ctr;
    v[1] -= ctr;
    v[2] -= ctr;
    
     // Centered ID.
    vec2 ctrID = vID[2]; //(vID[0] + vID[1] + vID[2])/3.;//vID[2]/2.; //
    id = id*3. + ctrID;
    // Since these are out by a factor of three, "v = vertID*rect/3.".
    vID[0] -= ctrID; vID[1] -= ctrID; vID[2] -= ctrID;
 
 
 
    // Triangle local coordinates (centered at the zero point) and 
    // the central position point (which acts as a unique identifier).
    return vec4(p, id);
}


//////////



void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    float fBlend = 0.;
    
    // Screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
	
	// Camera Setup.
	vec3 lk = vec3(0, 0, 0); // Camera position, doubling as the ray origin.
	vec3 ro = lk + vec3(cos(iTime/3.)*.1, .5, -2);//vec3(0, -.25, iTime);  // "Look At" position.
 
    // Light positioning. One is just in front of the camera, and the other is in front of that.
 	vec3 lp = ro + vec3(.25, .75, -1);// Put it a bit in front of the camera.
	

    // Using the above to produce the unit ray-direction vector.
    float FOV = .7; // FOV - Field of view.
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
	    
	    // Fresnel term. Good for giving a surface a bit of a reflective glow.
        float fre = pow(clamp(1. + dot(sn, rd), 0., 1.), 2.);
        
        
		// Schlick approximation. I use it to tone down the specular term. It's pretty subtle,
        // so could almost be aproximated by a constant, but I prefer it. Here, it's being
        // used to give a hard clay consistency... It "kind of" works.
		float Schlick = pow( 1. - max(dot(rd, normalize(rd + ld)), 0.), 5.);
		float freS = mix(.2, 1., Schlick);  //F0 = .2 - Glass... or close enough.        
        
          
        // Texel color. 
	    vec3 texCol = vec3(0); 
        
        // General scene color.
        //
        
        #if COLOR == 0
        vec3 lCol = vec3(.45, .9, .2);
        lCol = mix(lCol.zyx, lCol, clamp(rd.y*2. + 1., 0., 1.));
        #elif COLOR == 1
        vec3 lCol = vec3(1.75, .12, .35);
        lCol = mix(lCol, vec3(1.2, .7, .1), clamp(rd.y*2. + .8, 0., 1.)*.2);
        #else
        vec3 lCol = mix(vec3(.2, .6, 1.5), vec3(.1, .9, .7), clamp(rd.y*2. + 1., 0., 1.)*.5);
        #endif
        
        
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
            vec3[6] vE2;
            
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
            for(int i = 0; i<subDivNum; i++){
            
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
            // Rendering lines on a sphere is a little different to those on a plane.
            // Lines between points translate to great arcs between points. This is
            // just three triangle edge borders. I normally do these individually, but
            // discovered this matrix short cut in on of Mattz's examples. Quite obvious...
            // once someone else did it. :)
            mat3 mEdge = mat3(cross(v[0], v[1]), cross(v[1], v[2]), cross(v[2], v[0]));
            vec3 ep = abs(normalize(lq)*mEdge)/length(v[0] - v[1]);  
            
            // Icosahedral triangle cell boundary. If you wanted the triangle, take the
            // "abs" above away.
            float line = min(min(ep.x, ep.y), ep.z) - .0035;
 
            
            
            // Calculating the tangent vectors for each edge, as well as the two
            // entry and exit points on each side of the mid-edge point. All are
            // used to produce the random curves within each triangle cell.
            for(int i = 0; i<3; i++){
                
                // Edge tangent vectors.
                vN[i] = normalize(cross(v[(i + 1)%3] - v[i], v[i]));
                // Cheap shortcut, but not quite accurate.
                //vN[i] = normalize(mix(v[(i + 2)%3], vE[i], .95) - vE[i]);
                // Due to the spherical correction in the Bezier function,
                // this could be used.
                //vN[i] = normalize(v[(i + 2)%3] - vE[i]);
                
                // Edge entry points -- One on each side of the mid point.
                float mOffs = .5/2.6; // Edge mid point offset.
                vE2[i*2] = normalize(mix(v[i], v[(i + 1)%3], .5 - mOffs))*rad;
                vE2[i*2 + 1] = normalize(mix(v[i], v[(i + 1)%3], .5 + mOffs))*rad;

            } 

            

            // Shuffling the 6 array points and normals by shuffling an array of indices. I 
            // think this is the Fisher–Yates method, but don't quote me on it. It's been a 
            // while since I've used a shuffling algorithm, so if there are inconsistancies, etc,
            // feel free to let me know -- It seems to work though, so that's a good sign. :)
            //
            // For various combinatorial reasons, some non overlapping tiles will probably be 
            // rendered more often, but generally speaking, the following should suffice.
            //
            // Indices for randomization.
            int[6] iRnd = int[6](0, 1, 2, 3, 4, 5);
            //int[6] iRnd = int[6](0, 2, 4, 1, 3, 5);
            //
            for(int i = 5; i>0; i--){

                // Using the cell ID and shuffle number to generate a unique random number.
                float fi = float(i);

                // Random number for each triangle: The figure "id" is unique for
                // each triangle, and "id + fi/24." should be unique for each iteration.
                float rs = hash31(id + fi/24. + .0273);

                // Other array point we're swapping with.
                //int j = int(floor(mod(rs*6e6, fi + 1.)));
                // I think this does something similar to the line above, but if not, let us know.
                int j = int(floor(rs*(fi + .9999)));
                //swap(iRnd[i], iRnd[j]);
                // Swap.
                int tmp = iRnd[i]; iRnd[i] = iRnd[j]; iRnd[j] = tmp;

            } 

            // Rendering the spline curves between entry and exit points. There are six
            // alltogether. We're indexing into random indices, and that creates the 
            // randomness, strangely enough. :)
            vec3 ln = vec3(1e5);
            for(int i = 0; i<3; i++){
                
                // Two random indices pointing to random entry and exit points.
                int iR = iRnd[(i*2)];
                int iRN = iRnd[(i*2 + 1)%6];

                // How far we wish to nudge out the second Bezier point in the direction
                // of the edge normal... That's an artform in its own right, which is
                // just another way to say, I'm guessing. :)
                float ndg = length(vE2[iR] - vE2[iRN])/2.5;
                //if(ndg<.001) ndg *= 2.;
                // Based purely on observation, exit and entry points on the same edge 
                // need the tangent points edged out more. 
                if(iR/2 == iRN/2) ndg *= 2.;//length(vE2[iR])/6. + length(vE2[iRN])/6.;
                
                // Take four points and render a spline curve. Rendering spline curves
                // is simple enough, but if you're not sure
                ln[i] = distSpline(lq, vE2[iR], vE2[iR] + vN[iR/2]*ndg, 
                                       vE2[iRN] + vN[iRN/2]*ndg, vE2[iRN]); 


            }

            // Give the edge some thickness.
            #if SCHEME > 1
            ln -= .01;
            #else
            ln -= .02;
            #endif
            
            
            
            // Rendering the vertices, borders and Bezier curvers.
            
            
            // Smoothing factor.
            float sf = .003; 
            
            // Initial background color.
            texCol = vec3(.05); 
            
            // Cell border lines.
            texCol = mix(texCol, vec3(.2), (1. - smoothstep(0., sf*2., line ))*.35);
            texCol = mix(texCol, vec3(.0), (1. - smoothstep(0., sf, line))*.9);
            
            // Cell vertices.
            vec3 v3 = vec3(length(lq - v[0]), length(lq - v[1]), length(lq - v[2])); 
            float vert = min(min(v3.x, v3.y), v3.z) - .01;
            texCol = mix(texCol, vec3(0), (1. - smoothstep(0., sf*4., vert - .005))*.35);
            texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, vert - .005));
            texCol = mix(texCol, vec3(.1), 1. - smoothstep(0., sf, vert));
            texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, vert + .005));

 
            // Rendering the bezier curves themselves. 
            for(int i = 0; i<3; i++){
                //float sh = max(.15 - ln[i]/.01, 0.);
                texCol = mix(texCol, vec3(0), (1. - smoothstep(0., sf*8., ln[i] - .01))*.5);
                texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, ln[i] - .0085));
                texCol = mix(texCol, lCol*1.2, 1. - smoothstep(0., sf, ln[i]));
                #if SCHEME <= 1
                texCol = mix(texCol, lCol/2.6, 1. - smoothstep(0., sf, abs(ln[i] + .011) - .0025));
                #else
                texCol = mix(texCol, lCol/2.6, 1. - smoothstep(0., sf, ln[i] + .006));
                #endif
            }
            
    
            
        }
        else if(objID==1){ 
        
            //  Wall.
            
            
            // Texture coordinates and normal.
            vec3 txP = sp;
            vec3 txN = sn;
            
            // Rotating the pattern for a different perspective.
            //txP.xy *= rot2(3.14159/6.);
         
            // Intial background color.
            texCol = vec3(.04);
            
            // Cell coordinate, ID and triangle orientation id.
            // Cell vertices and vertex ID.
            vec2[3] v, vID;

            // Returns the local coordinates (centered on zero), cellID, the 
            // triangle vertex ID and relative coordinates.
            vec4 p4 = getTriVerts(txP.xy, vID, v);
            vec2 p = p4.xy;
            vec2 id = p4.zw;
            float tri = gTri;
            vec2 triID = id;// + (vID[0] + vID[1] + vID[2])/3.;
            
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
            
            
            
            vert -= .0275;
             
            // Border triangles, bump highlights, etc. It was made up on the spot, and
            // I'm pretty sure there'd be better ways to do it. 3D bump mapping would
            // be better, but I'm keeping things simple and cheaper.
            vec2 q = p*vec2(1, tri);
            float tr = (max(abs(q.x)*.8660254 + q.y*.5, -q.y) - scale/3. + .01)/1.;
            float trr = length(q);
            q -= ld.xy*.005*(tri<0.? vec2(1) : vec2(1, -1));
            //float tr2 = (max(abs(q.x)*.8660254 + q.y*.5, -q.y) - scale/3. + .01)/1.;
            float trr2 = length(q);
            //float b = max(tr2 - tr, 0.)/.005;
            float b2 = max(trr2 - trr, 0.)/.005;
       
            // Blinking vertex color.
            float rndVert = hash21(vertID);
            float rnd = smoothstep(.9, .97, sin(rndVert*6.2831 + iTime)*.5 + .5);
            lCol = mix(vec3(.1), lCol, rnd);
            
            // Triangle pattern.
            texCol = mix(texCol, vec3(0), (1. - smoothstep(0., sf*4., tr - .005))*.5);
            texCol = mix(texCol, vec3(0), (1. - smoothstep(0., sf, tr - .005))*.9);
            texCol = mix(texCol, vec3(.05) + vec3(.2, .4, 1)*lCol*b2*.3, 1. - smoothstep(0., sf, tr));
            texCol = mix(texCol, texCol/2.5, 1. - smoothstep(0., sf, abs(tr + .025) - .005));
         
            // Vertices.
            texCol = mix(texCol, vec3(0), (1. - smoothstep(0., sf*8., vert - .015))*.35);
            texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, vert - .015));
            texCol = mix(texCol, lCol, 1. - smoothstep(0., sf, vert));
            texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, vert + .015));

            
            // Last minite 2D simplex weave pattern: Create 3 arcs about each vertex
            // point, then randomly render each over one another. I have one of these
            // on Shadertoy somewhere.
            vec3 v3 = vec3(length(p - v[0]), length(p - v[1]), length(p - v[2])); 
            //vert = min(min(v3.x, v3.y), v3.z) - .01;
            //
            // Random rotation.
            float rndI = hash21(id);
            if(rndI<.333) v3 = v3.yzx;
            else if(rndI<.666) v3 = v3.zxy;
            
            // Arc distance fields.
            float sl = length(v[0] - v[2])/2.;
            vec3 arc = abs(v3 - sl) - .025;
            // Double arc: Cool, but a little busy for this example.
            //arc = abs(arc - .025) - .025; 
            
            // Rendering the arc shadows, stroke, main layer, etc, over the top of one another.
            for(int i = 0; i<3; i++){
                texCol = mix(texCol, vec3(0), (1. - smoothstep(0., sf*8., arc[i] - .01))*.35);
                texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, arc[i] - .01));
                texCol = mix(texCol, vec3(.07), 1. - smoothstep(0., sf, arc[i]));
                texCol = mix(texCol, vec3(.07)/2.6, 1. - smoothstep(0., sf, arc[i] + .015));
            }
 
            
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
        col = texCol*(diff*sh + .3 + vec3(1, .5, .2)*spec*freS*sh*2. + vec3(.2, .4, 1)*fre*sh);
 


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