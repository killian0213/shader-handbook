// Buffer A (buffer) — Icosahedron Triangle Pattern by Shane
// https://www.shadertoy.com/view/cllGzr

/*

    Icosahedron Triangle Pattern
    ----------------------------
    
    Applying a common spiral pattern to the triangle cells of a subdivided 
    icosahedron. Attaching a suitable grid to a sphere, then rendering a 
    pattern into the cells is not what I'd call a common excercise amongst
    the graphics crowd, but there are still plenty of examples out there. 
    There are examples on Shadertoy too, but far fewer than I would have 
    expected.
    
    I can understand why, since rendering to surfaces other than a plane 
    might seem a little daunting at first. However, the process is exactly 
    the same; You're simply rendering objects to a surface using familiar 
    rendering calls that involve line and shape distances, etc. For example, 
    a line between point A and B is just that, regardless of the surface 
    involved. Three line distance calls between triangle vertices will 
    result in a triangle, etc. Partitioning space into some kind of grid
    is a little different in the sense that a plane is flat and goes on 
    forever, whereas a sphere is curved and wraps around on itself, but the 
    process still involves obtaining local cell coordinates, cell vertices, 
    etc, then using them to place objects within the cell.
    
    Writing spherical lines, spherical partitioning algorithms, etc, can be 
    simple or painful, but once they're done, you simply have to use them 
    however you see fit. The possibilities are endless.
    
    Admittedly, there's probably a little too much information in this 
    particular shader to sift through. However, if you're new to this and 
    would like to make a start, begin with rendering some line borders and 
    vertex points to the square or triangle cells of a sphere, then take 
    it from there.
    
    Anyway, as mentioned, this is just one of countless spherical grid 
    patterns possible. I'll post a few more in due course.   

    

	Related examples:

    
    // A really nice triangle spiral feedback example. It takes a little 
    // while to build up to the good stuff, but it's worth it. :) 
    [phreax] creation process - phreax
    https://www.shadertoy.com/view/Dd2SWV
    
    // Looking at this example reminded me that I had several spiral
    // polygon examples that I hadn't bothered finishing, so I finished
    // one. :)
    Nest of Polygons II - mla
    https://www.shadertoy.com/view/cs2XWy
    
    // TDHooper's examples are all really popular. This one is 
    // simply, but elegantly rendered. 
    Icosahedron twist - tdhooper
    https://www.shadertoy.com/view/Mtc3RX
    
    
*/
 

// Max ray distance.
#define FAR 20.


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

// IQ's vec3 to float hash.
float hash31(in vec3 p){
    return fract(sin(dot(p, vec3(91.537, 151.761, 72.453)))*435758.5453);
}



// 3D rotation via two axis rotations. I should probably drop in a
// more concise 3D rotation formula from one of my other examples.
vec3 rotObj(in vec3 p){

    p.xy *= rot2(-3.14159/12.);
    p.xz *= rot2(-iTime/8.); 

    return p;
    
}

// Sphere position: A little redundant, in this case.
vec3 sphPos = vec3(0);

vec3 gVal;

// Scene distance function.
float map(vec3 p){
    
    // Back wall.
    //
    // Flat plane back wall.
    float wall = -p.z + 2.5;// - (length(p) - .5)*.1;
    

    // Perturbing the back wall with some cheap sinusoidal layers. You could leave the 
    // wall flat, but this will reflect light in a more interesting way.
    vec3 pp = p*2. + vec3(0, 0, iTime/2.);
    float pOffs = dot((sin(pp - cos(pp.yzx*2.2/2.4)*1.57)), vec3(.1));
    pOffs = mix(pOffs, dot((sin(pp*2. - cos(pp.yzx*2.2/2.4*2.)*1.57)), vec3(.1)), .333);
    wall -= pOffs;
    
    // Rotate the sphere.
    vec3 qq = rotObj(p - sphPos);

    // Sphere.
    float sph = length(qq) - .5;
    
 
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
	
    //const vec2 e = vec2(.001, 0);
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
        //if(occ>1e5) break;
    }
    
    return clamp(1. - occ, 0., 1.);  
    
} 
 

/////////
// A concatinated spherical coordinate to world coordinate conversion.
vec3 sphericalToWorld(vec3 sphCoord){
   
    vec4 cs = vec4(cos(sphCoord.xy), sin(sphCoord.xy));
    return vec3(cs.w*cs.x, cs.y, cs.w*cs.z)*sphCoord.z;
}
  

