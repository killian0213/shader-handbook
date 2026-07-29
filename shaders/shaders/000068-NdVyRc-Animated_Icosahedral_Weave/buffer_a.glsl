// Buffer A (buffer) — Animated Icosahedral Weave by Shane
// https://www.shadertoy.com/view/NdVyRc

/*

    Animated Icosahedral Weave
    --------------------------
    
    Of all the geometric art out there, 3D polyhedron variations would have to 
    be among my favorites. This is more of a 3D polyhedral texture demonstration,
    but I'll post more interesting 3D ones later. This is the icosahedral 
    version of my previous "Animated Triangle Grid Weave" example. I was pretty 
    sure it'd work in theory, but couldn't be sure until I tried it. I was able 
    to use an icosahedral template of mine, so thankfully, didn't have to put 
    too much thinking into it.
    
    In fact, I put more effort into the background and color scheme than the 
    icosahedral sphere construction itself. Technically speaking, there wasn't
    a great deal to it: Obtain the nearest icosahedral triangle face information, 
    then render arcs around each of the vertices. Obtain the angle of the pixel on
    each arc, then use that to render some repeat moving parts, and that's it.
    
    Of course, I'm glossing over the spherical arc rendering and spherical 
    angles, but that's not as hard as you'd think, and you can find that amongst 
    the code somewhere.
    
    Anyway, this was just a simple demonstration, but as mentioned, I intend to 
    post more interesting examples along these lines later. 

    

	Other examples:
    
	// To my knowledge, the following is the only animated polyhedral weave on 
    // here, which is not surprising, because although looking cool, they're not
    // that fun to make. :) Having made one of these, I can say that the static 
    // non-animated version is simple enough to produce, but including moving parts 
    // can be fiddly work. I'll get around to posting my own one at some stage.
    medusas hairdo with uv - flockaroo
    https://www.shadertoy.com/view/ltBcDw
    
    // In terms of aesthetics and sheer technical ability, this would
    // have to be one of my favorites.
    heavy metal squiggle orb - mattz
    https://www.shadertoy.com/view/wsGfD3
    
    // The flat plane version.
    Animated Triangle Grid Weave - Shane
    https://www.shadertoy.com/view/7sycz3


*/
 

// Max ray distance.
#define FAR 20.

// Color: White: 0, Pinkish Red: 1, Green 2, Blue: 3.
#define COLOR 1

// Two arcs subtended from each spherical triangle vertex. The alternative
// is a single arc.
#define DOUBLE_ARC


// Scene object ID to separate the mesh object from the terrain.
int objID;
vec4 vID;


// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// IQ's vec2 to float hash.
float hash21(vec2 p){  
    return fract(sin(mod(dot(p, vec2(27.609, 57.583)), 6.2831859))*43758.5453); 
}


// IQ's vec3 to float hash.
float hash31(in vec3 p){
    return fract(sin(mod(dot(p, vec3(91.537, 151.761, 72.453)), 6.2831859))*435758.5453);
}


// 3D rotation via two axis rotations. I should probably drop in a
// more concise 3D rotation formula from one of my other examples.
vec3 rotObj(in vec3 p){
   
    p.xz *= rot2(iTime/3./2.);
    p.yz *= rot2(iTime/6./4. + 0.); 
    
    return p;
    
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
// Moving parts direction vectors.
vec3 dir, dir2;

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
    

    // Arc direction vectors. Hacked in at the last minute.
    #ifdef DOUBLE_ARC
    // You'd think this would present the most problems, but double
    // arc directions are easier.
    dir = vec3(1);
    #else
    // For single arcs, directions need to be flipped in two of the
    // latitudinal strips, which is not all that surprising.
    if(id==1 || id==2) dir = vec3(1, -1, 1);
    else dir = vec3(-1, 1, -1);
    #endif
     
    return q;
}


 
// You could get out a pen and paper and figure out the arc distances, or
// if you're lazy like me, you could use Mattz's formula below. :)
//
// By the way, the original example that it comes from is awesome.
// heavy metal squiggle orb - mattz
// https://www.shadertoy.com/view/wsGfD3
//
// Distance from point p to a circle perpendicular to a central vector n 
// and passing through point p0.
//
float pCircDist(vec3 p, vec3 n, vec3 p0) {

    // Projecting "p0" onto "n".
    vec3 c = dot(p0, n)*n;
    
    // Perpendicular distance.
    p -= c, p0 -= c;
    
    p -= normalize(p - dot(p, n)*n)*length(p0);
    
 
    return length(p); 
    
}

