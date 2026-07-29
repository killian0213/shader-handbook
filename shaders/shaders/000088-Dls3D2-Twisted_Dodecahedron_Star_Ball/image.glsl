// Image (image) — Twisted Dodecahedron Star Ball by Shane
// https://www.shadertoy.com/view/Dls3D2

/*

    Twisted Dodecahedron Star Ball
    ------------------------------
    
    I'm not sure what you'd technically call this, but I've seen it referred
    to as a twisted starball, so I'll call it that. From a geometric perspective,
    it's a rendering of wavy twisted lines eminating from the pentagon face 
    centers of a dodecahedron to each of the five edges.
    
    I've mentioned before that I'd like to post more of the ornate polyhedral 
    objects that the geometric art crowd are fond of. Unfortunately, the lengthy 
    construction procedures don't lend themselves well to the pixelshader
    environment -- due to the fact that we have to construct and render them
    in a fraction of the time that it takes a Blender artist, for instance.
    
    My main objective was to get one of these on the board, rather than write
    it in the most efficient way. Having said that, it seems to run resonably
    well in windowed mode. The compile time is pretty mediocre, so I'll try to 
    get that down later.
    
    The construction procedure was pretty simple: Select the nearest pentagon 
    face, then render curved twisted lines from the centers to the edge midpoints.
    Normally, that would involve 3D Bezier curves, but realtime pixelshader 
    constraints wouldn't allow for that, so I had to get inventive and take a
    warped space approach. Thankfully, it worked. :)
    
    I've noticed that rendering things in spherical space isn't exactly a task 
    that a lot of coders like to undertake, and I understand that, but it's not 
    as bad as people would think. The line algorithms involve more cross products 
    and so forth, but other than that, they're roughly the same.
  
   

	Other examples:
    
    // There aren't a lot of similar examples on here. However TDHooper 
    // was doing this kind of thing before it was cool. :) Unfortunately,
    // due to the style of rendering involved, I had to take a completely
    // different approach.
    Dodecahedron twist  - tdhooper
    https://www.shadertoy.com/view/MlcGRf
    
    // A very stylish, beautifully rendered example. Fast too.
    Sphere Gears - iq
    https://www.shadertoy.com/view/tt2XzG

*/
 

// Max ray distance.
#define FAR 20.

// Twist, or not. A regular star ball has curved lines without
// the twist, which is neater, but not quite as interesting.
#define TWIST

// Curving the spiral arms.
#define CURVE
 

// Scene object ID to separate the mesh object from the terrain.
int objID;
vec4 vID;


// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.609, 57.583)))*43758.5453); }


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


// 3D rotation via two axis rotations. I should probably drop in a
// more concise 3D rotation formula from one of my other examples.
vec3 rotObj(in vec3 p){

    // Mouse movement.
    if(iMouse.z>1.){
        p.yz *= rot2(-(iMouse.y - iResolution.y*.5)/iResolution.y*3.1459);  
        p.xz *= rot2(-(iMouse.x - iResolution.x*.5)/iResolution.x*3.1459);  
    } 

    p.yz *= rot2(iTime/6./4. + 0.);
    p.xz *= rot2(iTime/3./2.);
    return p;
    
}


// IQ's 3D box formular with rounding.
float sBoxS(in vec3 p, in vec3 b, in float rf){
  
  vec3 d = abs(p) - b + rf;
  return min(max(max(d.x, d.y), d.z), 0.) + length(max(d, 0.)) - rf;
    
}

// IQ's 2D box formular with rounding.
float sBoxS(in vec2 p, in vec2 b, in float rf){
  
  vec2 d = abs(p) - b + rf;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - rf;
    
}
 
// Angle between 3D points.
float angle(vec3 v1, vec3 v2){

    return acos(dot(v1, v2)/(length(v1)*length(v2)));
}

 
//////////

/*
// Readjusting the points to the surface of the sphere in question. The function here
// is the same as the one below, but that's not always the case.
vec3 size(in vec3 p, in float rad){

    //return p;
    return normalize(p)*rad;
}
*/
 