// Useful polyhedron constants. 
//#define PI 3.14159265359
#define TAU 6.283185307179586
#define PI TAU*.5 // To avoid numerical wrapping problems... Sigh! :)
#define PHI  1.6180339887498948482// (1. + sqrt(5.))/2.

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
// Direction vector.
vec3 dir;
//int sID, cID;

// Returns the local world coordinates to the nearest triangle and the three
// triangle vertices in spherical coordinates.
vec3 getIcosTri(inout vec3 p, inout mat3x3 gVertID, const float rad){
       
 
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
/*    
    cID = int(floor(ax/TAU*5.));
    
    dir = vec3(1);
    if(id == 1 || id == 2) dir *= -1.;
    if(id == 0 || id == 2) dir.x *= -1.;
    
    sID = id;
*/    
    
    return q;
}

 
/*
// Sphere line distance between A and B.
float sphereLineCapABDist(vec3 p, vec3 a, vec3 b, float rad){
     
     p = normalize(p); // Normalize p.
     float ln = dot(p, cross(a, b))/length(a - b);
     
     vec3 perpA = a + cross(b - a, a);
     vec3 perpB = b + cross(a - b, b);
     float endA = dot(p, cross(perpA, a))/length(perpA - a);
     float endB = dot(p, cross(perpB, b))/length(perpB - b);
     
     
     return max(max(ln, endA), endB);
      
}
*/

// Sphere line distance.
float sphereLineDist(vec3 p, vec3 a, vec3 b, float rad){
     
     p = normalize(p); // Normalize p. // Set radius: p /= rad; 
     return dot(p, cross(a, b))/length(a - b);

}

//////////