// Angle between 3D vectors. Similar to the 2D version. It's easy to derive
// this yourself, or look it up on the internet.
float angle(vec3 p0, vec3 p1){

    return acos(dot(p0, p1)/(length(p0)*length(p1)));
}

// TDHooper's closest icosahedron vertex formula. The original is 
// clever and concise. The original formula is here:
// Closest icosahedron vertices - tdhooper
// https://www.shadertoy.com/view/fdXcDl
//
vec3 icosahedronVertex(inout vec3 p) {

    // TDHooper's function is designed for differently aligned vertices,
    // which I'm guessing are center face aligned along the vertical. Mine 
    // have vertically algined vertex poles, so rather than do rewrite 
    // the function, I've lazily realigned the coordinate system. Not my
    // best work. :D
    
    // Coordinate realignment.
    //const float iAng = acos(dot(vec3(PHI, 1, 0), 
    //                   vec3(0, 1, 0))/length(vec3(PHI, 1, 0)));
    const float iAng = acos(1./length(vec2(PHI, 1)));
    const float cIR = cos(iAng), sIR = sin(iAng);
    const mat2 mIR = mat2(cIR, -sIR, sIR, cIR);
    p.xy = mIR*p.xy;
    
    vec3 ap = abs(p);
    vec3 v = vec3(PHI, 1, 0);
    if (ap.x + ap.z*PHI > dot(ap, v)) v = vec3(1, 0, PHI);
    if (ap.z + ap.y*PHI > dot(ap, v)) v = vec3(0, PHI, 1);
    return v*.52573111*(max(vec3(0), sign(p))*2. - 1.);
}

// Sphere position: A little redundant, in this case.
vec3 sphPos = vec3(0);