/////////
// A concatinated spherical coordinate to world coordinate conversion.
vec3 sphericalToWorld(vec3 sphCoord){
   
    vec4 cs = vec4(cos(sphCoord.xy), sin(sphCoord.xy));
    return vec3(cs.w*cs.x, cs.y, cs.w*cs.z)*sphCoord.z;
}
  

// Useful polyhedron constants. 
//#define PI 3.14159265359
#define TAU 6.283185307179586
#define PI (TAU*.5) // To avoid numerical wrapping problems... Sigh! :)
#define PHI  1.6180339887498948482 // (1. + sqrt(5.))/2.

/*
// A cartesian coordinate to spherical coordinate conversion.
vec3 worldToSpherical(vec3 cartCoord){
    
    float r = length(cartCoord);
    float ax = mod(atan(cartCoord.z, cartCoord.x), TAU); // Longitudinal coordinate.
    float ay = mod(acos(cartCoord.y/r), PI);// Or atan(sphP.y, length(sphP.xz)); // Latitude. 
    return vec3(ax, ay, r);
}
*/

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
 
// Global pentagon center position.
vec3 pentCntr = vec3(0);
// Global pentagon latitudinal block ID.
int pID;

// Returns the local world coordinates to the nearest triangle and the three
// triangle vertices in spherical coordinates.
vec3 getDodecPent(inout vec3 q, inout vec3[5] gVertID, const float rad){


    // The sphere is broken up into two sections. The top section 
    // consists of the top row, and half the triangle in the middle
    // row that sit directly below. The bottom section is the same,
    // but on the bottome and rotated at PI/5 relative to the top. 
    // The half triangle rows perfectly mesh together to form the 
    // middle row or section.

    // Top and bottom section coordinate systems.The bottom section is 
    // rotated by PI/5 about the equator.

 
    // Converting to spherical coordinates.
    // X: Longitudinal angle -- around XZ, in this case.
    // Y: Latitudinal angle -- rotating around XY.
    // Z: The radius, if you need it.

    // Longitudinal angle for the top and bottom sections.
    const float scX = 5.; // Longitudinal scale.
    vec4 sph = mod(atan(q.z, q.x) + vec4(PI/5., PI/5., 0, 0), TAU);
    sph = mod((floor(sph*scX/TAU) + vec4(0, 0, .5, .5))/scX*TAU, TAU);

    // Latitudinal strip positions.
    vec4 pLat = vec4(0, ang, PI - ang, PI);
    
    // Pentagon center.
    //pentCntr = vec3(0);
    
    // Distance to pentagon center.
    float dist = 1e5;
 
    // Latitudinal strip ID.
    int id;

    // Iterating through the four triangle group strips and determining the 
    // closest one via the closest central triangle point.
    for(int i = 0; i<4; i++){
        
        // The spherical coordinates of the central vertex point for each pentagon.
        vec3 sc = vec3(sph[i], pLat[i], rad);
 
        // Spherical to world, or cartesian, coordinates.
        vec3 wc = sphericalToWorld(sc);

        // Nearest pentagon distance.
        float vDist = length(q - wc);
        if(vDist<dist){
           // Update.
           dist = vDist;
           id = i;
           pentCntr = sc;
        }


    }


    float ax = sph[id];

    // The five vertices in spherical coordinates. I can't remember why
    // I didn't convert these to world coordinates prior to returning, but
    // I think it had to do with obtaining accurate IDs... or something. :)
   
    vec3 vLat = vec3(cAng, 2.*mAng - cAng, PI - (2.*mAng - cAng));
    if(id==0 || id ==3){
        
        // Top and bottom pentagons.
        float xOff = PI/5.;
        if(id==3){ vLat = PI - vLat; xOff = 0.; }

        gVertID[0] = vec3(xOff, vLat.x, rad);
        gVertID[1] = vec3(2.*PI/5. + xOff, vLat.x, rad);
        gVertID[2] = vec3(4.*PI/5. + xOff, vLat.x, rad);
        gVertID[3] = vec3(6.*PI/5. + xOff, vLat.x, rad);
        gVertID[4] = vec3(8.*PI/5. + xOff, vLat.x, rad); 
    
    
    }
    else{ 
        
        // Middle latitudinal strip pentagons.
        if(id==2){ vLat = PI - vLat; }
        
        vec3 ax3 = mod(vec3(ax + TAU - PI/5., ax + PI/5., ax), TAU);

        // Clockwise.
        gVertID[0] = vec3(ax3.x, vLat.y, rad);
        gVertID[1] = vec3(ax3.x, vLat.x, rad);
        gVertID[2] = vec3(ax3.y, vLat.x, rad);
        gVertID[3] = vec3(ax3.y, vLat.y, rad);
        gVertID[4] = vec3(ax3.z, vLat.z, rad);
    }
    

 
   
    // Top and bottom poles have a longitudinal coordinate of zero.
    if (id==0 || id==3) pentCntr.x = 0.;
    
    // Debug.
    //cID = int(floor(ax/TAU*5.));
    
    /*
    // Not needed here.
    dir = vec3(1);
    if(id == 1 || id == 2) dir *= -1.;
    if(id == 0 || id == 2) dir.x *= -1.;
    */
    
    // Global pentagon latitudinal block ID.
    pID = id;
    
    
    return q;
}
///////////////////
 