void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    float fBlend = 0.;
    
    // Screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
	
	// Camera Setup.
	vec3 lk = vec3(0, 0, 0); // Camera position, doubling as the ray origin.
	vec3 ro = lk + vec3(cos(iTime/3.)*.1, .25, -1.85);//vec3(0, -.25, iTime);  // "Look At" position.
 
    // Light positioning. One is just in front of the camera, and the other is in front of that.
 	vec3 lp = ro + vec3(.25, .5, 0);// Put it a bit in front of the camera.
	

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
    
    //rd = normalize(vec3(rd.xy, sqrt(max(rd.z*rd.z - dot(rd.xy, rd.xy)*.25, 0.))));
    
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
    
    vec3 svVal = gVal;
    
	
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
	    float spec = pow(max(dot(reflect(ld, sn), rd ), 0.), 12.); 
	    
	    // Fresnel term. Good for giving a surface a bit of a reflective glow.
        float fre = pow(clamp(1. + dot(sn, rd), 0., 1.), 2.);
        
        
		// Schlick approximation. I use it to tone down the specular term. It's pretty subtle,
        // so could almost be aproximated by a constant, but I prefer it. Here, it's being
        // used to give a hard clay consistency... It "kind of" works.
		float Schlick = pow( 1. - max(dot(rd, normalize(rd + ld)), 0.), 5.);
		float freS = mix(.2, 1., Schlick);  //F0 = .2 - Glass... or close enough.        
        
          
        // Texel color. 
	    vec3 texCol = vec3(0); 
        
        
        // Frame blending hack to mitigate alliasing on the sphere edges.
        fBlend = 1. - smoothstep(-.2, .2, abs(dot(rd, sn)) - .2);
        


        // Object patterns, coloring, etc.        
        if(objID==0){ 
        
            // The sphere.
            
             // Smoothing factor.
            float sf = .003; 
            
            // Texture position and normal.
            vec3 txP = sp - sphPos;
            vec3 txN = sn;
            
            // Rotation to match the scene movement.
            txP = rotObj(txP);
            txN = rotObj(txN);
             
            
            // Icosahedron vertices and vertex IDs for the current cell.
            mat3x3 v, vID;
            
            // Obtaining the local cell coordinates and spherical coordinates
            // for the icosahedron cell.
            const float rad = .5;
            vec3 lq = getIcosTri(txP, vID, rad);
    
            v[0] = sphericalToWorld(vID[0]);//vec3(0, rad, 0);
            v[1] = sphericalToWorld(vID[1]);
            v[2] = sphericalToWorld(vID[2]);
            
            
            
            // Edge mid points, edge tangents and exit and entry points.
            mat3x3 vE;
             
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
            
            mat3x3 VNgbr2;
            
            float midTri = 0.;
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
                    //dir = -dir;
                }
                else if(dot(lq, cross(vE[1], vE[2]))>0.){
                    v[0] = vE[2]; v[1] = vE[1];
                }
                else if(dot(lq, cross(vE[2], vE[0]))>0.){
                    v[1] = vE[0]; v[2] = vE[2];
                }
                else {
                
                    // Neighboring v2 point is the original point.
                    VNgbr2 = v;
                    
                    v[0] = vE[2]; v[1] = vE[0]; v[2] = vE[1];
                     //if(i==1){
                    // if(sID%2==1) dir = -dir;
                    // else dir *= vec3(1, -1, 1);
                     //}
                     midTri = 1.;
                     
                     
                }
               
                // Recalculating the edge mid-vectors for the next iteration.
                vE[0] = normalize(mix(v[0], v[1], .5))*rad;
                vE[1] = normalize(mix(v[1], v[2], .5))*rad;
                vE[2] = normalize(mix(v[2], v[0], .5))*rad;
                
                
            }
            #endif
            /////  
            
           
            
  
            // The unique cell ID, which is used for randomness, etc.
            vec3 id = v[0] + v[1] + v[2];
            // The cell center, which doubles as a cell ID,
            // due to its uniqueness.
            vec3 ctr = normalize(id)*rad;
            
             
            // Rendering the triangle spirals... The rushed logic needs some tidying up,
            // but it works, so it'll do. You could almost ignore my approach and devise 
            // your own one. I've taken a brute force approach because I wanted an 
            // accumulated shadow effect, but a polar coordinate method would be faster. 
            mat3x3 pp, vv = v;
            float per = 0.; 
            #if SCHEME == 0
            const int N = 24; // More triangles, if there is no subdivision.
            #else
            const int N = 12; // Fewer triangles for smaller subdivided cells.
            #endif
            const float fN = float(N);
            float lf = 1./fN;
            
            // Render a few layered spiraling triangles.
            for(int j = 0; j<N; j++){//3
                
                
                // The vertices. They're contracted and rotated each iteration.
                pp[0] = mix(vv[0], vv[1], per);
                pp[1] = mix(vv[1], vv[2], per);
                pp[2] = mix(vv[2], vv[0], per); 
                
                // Three line distances between vertices, which, not surprisingly,
                // combine to form a triangle.
                float pLn = sphereLineDist(lq, pp[0], pp[1], rad);
                pLn = max(pLn, sphereLineDist(lq, pp[1], pp[2], rad));
                pLn = max(pLn, sphereLineDist(lq, pp[2], pp[0], rad));
                
                // Triangle shade. It gets brighter each iteration, but you
                // can do whatever you want.
                float sh = pow(float(j)/(fN - 1.), 1.5)*.975 + .025;
                
                // Triangle color.
                vec3 tCol = vec3(min(sh*2.5, 1.));
                //vec3 tCol = (.5 + .45*cos(6.2831*sqrt(sh)/1. + vec3(0, 1, 2))); // Colors.
                
                // The colored moving triangle.
                float rndJ = mod(floor(iTime*7. + hash31(ctr+.08)*(fN*3.)), fN*3. - 1.) + 1.;
                if(j == int(rndJ)) tCol = (tCol*.5 + .5)*vec3(3, .6, .4)*2.;//vec3(.8, 1, .3);
                
                tCol = mix(tCol, tCol.xzy, -sn.x);
                
                // Darkening the central triangle.
                if(j==N-1){
                    tCol = vec3(.15);
                    texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, pLn + .015));
                }
                
                
                //tCol = vec3(.35); // Debug.
                
                // Shadow facotr, line width and transparency.
                #if SCHEME < 2
                const float shF = 12.;
                const float lw = .005;
                const float alpha = .35;
                #else
                const float shF = 6.;
                const float lw = .004;
                const float alpha = .25;
                #endif
                
                // Rendering the triangle layers.
                texCol = mix(texCol, vec3(0), (1. - smoothstep(0., sf*shF, pLn))*alpha);
                texCol = mix(texCol, tCol*.05, 1. - smoothstep(0., sf, pLn));
                texCol = mix(texCol, tCol, 1. - smoothstep(0., sf, pLn + lw));

                
                //if(j==N-1) texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, pLn + .01));
                 
                // Edge contraction distance factor.
                lf *= 1.125;//1.125/*(cos(iTime/1.)*.25 + 1.);
                
                // Set the new vertices to the adusted values.
                vv = pp;
                
                // Edge contraction.
                per = lf;
                //per = lf*(cos(iTime/2.)*.5 + .75);
                //per = lf*.55;
            }
            
 
            
            // Cell vertices.
            vec3 v3 = vec3(length(lq - v[0]), length(lq - v[1]), length(lq - v[2])); 
            float vert = min(min(v3.x, v3.y), v3.z) - .012;
            texCol = mix(texCol, vec3(0), (1. - smoothstep(0., sf*4., vert - .005))*.35);
            texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, vert - .005));
            texCol = mix(texCol, vec3(.1), 1. - smoothstep(0., sf, vert));
            texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, vert + .007));
            
            // Extra global coloring.
            texCol *= vec3(.85, 1, 1.1); // Blueish tinge.
 
            
        }
        else if(objID==1){ 
        
            //  Back wall.
 
            
            // Texture coordinates.
            vec3 txP = sp;
            txP.xy = rot2(3.14159/12.)*txP.xy + vec2(iTime/8., 0.);
            
            // Cell coordinate, ID and triangle orientation id.
            // Cell vertices and vertex ID.
            mat3x2 v, vID;

            // Returns the local coordinates (centered on zero), cellID, the 
            // triangle vertex ID and relative coordinates.
            vec4 p4 = getTriVerts(txP.xy, vID, v);
            vec2 p = p4.xy;
            vec2 id = p4.zw;
            float tri = gTri;
            vec2 triID = id + (vID[0] + vID[1] + vID[2])/3.;
            
            
            // Smoothing factor.
            float sf = .003*2.;
            const float ew = .01;
           
            
            // Nearest vertex ID.
            float vert = 1e5;
            //
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
            vec2 q = tri<.5? p*vec2(1, -1) : p;
             
            // Triangle.
            float tr = getTri(q, scale*.57735);
            
            // Triangle shade and color.
            float sh = pow(floor(hash21(p4.zw + .1)*11.999)/11., 1.5)*.025 + .025;
            vec3 tCol = vec3(sh)*vec3(.9, 1, 1.1); 
            vec3 eCol = tCol;
           
            // Intial background triangle color.
            texCol = vec3(0);
            
            // Triangle rendering.
            #if 1
            texCol = mix(texCol, tCol, (1. - smoothstep(0., sf, tr + ew)));
            #else
            texCol = mix(texCol, eCol*1.25, (1. - smoothstep(0., sf, tr + ew)));
            texCol = mix(texCol, vec3(0), (1. - smoothstep(0., sf, tr + .02 + ew)));
            texCol = mix(texCol, tCol, (1. - smoothstep(0., sf, tr + .02 + ew*2.)));
            #endif
             

            // Vertex coloring.
            vec3 vCol = vec3(hash21(vertID + .1)*.075 + .025);
            vCol *= vec3(.9, 1, 1.1);
             
            // Blinking glowing vertices.
            vec3 lCol2 = (vCol*.5 + .5)*vec3(3, .6, .4)/2.;//vec3(.8, 1, .3);
            lCol2 = mix(lCol2, lCol2.xzy, -sp.x/2.);
            float glow = smoothstep(.97, .99, sin(6.2831*hash21(vertID + .2) + iTime/4.));
            vCol = mix(vCol, lCol2, glow);    
            
            // Vertex rendering.
            float vw = .04;
            vert -= vw;
            texCol = mix(texCol, vec3(0), (1. - smoothstep(0., sf*4., vert))*.35);
            texCol = mix(texCol, texCol + vCol, (1. - smoothstep(0., sf*8., vert))*.05);
            texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, vert));
            texCol = mix(texCol, vCol, 1. - smoothstep(0., sf, vert + .01));
            texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, vert + vw - .01));
            
            // Adding some extra global coloring.
            texCol *= vec3(.9, 1, 1.1)*vec3(.85, 1, 1.1);
  
        }

      
        //texCol *= vec3(.8, 1.2, 2.75); // More blue.
        
        
        // Debug frame blending region.
        //texCol = mix(texCol, vec3(4, .2, .1), fBlend);
        
        // Specular reflection.
        vec3 hv = normalize(ld - rd); // Half vector.
        vec3 ref = reflect(rd, sn); // Surface reflection.
        if(objID==0) ref.xz = rot2(-iTime/3./2.)*ref.xz;
        vec3 refTx = texture(iChannel1, ref).xyz; refTx *= refTx;
        refTx = (texCol*1.5 + .66)*refTx;//smoothstep(.2, .5, refTx);
        float spRef = pow(max(dot(hv, sn), 0.), 8.); // Specular reflection.
        float rf = objID == 1? .5 : 1.;
        //
        // Adding the specular reflection and glow for the inner light.
        texCol += texCol*spRef*mix(refTx, refTx.zyx, rd.y*0.)*rf*4.;
    	
        
        // Combining the above terms to procude the final color.
        col = texCol*(diff*sh + .3 + vec3(1, .8, .5)*spec*freS*sh*16. + vec3(.2, .4, 1)*fre*sh*0.);
 
        // Ambient occlusion and light attenuation.
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