// Scene distance function.
float map(vec3 p){
    
    // Back wall.
    //
    // Using a large sphere to create a slightly curved back wall.
    float wall = -(length(p - sphPos - vec3(0, 0, -(48. - 3.))) - 48.);
     // Flat plane back wall.
    //float wall = -p.z + 3.;
    
    // Rotate the sphere.
    vec3 q = rotObj(p - sphPos);

    // Sphere.
    float sph = length(q) - .5;
    
///////////////////////////    

    // Icosahedron vertices for the current cell.
    // Using TDHooper's simple icasahedron vertices
    // formula. "v0" is is the nearest vertex 
    // coordinate for a sphere of radius one.
    vec3 v0 = icosahedronVertex(q); 

    // The ".5" figure is compensating for the sphere's
    // ".05" radius.
    float vert = length(q -  v0*.5) - .02;
  
////////////////////////////////    
 
    // Overall object ID -- There in one rundundant slot there.
    vID = vec4(sph, wall, vert, 1e5);
    
    // Shortest distance.
    return  min(min(sph, wall), vert);
 
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


void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    // Frame blend value for the sphere.
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
        
        // A bright color with grey tones is a design cliche, but cliches are
        // cliches for a reason. :)
        #if COLOR == 0
        const vec3 bCol = vec3(.7); // White.
        #elif COLOR == 1
        const vec3 bCol = vec3(1, .1, .2); // Pink.
        #elif COLOR == 2
        const vec3 bCol = vec3(.45, .85, .15); // Green.
        #else
        const vec3 bCol = vec3(.2, .6, 1.2); // Blue.
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
            vec3[3] v, vertID;
            
            // Obtaining the local cell coordinates and spherical coordinates
            // for the icosahedron cell.
            const float rad = .5;
            vec3 lq = getIcosTri(txP, vertID, rad);
    
            v[0] = sphericalToWorld(vertID[0]);//vec3(0, rad, 0);
            v[1] = sphericalToWorld(vertID[1]);
            v[2] = sphericalToWorld(vertID[2]);
            
             
           
            // Edge mid points, edge tangents and exit and entry points.
            vec3[3] vE, vN;
            vec3[6] vE2;
            
            // Edge mid points.
            vE[0] = normalize(mix(v[0], v[1], .5))*rad;
            vE[1] = normalize(mix(v[1], v[2], .5))*rad;
            vE[2] = normalize(mix(v[2], v[0], .5))*rad;
             
  
            // The cell center, which doubles as a cell ID,
            // due to its uniqueness, which can be used for 
            // randomness, etc.
            vec3 id = normalize((v[0] + v[1] + v[2]))*rad;
             

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
 
          
            #ifdef DOUBLE_ARC
            // Calculating the tangent vectors for each edge, as well as the two
            // entry and exit points on each side of the mid-edge point. All are
            // used to produce the random curves within each triangle cell.
            for(int i = 0; i<3; i++){
                
                // Edge entry points -- One on each side of the mid point.
                float mOffs = .333/2.; // Edge mid point offset.
                vE2[i*2] = normalize(mix(v[i], v[(i + 1)%3], .5 - mOffs))*rad;
                vE2[i*2 + 1] = normalize(mix(v[i], v[(i + 1)%3], .5 + mOffs))*rad; 
                
            } 
            #endif
           
 
            vec3 laneDir = vec3(1);
            // Rendering the spline curves between entry and exit points. There are six
            // alltogether. We're indexing into random indices, and that creates the 
            // randomness, strangely enough. :)
            vec3 ln = vec3(1e5), ln2 = vec3(1e5);
            vec3 angl;
             
            for(int i = 0; i<3; i++){
            
                vec3 v0 = v[(i + 2)%3], v2 = v[(i + 1)%3];
         
                
                // Using Mattz's spherical arc formula to determine the
                // arc distance. It's easy enough to work out, but it's
                // even easier just to use Mattz's formula. :) By the way,
                // the original example that it comes from is awesome.
                //
                // heavy metal squiggle orb - mattz
                // https://www.shadertoy.com/view/wsGfD3
                #ifdef DOUBLE_ARC
                ln[i] = pCircDist(lq, normalize(v0), vE2[((i + 2)%3)*2]); 
                ln[i] = abs(ln[i]); 
                ln2[i] = pCircDist(lq, normalize(v0), vE2[((i + 2)%3)*2 + 1]); 
                ln2[i] = abs(ln2[i]); 
                
                if(ln[i]<ln2[i]) laneDir[i] *= -1.;
                #else
                ln[i] = pCircDist(lq, normalize(v0), vE[((i + 2)%3)]); 
                ln[i] = abs(ln[i]); 
                #endif
                
                // Moving parts.
                //
                // Angle of each pixel on each arc. As above, further calculations
                // are performed outside the loop for speed.
                angl[i] = angle(cross(lq, v0), cross(v2, v0));
  

            }
            
            // Combine the top and bottom arcs and givving them some thickness
            #ifdef DOUBLE_ARC
            // Comining the arcs in order to perform just a single render.
            ln = min(ln, ln2);
            ln -= .04;
            #else
            ln -= .05;
            #endif
            
 

            
            // RENDERING.
            
            
            // Smoothing factor.
            float sf = .003; 
           
            
            // Initial background color.
            texCol = vec3(.05); 

            
            // Cell border lines.
            texCol = mix(texCol, vec3(.2), (1. - smoothstep(0., sf*2., line ))*.35);
            texCol = mix(texCol, vec3(.0), (1. - smoothstep(0., sf, line))*.9);
            
            // Cell vertices.
            vec3 v3 = vec3(length(lq - v[0]), length(lq - v[1]), length(lq - v[2])); 
            float vert = min(min(v3.x, v3.y), v3.z) - .035;
            texCol = mix(texCol, vec3(0), (1. - smoothstep(0., sf*4., vert - .005))*.35);
            texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, vert - .005));
            texCol = mix(texCol, vec3(.1), 1. - smoothstep(0., sf, vert));
            texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, vert + .0075));

            
            // Angular repetition.
            #ifdef DOUBLE_ARC
            // Repeat objects need to be divisible by 5 (due to the five triangles per
            // revolution, or whatever), and maybe 2 also on occasion. If you don't like
            // science, try any set of numbers, and if it works, great. :D
            const float aOuter = 40., aInner = 20.;
            vec3 angNum = vec3(aOuter); 
            // Less repetion along the inner arcs, since the arc length is shorter, which in
            // turn means a smaller circle. Therefore, fewer squares are required to fill out
            // the perimeter of the circle.
            if(laneDir.x<0.){ angNum.x = aInner; };
            if(laneDir.y<0.){ angNum.y = aInner; };
            if(laneDir.z<0.){ angNum.z = aInner; };
            #else
            const float aOuter = 20.; // Only one arc, so only one repetition factor.
            vec3 angNum = vec3(aOuter);        
            #endif

            // Angular ID, for multicolored squares. Not used here.
            //vec3 rpFct = aInner/10.;// Repetition factor and ID (not used).
            //vec3 angID = mod(floor(angl/6.2831*angNum*dir*laneDir + iTime*2.), rpFct)/rpFct;


            // Repeat partitioning the squares along the vertical.
            angl = fract(angl/6.2831*angNum*dir*laneDir + iTime*2.);

            #ifdef DOUBLE_ARC
            // No rounding, but it's there as an option.
            vec3 an2 = vec3(0);//max(ln, cos(angl*6.2831)*.5 + .5);
            // Moving squares.
            angl = (abs(angl - .5)*2. - .85)/aOuter;
            angl = max(angl, ln + .0165*(1. + an2*.2));
            #else
            // Rounding the square edges.
            vec3 an2 = vec3(0);//max(ln, cos(angl*6.2831)*.5 + .5);
            // Moving squares.
            angl = (abs(angl - .5)*2. - .9)/aOuter;
            angl = max(angl, ln + .0165*(1. + an2*.2));
            #endif
            
            // Extra noise.
            //float ns = fBm(txP*256.);
            //texCol *= ns*.5 + .75;
            
            
            // Rendering the arc lines and squares over the top.
            for(int i = min(0, iFrame); i<3; i++){ 
            
                // Arc lines.
                texCol = mix(texCol, vec3(0), (1. - smoothstep(0., sf*8., ln[i] - .01))*.5);
                texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, ln[i] - .0085));
                texCol = mix(texCol, vec3(.1)*1.2, 1. - smoothstep(0., sf, ln[i]));
                
                // Arc line rails.
                texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, abs(ln[i] + .011 - .005) - .0025));
           
                // Squares.
                //
                //vec3 lCol = vec3(1);
                //if(i==1) lCol = bCol;
                //lCol = mod(angID[i], 2.)<.5? bCol : vec3(1);
                vec3 lCol = bCol*1.2;//.5 + .45*sin(6.2831*angID[i] + vec3(0, 1, 2) + 1.);
                float shd = max(.2 - angl[i]/.02, 0.);
                vec3 rCol = vec3(1)*shd;//*(fract(angID[i])*.7 + .6);
                //if(mod(floor(angID[i]*4.), 2.)<.5){ vec3 tmp = lCol; lCol = rCol; rCol = tmp; }
                texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, angl[i]));
                texCol = mix(texCol, rCol, 1. - smoothstep(0., sf, angl[i] + .007));
                texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, angl[i] + .011));
                texCol = mix(texCol, lCol, 1. - smoothstep(0., sf, angl[i] + .018));
                
                
            }
            
    
            
        }
        else if(objID==1){ 
        
            //  Wall.
         
            // Intitial background color.
           
           
            // Rendering an ordered subdivided pattern.
            const vec2 sc = vec2(1./2., 1./4.);
            float sf = .005;
            vec2 p = rot2(3.14159/6.)*sp.xy;
            float iy = floor(p.y/sc.y);
            float rndY = hash21(vec2(iy));
            if(mod(iy, 2.)<.5) p.x += sc.x/2. + iTime/8.*(rndY*.65 + .35);
            else p.x -= iTime/8.*(rndY*.65 + .35);
            vec2 ip = floor(p/sc);
            p -= (ip + .5)*sc;
            
            // I catered for angular subdivision, then decided against
            // it, so this could be tidied up a lot, which I'll do later.
            float a = 0.;//atan(sc.y, sc.x) + 3.14159/9.;
            if(mod(ip.x, 2.)<.5) a += 3.14159/2.;
            if(mod(ip.y, 2.)<.5) a += 3.14159/2.;
            vec2 pR = rot2(-a)*p;
            float tri = pR.y<0.? -1. : 1.;
            ip.x += tri*.5; // Subdivided ID.
            
            // Rectangle distance value.
            p = abs(p) - sc/2.;
            float shp = max(p.x, p.y);
            shp = max(shp, -tri*pR.y);
            
            // Rendering the squares.
            texCol = vec3(.04) + hash21(ip)*.02;
            // Extra noise.
            //float ns = fBm(sp*256.);
            //texCol *= ns*.5 + .75;
            texCol = mix(texCol, texCol*2.5, (1. - smoothstep(0., sf*3.5, abs(shp) - .015)));
            texCol = mix(texCol, vec3(0), (1. - smoothstep(0., sf, abs(shp) - .015))*.9);
            //texCol = mix(texCol, vec3(0), (1. - smoothstep(0., sf, abs(shp + .06) - .005))*.5);
    
            /*
            // Rectangles on random blocks.
            if(abs(ip.y + 2.)>7. && hash21(ip + .11)<.5){
                shp += .045;
                vec3 svCol = texCol;
                float sh = max(.1 - shp/.08, 0.);
                texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, shp));
                texCol = mix(texCol, vec3(sh), 1. - smoothstep(0., sf, shp + .02));
                texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, shp + .04));
                texCol = mix(texCol, bCol*1.2, 1. - smoothstep(0., sf, shp + .06));
            } 
            */

        }
        else {  
            // The icosahedral vertices.
            texCol = bCol;
        }

        
        
        // Debug frame blending region.
        //texCol = mix(texCol, vec3(4, .2, .1), fBlend);
    	
        
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