// A signed spherical line running between points "a" and "b"
// (capped at "b"). I wrote it and appended a wave to it in a hurry,
// but it seems to work.
float sphereLineDistCapBWave(vec3 p, vec3 a, vec3 b, float ang){ 
     
     //float ld = length(a - b);
     //float lp = length(p);
     
     p = normalize(p); // Normalize p. // p /= rad; 
     float ln = dot(p, cross(a, b))/length(a - b);
     
     // Perpendicular vector running through point "b".
     vec3 perpB = normalize(b + cross((a - b), b))*.5;
     // Capping the line off at point "b".
     float endB = dot(p, cross(perpB, b))/length(perpB - b);
     
     #ifdef CURVE
     // Using the perpendicular vector to add a sinusoidal wave to the line.
     //ln -= sin(6.2831/ld*.25*.975*(ang))*.06;//(endB)*.95//*.975
     ln -= sin(6.2831*2.*(endB) + 0.125)*.06;//(endB)*.95//*.975
     //ln -= sin(6.2831*1.905*(endB))*.06;//(endB)*.95//*.975
     #endif
 
     // Return the signed distance. 
     return sign(ln)*max(abs(ln), endB);      
}

// Sphere position: A little redundant, in this case.
vec3 sphPos = vec3(0);

// Scene distance function.
float map(vec3 p){
    
     // Rotate the sphere.
    vec3 q = rotObj(p - sphPos);
    
    // Back wall.
    //
    // Using a large sphere to create a slightly curved back wall.
    //float wall = -(length(p - sphPos - vec3(0, 0, -(16. - 3.))) - 16.);
     // Adding subtle perturbation to the plane.
    p.z -= dot(sin(p.xy*1. - cos(p.yx*2.)), vec2(.05));
    float wall = -p.z + 3.;
    
    
////////////////    
 
    // Dodecahedron vertices and vertex IDs for the current cell.
    vec3[5] vP, vPID;

    // Obtaining the local cell coordinates and spherical coordinates
    // for the dodecahedron cell.
    const float rad = .5;
    vec3 lq = getDodecPent(q, vPID, rad);


    // World vertex coordinates.
    for(int i = 0; i<5; i++){
        vP[i] = sphericalToWorld(vPID[i]);//vec3(0, rad, 0);
    }


    // Pentagon center cartesian coordinates.
    vec3 vPCntr = sphericalToWorld(pentCntr);

    
    // Central curve and trimming curve.
    float crv = 1e5, crv2 = 1e5;

    
    //float pDir = ((pID&1)==0)? 1. : -1.;
    
    
    // The pentagon spiral consists of five curved lines connecting the
    // center to the pentagon edges.
    for(int i = min(0, iFrame); i<5; i++){ 
    
        int ip1 = (i + 1)%5;

        // Mid pentagon edge point.
        vec3 vMid1 = normalize(mix(vP[i], vP[ip1], .5))*rad; 
        // Angle between the current point and the pentagon center.
        float angR = angle(lq, vPCntr);
        //float angR = length(lq - vPCntr)/length(vMid1 - vPCntr);         

        // Sphere line between the mide edge point and the pentagon center.
        // The formula has been modified to give it a sinusoidal wave.
        float line = sphereLineDistCapBWave(lq, vMid1, vPCntr, angR);

        // 2D box coordinates (The line and the Z direction).
        vec2 lv = vec2(line, (length(lq) - .5));

       
        #ifdef TWIST
        // Twisting (rotating) the box coordinates a quarter turn from the center to
        // the mid point. How you do this is up to you. The way I've done it is not
        // pefect, but it's close enough. I'll put more effort into it later.
        lv = rot2(smoothstep(.25, 1., angR/cAng*1.15)*3.14159/4.)*lv;
        //lv = rot2(smoothstep(.05, .95, length(lq - vPCntr)/length(vMid1 - vPCntr))*3.14159/4.)*lv;
        //lv = rot2(smoothstep(.05, 1., angR*1.)*3.14159/4.)*lv;
        //lv = rot2(clamp(angR*2.65 - .4, .0, 1.)*3.14159/4.)*lv;
        #endif

        /*
        // Failed experiment with repeat boxes... I'll try again later. :)
        float z = normalize(cross(vec3(lv.x, 0, 0), vec3(0, lv.y, 0))).z;
        z = mod(angR*cAng/6.2831*8. + .25/8., 1./8.) - .5/8.;
        float bx = sBoxS(vec3(lv, z), vec3(.04), .01);
        */
        
        // Cross sectional 2D box object.
        float bx = sBoxS(lv, vec2(.04), .0);
        //float bx = max(abs(lv.x), abs(lv.y)) - .04;
        //bx += sin(angR*cAng*256. + 3.14159)*.0003; // Ribbing.
        //bx = max(ln2, abs(z) - .2/8.);
        
        // Putting on some trimming.
        float sdBox = length(abs(lv) - .045) - .0085;//max(abs(lv.x), abs(lv.y));//
        //sdBox += clamp(sin(angR*cAng*128. + 3.14159)*3., 0., 1.)*.002;
        sdBox += sin(angR*cAng*256. + 3.14159)*.0005; // Beading.
 
        crv = min(crv, bx);
        crv2 = min(crv2, sdBox);
 
 
            
    }
         
    // Hastily written background line trimming. 
    float sc = .45;      
    vec3 qq = p - vec3(0, 0, 3. - .02);
    qq.xy *= rot2(-3.14159/5.);
    qq.xy += sin(qq.xy*1. - cos(qq.yx*2.))*.05;
    qq.y = mod(qq.y, sc) - sc/2.;
    //
    float bgLn = length(qq.yz) - .03;
    bgLn += sin(6.2831*qq.x*16.)*.002; // Beading.
    
    // Appending the background line trimming.  
    crv2 = min(crv2, bgLn);
 
    // Central pentagon spheres.
    float sph = length(lq - vPCntr*1.115) - .0325;
     


 
    // Overall object ID -- There are two rundundant slots there.
    vID = vec4(sph, wall, crv, crv2);
    
    // Shortest distance.
    return  min(min(sph, wall), min(crv, crv2));
 
}

 
// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    // Overall ray distance and scene distance.
    float t = 0., d;
    
    for(int i = min(iFrame, 0); i<96; i++){
    
        d = map(ro + rd*t);
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, as
        // "t" increases. It's a cheap trick that works in most situations... Not all, though.
        if(abs(d)<.001 || t>FAR) break; // Alternative: 0.001*max(t*.25, 1.), etc.

        t += d*.75; 
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
        //if(occ>1e5) break;
    }
    
    return clamp(1. - occ, 0., 1.);  
    
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    float fBlend = 0.;
    
    // Screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
	
	// Camera Setup.
	vec3 lk = vec3(0, 0, 0); // Camera position, doubling as the ray origin.
	vec3 ro = lk + vec3(cos(iTime/3.)*.1, .1, -2);//vec3(0, -.25, iTime);  // "Look At" position.
 
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
    
    
    // Object identification: For two objects only, this is overkill,
    // but handy when using more.
    objID = 0;
    float obD = vID[0];
    for(int i = 0; i<4; i++){ 
        if(vID[i]<obD){ obD = vID[i]; objID = i; }
    }
    
    //float svMetal = gMetal;
    
	
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

        // Object patterns, coloring, etc.        
        if(objID==0){ 
        
            // Central spheres.
            texCol = mix(vec3(1, .3, .1), vec3(1, .1, .2), abs(sn.y)*.5 + .25);
            texCol = max((sn.xzy)*.35 + .65, .1)*texCol*1.2;
           
            // Texture position and normal.
            vec3 txP = sp - sphPos;
            vec3 txN = sn;

            // Rotation to match the scene movement.
            txP = rotObj(txP);
            txN = rotObj(txN);
            vec3 tx = tex3D(iChannel1, txP, txN);
            texCol *= tx*2.; 
    
           
        }
        else if(objID==1){ 
        
            //  Wall.

            // Intial background color.
            texCol = mix(vec3(1, .5, .25), vec3(.175), .9);       
            
            // Coloring alternate strips.
            float sc = .45;      
            vec3 qq = sp;// - vec3(0, 0, 3. - .035);
            qq.xy *= rot2(-3.14159/5.);
            qq.xy += sin(qq.xy*1. - cos(qq.yx*2.))*.05;
            float idy = floor(qq.y/sc + .5);
            qq.y -= (idy + .5)*sc;//mod(qq.y, sc) - sc/2.;
            if(mod(idy, 2.)<.5) texCol = mix(vec3(1, .5, .25), vec3(.175), .825);

            // Applying texture.
            vec3 tx = texture(iChannel1, sp.xy/3. + .5).xyz; tx *= tx;
            texCol *= (tx + .75)*.9;
            
   
            
        }
        else { 
        
            // Star ball and trim color.

            // Main star ball color.
            texCol = mix(vec3(1, .3, .1), vec3(1, .1, .2), abs(sn.y)*.5 + .25);
             
            // Trimming.
            if(objID==3){
                 //All trimming.
                 texCol = max((sn.xzy)*.35 + .65, .1)*texCol*1.2;
                 // Star ball trimming.
                 if(sp.z<2.5){
                    diff *= sqrt(diff);
                    texCol = mix(mix(texCol, vec3(1, .5, .25)/2., .8), 
                                 vec3(1)*dot(texCol, vec3(.299, .587, .114)), .2); 
                } 
        
            }
            
            
            if(sp.z>2.5){ 
            
                // Back wall tubing metal.
                vec3 tx = tex3D(iChannel1, sp/3. + .5, sn);
                texCol = mix(vec3(1, .5, .25)/2., vec3(1)*dot(texCol, vec3(.299, .587, .114)), .65)*.5; 
                texCol *= (tx + .75)*.9;
            }
            else {
                
                // Star ball texturing.
                
                // Texture position and normal.
                vec3 txP = sp - sphPos;
                vec3 txN = sn;

                // Rotation to match the scene movement.
                txP = rotObj(txP);
                txN = rotObj(txN);
                vec3 tx = tex3D(iChannel1, txP, txN);
                //tx = smoothstep(.0, .5, tx);
                texCol *= tx*2.;// + .1;
            
            }
            
            
           
            
            
        }
        
         
        // Specular reflection.
        float speR = pow(max(dot(normalize(ld - rd), sn), 0.), 8.);
        vec3 rf = reflect(rd, sn); // Surface reflection.
        vec3 rTx = texture(iChannel0, rf).xyz; rTx *= rTx;
        float spF = objID == 2? 2. : 3.;
        if(objID!=1) texCol += (texCol*.9 + .1)*speR*rTx*spF;
        
    	
        
        // Combining the above terms to procude the final color.
        col = texCol*(diff*sh + .15 + vec3(1, .9, .7)*spec*freS*sh*8. + vec3(.2, .4, 1)*fre*sh*0.);
 


        // Shading.
        col *= ao*atten;
        
       
	
	}
    
    // Background fog.
    //col = mix(col, vec3(0), smoothstep(0., .99, t/FAR));


    // No temporal blur, for comparison.
    fragColor = vec4(sqrt(max(col, 0.)), 1);
	
}