// Image (image) — Marching Die by Shane
// https://www.shadertoy.com/view/3sVBDd

/*

	Marching Die
	------------
    
    I've had this scene sitting in my account for way too long, so thought I'd 
    put it up. I did it just for fun and to relieve boredom. At the time, I 
    thought it'd be cool to see what a standard infinite 2D hexagonal grid filled 
    with cubes would look like in 3D. Once I'd satisfied my curiosity, I figured 
    I'd randomly move a cube about the resultant surface for a bit of visual 
    interest and depth.
    
    All of that was simple enough, but texturing a moving animated die correctly
    proved to be a little tricky. I got there in the end, but I might try to come 
    up with a better system next time.
    
    In order to move and texture the die correctly, I hardcoded 15 steps that 
    looped around to the surface die just in front of the original position, which 
    was necessary to keep up with a moving camera synchronized to meet it there. 
    The steps were simple enough: Pivot up and forward about the YZ axis, pivot 
    down and left about the XY axis, etc. Whilst doing this, it was necessary to 
    keep track of the pivot points, fractional rotation matrix, overall position, 
    overall rotation, etc, in order to obtain the correct texture. Texturing was 
    achieved via standard cube mapping -- Render one dot on face one, two dots on 
    face two, etc. I was able to fake randomness by changing the original looped 
    path slightly each time around, or something to that effect.
    
    I'm giving the performance a "mildly OK" rating. On machines like mine, it'll 
    run fine in the 800 by 450 window, but fullscreen will be slow. At some stage,
    I'll get in amongst it and improve a few things. I'm also going to post my
    original shader that doesn't have rounded stacked dice, reflections, etc, so
    that will be much faster.
 
    
   
    Other examples:

	// Quite watchable: Dave Hoskins was coding stacked cubes before it was cool. :D 
    Ray*Bert - Dave_Hoskins 
	https://www.shadertoy.com/view/4sl3RH
    
    // I really like this one. It'd be cool to see a fancier version at some stage.
    hexastairs: ladder like + doors - FabriceNeyret2
    https://www.shadertoy.com/view/wsyBDm
    
    // Here's another related example of Fabrice's. I like the way he's worked
    // the camera.
    rolling dice on surface - FabriceNeyret2 
    https://www.shadertoy.com/view/WdGBRc
 

*/

// Bouncing the die from level to level... It works but needs a little fine tuning.
//#define BOUNCE

// Ray passes: For this example, just one intersection and one reflection.
#define PASSES 2

// Far plane, or max ray distance.
#define FAR 40.

// Minimum surface distance. Used in various calculations.
#define DELTA .001

// Global block scale.
#define GSCALE vec2(1./1.5)


#define PI 3.14159
// A swap without the extra declaration, but involves extra operations -- 
// It works fine on my machine, but if it causes trouble, let me know. :)
#define swap(a, b){ a = a + b; b = a - b; a = a - b; }

// Scene object ID to separate the mesh object from the terrain.
int objID, svObjID;

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.609, 57.583)))*43758.5453); }


// Commutative smooth maximum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smax(float a, float b, float k){
    
   float f = max(0., 1. - abs(b - a)/k);
   return max(a, b) + k*.25*f*f;
}


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



// IQ's signed box formula.
float sBox(in vec2 p, in vec2 b, in float sf){

  p = abs(p) - b + sf;
  return length(max(p, 0.)) + min(max(p.x, p.y), 0.) - sf;
}

// IQ's signed box formula.
float sBox(in vec3 p, in vec3 b, in float sf){

  p = abs(p) - b + sf;
  return length(max(p, 0.)) + min(max(max(p.x, p.y), p.z), 0.) - sf;
  
  // Unsigned.
  //return length(max(abs(p) - b + sf, 0.)) - sf;
}


// Exponential easing function.
float exponentialOut(float t) {
  return t == 1. ? t : 1. - pow(2., -8.*t);
}

// Quad easing function. 
float easeOutQuad(float t) {
    return -t*(t - 2.);
}
 
 
// Various moving die storage containers. I added these as I went
// along, so it definitiely needs a tidy up.

// Cube distance and ID.
vec3 svGID; 

// Die rotation storage matrices.
mat2 gMat, svMat;
mat2 lRot;

// Texture pivot and offset matrices for the moving die.
vec3 gTxP, svTxP;
vec3 gPiv, svPiv;
vec3 gOff;

// Pivot total direction and direction storage.
vec3 lPivot;
vec3 lTotDist;
vec3 dirI;
// XY and YZ direction start positions.
float lStartXY;
float lStartYZ;
// Bounce value.
float gBounce = 0.;


// Moving the cube whilst keeping track of pivot, offset, etc, variables
// for texturing purposes. This is a long and ugly function, but thankfully,
// it's only called once per frame.
void moveCube(float gTime){

   
    const int ttm = 15;
    float tm = gTime*float(ttm)/GSCALE.x; 
    
    float modtm = mod(tm, float(ttm));
 
    // Initial die offset -- Arrange to match the camera movement.
    gOff = ((vec3(5, 4, -4) - 1./2.) + floor(tm/float(ttm))*vec3(0, 1, 1))*GSCALE.x;
 
    lStartYZ = mod(floor(tm/float(ttm)), 2.);

    // Directions -- All 15 of them.
    vec3[ttm] dir = vec3[ttm](vec3(0, 1, 1), vec3(1, 1, 0), vec3(0, 1, 1), vec3(-1, -1, 0), vec3(0, 1, 1), vec3(-1, -1, 0),
    vec3(0, 1, 1), vec3(-1, -1, 0), vec3(-1, -1, 0), vec3(0, -1, -1), vec3(1, 1, 0), vec3(0, -1, -1), 
    vec3(1, 1, 0), vec3(0, -1, -1), vec3(1, 1, 0));
    
    // Random swap.
    for(int i = 0; i<15; i++){
        if(hash21(vec2(floor(tm/float(ttm)), i)/15.)<.333) swap(dir[i], dir[(i + 1)%15]);
    }
    
    lTotDist = vec3(0); // Total distance.
    
    // Cycle through the animation frames, then move the dice from one level to the
    // the next in whatever random direction the array has chosen. Whilst doing so,
    // keep track for the pivot point, rotation matrix, total distance, etc, for later
    // texture usage... If you're thinking it looks fiddly, you'd be right, but it's
    // all just basic physics and not as hard as you'd think.
    for(int i = 0; i<ttm; i++){

       float fi = float(i);
       dirI = dir[i];

       if(modtm<fi + 1.){ 
            
            // Fractional time component.
            float t = (modtm - fi)/1.;
            
            #ifdef BOUNCE
            // Alternative level to level bounce.
            t = easeOutQuad(t);
            gBounce = (1. - abs(fract(t) - .5)*2.)*GSCALE.x*.25;
            #else
            // Exponential ease.
            t = exponentialOut(t); 
            #endif
            
            // Rotate in the given direction from the pivot point.
            t = mix(0., PI, t);
            if(dirI.z<-.5 || dirI.x>.5) t *= -1.;            
            lRot = rot2(t);
            lPivot = dirI*GSCALE.x/2.;//vec3(0, GSCALE.x, GSCALE.x)/2.;
            
            // Save the pivol and rotation variables.
            gPiv = lPivot;
            gMat = lRot;
           
            break;


       }

       lTotDist += dirI; // Update the overall position.

    }
    

}


// Dice block levels.

vec4 blocks(vec3 q){


    // Brick dimension: Length to height ratio with additional scaling.
	const vec2 dim = GSCALE;//vec2(scale);
    // A helper vector, but basically, it's the size of the repeat cell.
	const vec2 s = dim*2.;

    
    // Distance.
    float d = 1e5;
    // Cell center, local coordinates and overall cell ID.
    vec2 p, ip;
    
    // Individual brick ID.
    vec2 id = vec2(0);
    vec2 cntr = vec2(0);
    
    // Four block central postions.
    vec2[4] ps4 = vec2[4](vec2(-.5, .5), vec2(.5),   vec2(.5, -.5), vec2(-.5));
 
    
    float height = 0.; // Block height initialization.
    
    // Height scale.
    const float hs = .125;


    for(int i = 0; i<4; i++){

        // Block center.
        cntr = ps4[i]/2.;// -  ps4[0]/2.;
        
 
        
        p = q.xz - cntr*s;
        ip = floor(p/s) + .5; // Local tile ID.
        p -= (ip)*s; // New local position.
        
        
        // Correct positional individual tile ID.
        vec2 idi = (ip + cntr)*s;

  
        // Block height.
        float h1 = (ip.y - .5 - float(i/2)/2.)*GSCALE.y + 1.;//hm(idi);
        h1 += (ip.x - .5)*GSCALE.x + 1.;
        if(i==0 || i==3) h1 -= GSCALE.x/2.;
        
 
        // Render the dice.
        float qy = mod(q.y - GSCALE.x/2., GSCALE.x*2.) - GSCALE.x;
        float face1Ext = sBox(vec3(p, qy), vec3(dim.x/2.), .07);
        face1Ext = smax(face1Ext, length(vec3(p, qy)) - GSCALE.x/2.*1.55, .1);
        qy = mod(q.y + GSCALE.x/2., GSCALE.x*2.) - GSCALE.x;
        float face2Ext = sBox(vec3(p, qy), vec3(dim.x/2.), .07);
        face2Ext = smax(face2Ext, length(vec3(p, qy)) - GSCALE.x/2.*1.55, .1);
        face1Ext = min(face1Ext, face2Ext);
        
        face1Ext = max(face1Ext, (q.y - h1*2. + .01));
        
        vec4 di = vec4(face1Ext, idi, h1);
        
        // If applicable, update the overall minimum distance value,
        // ID, and box height. 
        if(di.x<d){
            d = di.x;
            id = di.yz;
            height = di.w; 
     
        }
        
    }
    
    // Return the distance, position-based ID and triangle ID.
    return vec4(d, id, height);
}







// Block ID -- It's a bit lazy putting it here, but it works. :)
vec3 gID;

// The extruded image.
float map(vec3 p){
    
    
    // Reflecting the wall opposite to give the light something to relect off of.
    //p.y =  abs(p.y - .25) - .75;
    
    // Wall behind the pylons to stop the light getting through.
    vec3 q = p;
    
    q.yz *= rot2(3.14159/4.);
    q.xy *= rot2(-3.14159/5.);
    float wall = 1e5;//q.y - .7071 + .1;//abs(q.y - .7017 + 1.) - 1.;//1.5*.7071;
    
 
    // Blocks.
    vec4 d4 = blocks(p);
    gID = d4.yzw; // Individual block ID.
    
    
    // Move and render the die.
    
    // Initial point.
    q = p - gOff- lTotDist*GSCALE.x; 
    // Bounce.
    q.y -= gBounce;
    // Pivot about the pivot point.
    q -= lPivot;
    // Depending on direction rotate around the XY plane or the YZ one.
    if(abs(dirI.x)>.5) q.xy = lRot*q.xy;
    else q.yz = lRot*q.yz;
    // Pivot back.
    q += lPivot;
 
    // Factor in the total rotation for each direction.
    q.xy = rot2(mod(lTotDist.x, 2.)*PI)*q.xy;
    q.yz = rot2((lStartYZ + mod(lTotDist.z, 2.))*PI)*q.yz;

    // Keep a global texture copy for texturing later. 
    gTxP = q; 
    
    // Render the smooth edged rounded cube.
    float bx = sBox(q, vec3(GSCALE.x/2.), .07);
    bx = smax(bx, length(q) - GSCALE.x/2.*1.55, .1);
    
 
    // Overall object ID.
    objID = (wall<d4.x && wall<bx)? 2 : d4.x<bx? 0 : 1;
    
    // Combining the wall with the extruded blocks.
    return min(wall, min(d4.x, bx));
 
}


// Basic raymarcher.
float trace(vec3 ro, vec3 rd){

    // Overall ray distance and scene distance.
    float t = 0., d; 
    
    for(int i = 0; i<72; i++){
    
        d = map(ro + rd*t);
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, as
        // "t" increases. It's a cheap trick that works in most situations... Not all, though.
        if(d*d<DELTA*DELTA || t>FAR) break; // Alternative: .001*max(t*.25, 1.), etc.
        
        t += i<32? d*.5 : d*.9; // Slower, but more accuracy.
        //t += d*.7; 
    }

    return min(t, FAR);
}


// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with limited 
// iterations is impossible... However, I'd be very grateful if someone could prove me wrong. :)
float softShadow(vec3 ro, vec3 lp, vec3 n, float k){

    // More would be nicer. More is always nicer, but not really affordable... Not on my slow test machine, anyway.
    const int iter = 24; 
    
    ro += n*.0015; // Bumping the shadow off the hit point.
    
    vec3 rd = lp - ro; // Unnormalized direction ray.

    float shade = 1.;
    float t = 0.; 
    float end = max(length(rd), 0.0001);
    //float stepDist = end/float(maxIterationsShad);
    rd /= end;
    
    //rd = normalize(rd + (hash33R(ro + n) - .5)*.03);
    

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. Obviously, the lowest 
    // number to give a decent shadow is the best one to choose. 
    for (int i = 0; i<iter; i++){

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
float calcAO(in vec3 p, in vec3 n){

	float sca = 2., occ = 0.;
    for( int i = min(iFrame, 0); i<5; i++ ){
    
        float hr = float(i + 1)*.15/5.;        
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
        
        // Deliberately redundant line that may or may not stop the 
        // compiler from unrolling.
        if(sca>1e5) break;
    }
    
    return clamp(1. - occ, 0., 1.);
}


// Standard normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 getNormal(in vec3 p) {
	
    const vec2 e = vec2(.001, 0);
    
    //vec3 n = normalize(vec3(map(p + e.xyy) - map(p - e.xyy),
    //map(p + e.yxy) - map(p - e.yxy),	map(p + e.yyx) - map(p - e.yyx)));
    
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



// Render the dots on each face of each cube in the scene.
float getDots(vec3 p, vec3 n){

    // Choose the face. Based on some of Fizzer's cube mapping logic.
    vec3 aN = abs(n);

    ivec3 idF = ivec3(n.x<-.25? 0 : 5, n.y<-.25? 1 : 4, n.z<-.25? 2 : 3);

    int face = aN.x>.5? idF.x : aN.y>.5? idF.y : idF.z; 

    float zDist = GSCALE.x/2.;
    
    vec2 tuv = p.xy; // Face UV coordinates.

    // Render the face dots, according to face ID.
    // How you go about this is up to you. There'd probably be more efficient
    // ways, but this will do.
    float dots = 1e5;
    const float dSz = .0;
    const float dsp = .12;
    //if(face == 0)  dots = length(vec3(tuv, p.z + zDist)); // 3D -- Not needed.
    if(face == 0)  dots = length(tuv);
    else if(face == 1){
        dots = min(length(tuv - dsp), length(tuv + dsp));
        // 3D -- Not needed.
        //dots = length(vec3(tuv - dsp, p.z + zDist));
        //dots = min(dots, length(vec3(tuv + dsp, p.z + zDist)));
    }
    else if(face == 2){
        dots = length(tuv);
        dots = min(dots, min(length(tuv - dsp), length(tuv + dsp)));
    }
    else if(face == 3){
        tuv = abs(tuv) - dsp;
        dots = length(tuv);
    } 
    else if(face == 4){
        dots = length(tuv);
        tuv = abs(tuv) - dsp;
        dots = min(dots, length(tuv));

    }     
    else if(face == 5){
        tuv.y = abs(tuv.y) - dsp;
        dots = length(tuv);
        tuv.x = abs(tuv.x) - (dsp + .02);
        dots = min(dots, length(tuv));

    } 
    
    return dots - dSz;
                
}


// A global value to record the distance from the camera to the hit point. It's used to tone
// down the sand height values that are further away. If you don't do this, really bad
// Moire artifacts will arise. By the way, you should always avoid globals, if you can, but
// I didn't want to pass an extra variable through a bunch of different functions.
float gT;

// Surface bump function..
float bumpSurf3D(in vec3 txP, in vec3 n){

    
    vec3 txN = n;
     
    vec3 tuv = vec3(0);
    
    // Background dice.
    if(svObjID==0){  
       
        // Randomly rotate the faces.
        float rndXY = hash21(svGID.yz);
        float rndYZ = hash21(svGID.yz + .37);
        float rndZX = hash21(svGID.yz + .71);
        vec3 rSn = txN;
        rSn.xy *= rot2(floor(rndXY*36.)*PI/2.);
        rSn.yz *= rot2(floor(rndYZ*36.)*PI/2.);
        rSn.xz *= rot2(floor(rndZX*36.)*PI/2.);
        
        // Select the UV coordinates from the dominant normal.
        // If X is dominant, then select the YZ face, etc.
        vec3 aN = abs(txN);
        tuv = aN.x>.5? txP.yzx*vec3(1, 1, -1) :  aN.y>.5? txP.zxy*vec3(1, 1, -1) : txP.xyz*vec3(1, 1, -1);
    
        tuv = mod(tuv, GSCALE.x) - GSCALE.x/2.;
        
        txN = rSn;
    
    }
    
    // Moving die.
    if(svObjID==1){
    
    
        // Saved rotation data to rotated the normal to the 
        // correct position.
       
        if(abs(svPiv.x)>.01){
             txN.xy = svMat*txN.xy;
        }
        else {
             txN.yz = svMat*txN.yz;
        }  
       
        // Overall rotation.
        txN.xy = rot2(mod(lTotDist.x, 2.)*PI)*txN.xy;
        txN.yz = rot2((mod(lStartYZ + lTotDist.z, 2.))*PI)*txN.yz;    
 
        // Select the UV coordinates from the dominant normal.
        // If X is dominant, then select the YZ face, etc.
        vec3 aN = abs(txN);
        tuv = aN.x>.5? txP.yzx :  aN.y>.5? txP.zxy : txP.xyz;
        
    }
    
    
    
    
    // Rendering the dots on the faces.
    float d = 1.;
    
    if(svObjID<2) {
        d = getDots(tuv, txN); //sin(tuv.x*64.)*.5 + .5;//
        
        //tuv = mod(tuv - GSCALE.x/2., GSCALE.x) - GSCALE.x/2.;
        //float sq = max(abs(tuv.x), abs(tuv.y)) - GSCALE.x/2. + .01;
        //d = min(d, abs(sq));

        d = smoothstep(0., .06, d);
        
        // Corrugated grooves... Why I thought this would work, I'll never know. :D
        //d *= sin((tuv.x)*40.)*.04 + .96;
        
    }
    
    
    // A surprizingly simple and efficient hack to get rid of the super annoying Moire pattern 
    // formed in the distance. Simply lessen the value when it's further away. Most people would
    // figure this out pretty quickly, but it took far too long before it hit me. :)
    return  d;//d/(1. + gT*gT*.015);
   
   
}

// Standard function-based bump mapping routine: This is the cheaper four tap version. There's
// a six tap version (samples taken from either side of each axis), but this works well enough.
vec3 doBumpMap(in vec3 p, in vec3 nor, float bumpfactor, inout float ref){


    // Larger sample distances give a less defined bump, but can sometimes lessen the aliasing.
    const vec2 e = vec2(0.001, 0);
    
    // It'd be nice to have elegant looking code, but in reality, it's all about 
    // hacks. The cube moves in relation to the rest of the scene, and needs 
    // to have it's relative position tracked for texturing purposes... 
    // And the relative sample offsets, it would appear... That's just painful. 
    // Not all coding is fun. :)
    vec3 v0 = e.xyy;
    vec3 v1 = e.yxy;
    vec3 v2 = e.yyx;
   
    if(svObjID==1){
    
        p = svTxP;
        
        if(abs(svPiv.x)>.01){
             v0.xy = svMat*v0.xy;
             v1.xy = svMat*v1.xy;
             v2.xy = svMat*v2.xy;
        }
        else {
             v0.yz = svMat*v0.yz;
             v1.yz = svMat*v1.yz;
             v2.yz = svMat*v2.yz;
        }  
       
        // Overall rotation.
        v0.xy = rot2(mod(lTotDist.x, 2.)*PI)*v0.xy;
        v0.yz = rot2((lStartYZ + mod(lTotDist.z, 2.))*PI)*v0.yz;    
        v1.xy = rot2(mod(lTotDist.x, 2.)*PI)*v1.xy;
        v1.yz = rot2((lStartYZ + mod(lTotDist.z, 2.))*PI)*v1.yz;    
        v2.xy = rot2(mod(lTotDist.x, 2.)*PI)*v2.xy;
        v2.yz = rot2((lStartYZ + mod(lTotDist.z, 2.))*PI)*v2.yz;
        
    }
    
     
    
    // Gradient vector: vec3(df/dx, df/dy, df/dz);
    ref = bumpSurf3D(p, nor); // The reference value is returned for later use.
    vec3 grad = (vec3(bumpSurf3D(p - v0, nor),
                      bumpSurf3D(p - v1, nor),
                      bumpSurf3D(p - v2, nor)) - ref)/e.x; 
    
    /*
    // Six tap version, for comparisson. No discernible visual difference, in a lot of cases.
    vec3 grad = vec3(bumpSurf3D(p - e.xyy) - bumpSurf3D(p + e.xyy),
                     bumpSurf3D(p - e.yxy) - bumpSurf3D(p + e.yxy),
                     bumpSurf3D(p - e.yyx) - bumpSurf3D(p + e.yyx))/e.x*.5;
    */
       
    // Adjusting the tangent vector so that it's perpendicular to the normal. It's some kind 
    // of orthogonal space fix using the Gram-Schmidt process, or something to that effect.
    grad -= nor*dot(nor, grad);          
         
    // Applying the gradient vector to the normal. Larger bump factors make things more bumpy.
    return normalize(nor + grad*bumpfactor);
	
}

/*
// Texture bump mapping. Four tri-planar lookups, or 12 texture lookups in total. I tried to
// make it as concise as possible. Whether that translates to speed, or not, I couldn't say.
vec3 texBump( sampler2D tx, in vec3 p, in vec3 n, float bf){
   
    const vec2 e = vec2(.001, 0);
    
    // Three gradient vectors rolled into a matrix, constructed with offset greyscale texture values.    
    mat3 m = mat3(tex3D(tx, p - e.xyy, n), tex3D(tx, p - e.yxy, n), tex3D(tx, p - e.yyx, n));
    
    vec3 g = vec3(.299, .587, .114)*m; // Converting to greyscale.
    g = (g - dot(tex3D(tx,  p , n), vec3(.299, .587, .114)))/e.x; 
    
    // Adjusting the tangent vector so that it's perpendicular to the normal -- Thanks to
    // EvilRyu for reminding me why we perform this step. It's been a while, but I vaguely
    // recall that it's some kind of orthogonal space fix using the Gram-Schmidt process. 
    // However, all you need to know is that it works. :)
    g -= n*dot(n, g);
                      
    return normalize( n + g*bf ); // Bumped normal. "bf" - bump factor.
	
}
*/


// Compact, self-contained version of IQ's 3D value noise function. I have a transparent noise
// example that explains it, if you require it.
float n3D(in vec3 p){
    
	const vec3 s = vec3(7, 157, 113);
	vec3 ip = floor(p); p -= ip; 
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    p = p*p*(3. - 2.*p); //p *= p*p*(p*(p * 6. - 15.) + 10.);
    h = mix(fract(sin(h)*43758.5453), fract(sin(h + s.x)*43758.5453), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z); // Range: [0, 1].
}

// FBM.
float fBm(vec3 p){ return n3D(p)*.57 + n3D(p*2.)*.28 + n3D(p*4.)*.15; }

// Very basic pseudo environment mapping... and by that, I mean it's fake. :) However, it 
// does give the impression that the surface is reflecting the surrounds in some way.
//
// More sophisticated environment mapping:
// UI easy to integrate - XT95    
// https://www.shadertoy.com/view/ldKSDm
vec3 envMap(vec3 p){
    
    p *= 5.;
    p.x += iTime/2.;
    
    float n3D2 = n3D(p*2.);
   
    // A bit of fBm.
    float c = n3D(p)*.57 + n3D2*.28 + n3D(p*4.)*.15;
    c = smoothstep(.4, 1., c); // Putting in some dark space.
    
    
    //p = pow(min(vec3(1.4, 1, 1)*c, 1.), vec3(1, 3, 16)); // Fire.
    p = vec3(c, c*c, c*c*c*c); // Orange tinge.
   
    p = mix(p, p.zyx, n3D2); // Mixing the color around.
    
    return p*p;

}


void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    
    // Screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
	

    // Ray origin.
    float tm = iTime/12.;
    vec3 ro = vec3(0, 5. + tm, -5. + tm); 
    // "Look At" position.
    vec3 lk = ro + vec3(.18, -.15, .2);//vec3(0, -.25, iTime);  
 
    // Light positioning.
 	vec3 lp = ro + vec3(2.5, 1, 2.25); // Put near the camera.
	

    // Using the above to produce the unit ray-direction vector.
    float FOV = 1.; // FOV - Field of view.
    vec3 fwd = normalize(lk - ro);
    vec3 rgt = normalize(vec3(fwd.z, 0., -fwd.x )); 
    // "right" and "forward" are perpendicular, due to the dot product being zero. Therefore, I'm 
    // assuming no normalization is necessary? The only reason I ask is that lots of people do 
    // normalize, so perhaps I'm overlooking something?
    vec3 up = cross(fwd, rgt); 
    
 
    // Unit direction ray.
    vec3 rd = normalize(uv.x*rgt + uv.y*up + fwd/FOV);
    //vec3 rd = mat3(rgt, up, fwd)*normalize(vec3(uv, 1./FOV));
    
    // Camera position. Initially set to the ray origin.
    vec3 cam = ro;
    // Surface postion. Also initially set to the ray origin.
    vec3 sp = ro; 
    
    float gSh = 1.;
    float objRef = 1.;
     
    vec3 col = vec3(0); 
    
    float alpha = 1.;
    
    moveCube(tm);
    
    for(int j = 0; j<PASSES; j++){
    
         
        // Layer or pass color. Each pass color gets blended in with
        // the overall result.
        vec3 colL = vec3(0);

        // Used for refractions, but not here.    
        //float distanceFactor = 1.;

        
        // Raymarch to the scene.
        float t = trace(sp, rd);

        // Saving the object ID, block ID and cell object (block part) ID.
        svObjID = objID;
        svGID = gID;
        
        // Saving the texture, pivot and rotaion matrices for the animated
        // die on the surface.
        svTxP = gTxP;
        svPiv = gPiv;
        svMat = gMat;
        
        //float svBounce = gBounce;


        // Advance the ray to the surface. This becomes the new ray origin for the
        // next pass.
        sp += rd*t;
        
        
        // If the ray hits a surface, light it up. By the way, it's customary to put 
        // all of the following inside a single function, but I'm keeping things simple.
        // Blocks within loops used to kill GPU performance, but it doesn't seem to
        // effect the new generation systems.
      
        if(t<FAR){

            // Surface normal.
            vec3 sn = getNormal(sp);// *distanceFactor; // For refractions.
            
            
            // Function based bump mapping.
            //
            // The bump value at the hit point -- Used for later shading purposes.
            float bumpShade; 
            sn = doBumpMap(sp, sn, .1, bumpShade);///(1. + t*t/FAR/FAR*.25)
            
            // Texture size factor.
            float sz0 = 1./2.;
           
             
            // Integrating bump mapping -- Not used here. It's possible
            // to bump map on a pass by pass basis to save cycles.
            //vec3 smSn = sn;
            //sn = texBump(iChannel0, sp*sz0, sn, .005);///(1. + t/FAR)
            //vec3 reflection = reflect(rd, normalize(mix(smSn, sn, .35)));
             
            
            // The reflective ray, which tends to be very helpful when
            // calculating reflections. :)
            vec3 reflection = reflect(rd, sn);
            
            vec3 ld = lp - sp; // Point light direction.
            float lDist = length(ld); // Surface to light distance.
            ld /= max(lDist, .0001); // Normalizing.
            
            
            // Shadows and ambient self shadowing.
            //
            // Shadows are expensive. It'd be nice to include shadows on each bounce,
            // but it's still not really viable, so we just perform them on the 
            // first pass... Years from now, I'm hoping it won't be an issue.
            if(j == 0) gSh = softShadow(sp, lp, sn, 8.);
            float ao = calcAO(sp, sn); // Ambient occlusion.
            float sh = min(gSh + .2, 1.); // Shadow.
            

            float att = 1./(1. + lDist*lDist*.1); // Attenuation.

            float dif = max(dot(ld, sn), 0.); // Diffuse lighting.
            float spe = pow(max(dot(reflection, ld), 0.), 8.);
            float fre = clamp(1. + dot(rd, sn), 0., 1.); // Fresnel reflection term.
            
            dif = pow(dif, 4.)*2.; // Ramping up the diffuse.

            float Schlick = pow( 1. - max(dot(rd, normalize(rd + ld)), 0.), 5.);
            float freS = mix(.25, 1., Schlick);  //F0 = .2 - Glass... or close enough.

      
            // Object color.
            vec3 oCol;
            
             
            if(svObjID == 0) {

                // Coloring the background dice.
                float rnd2 = hash21(svGID.yz + floor(sp.y/GSCALE.x) + .3);
                
                // Block coloring.
                vec3 tx = tex3D(iChannel0, sp*sz0, sn);
                tx = smoothstep(-.05, .5, tx);
                //tx = mix(tx, vec3(1)*dot(tx, vec3(.299, .587, .144)), .5);
                oCol = tx*mix(vec3(.9, 1, 1.2).zyx, vec3(.9, 1, 1.2), tx.x);
                oCol *= vec3(.85, 1, 1.2);
                 
                //oCol *= mix(vec3(.8, 1, 1.2), 1./vec3(.8, 1, 1.2), 
                // mod(svGID.y + svGID.z, 2.)<.5? 0. : 1.);
                //float rnd = hash21(svGID.yz);
                //vec3 rCol = .6 + .4*cos(6.2831*rnd/4. + vec3(0, 1, 2));
               
                //objRef = .25;
                // Arrange for less reflection in the dice holes.
                objRef = mix(.125, .25, smoothstep(0., .1, bumpShade));

                
            }
            else if(svObjID == 1) {
            
                // Texture the colored moving die.
                
                // Saved texture value from the die movement function.
                vec3 txP = svTxP;
                
                // Using the saved rotation matrices to rotate the face
                // normal to the correct position.
                vec3 txN = sn;
 
                if(abs(svPiv.x)>.01){
                      txN.xy = svMat*txN.xy;
                }
                else {
                      txN.yz = svMat*txN.yz;
                }
               
                // Overall rotation.
                txN.xy = rot2(mod(lTotDist.x, 2.)*PI)*txN.xy;
                txN.yz = rot2((mod(lStartYZ + lTotDist.z, 2.))*PI)*txN.yz;
                   

                // Block texturing and coloring.
                vec3 tx = tex3D(iChannel0, txP*sz0, txN);
                tx = smoothstep(-.05, .55, tx);
                //tx = vec3(1)*dot(tx, vec3(.299, .587, .144));

                //oCol = tx*vec3(1, .3, .5)*2.;
                oCol = tx*mix(vec3(1, .42, .28).xzy, vec3(1, .42, .28), tx.x*1.1)*2.6;
                //oCol = tx*vec3(.2, .58, 1)*2.6;
        
                
                //vec3 aN = abs(txN);
                //vec3 tuv = aN.x>.5? txP.yzx :  aN.y>.5? txP.zxy : txP.xyz;
                //float sq = sBox(tuv.xy, vec2(GSCALE.x/2. - .07), .05);
                //sq = abs(sq) - .02;
                //oCol = mix(oCol, vec3(0), (1. - smoothstep(0., .003, sq))*.9);
               
                //objRef = .25;
                // Arrange for less reflection in the dice holes.
                objRef = mix(.125, .25, smoothstep(0., .1, bumpShade));

                
            }
            else {
                // Dark wall behind the tiny gaps in the blocks. 
                oCol = vec3(0);
                objRef = .0;
            }
            
 

            // Combining the diffuse, specular and Fresnel terms, if applicable.
            colL = oCol*(dif + vec3(1, .7, .5)*spe*16. + .1);// + vec3(1, .7, .5).zyx*pow(freS, 2.)*2.;
            
            // Optional environmental mapping. Not used.
            vec3 envCol = envMap(reflection);
            //vec3 envCol = texture(iChannel1, reflection).xyz; envCol *= envCol;
            colL += colL*envCol.zyx*8.;
            
            // Multiply the dice dots by the bump value for extra depth.
            if(svObjID<2) colL *= bumpShade;
            
            // Combining it with the object color, then shading.
            colL *= ao*att*sh;
 
            
            // Set the unit direction ray to the new reflected direction, and bump the 
            // ray off of the hit point by a fraction of the normal distance. Anyone who's
            // been doing this for a while knows that you need to do this to stop self
            // intersection with the current launch surface from occurring... It used to 
            // bring me unstuck all the time. I'd spend hours trying to figure out why my
            // reflections weren't working. :)
            rd = reflection;
            sp += sn*DELTA*1.1;

        }

        // Fog: Redundant here, since the ray doesn't go far, but necessary for other setups.
        float td = length(sp - cam); 
        vec3 fogCol = vec3(0);//mix(vec3(.1, .3, 1)/12., vec3(.25, .5, 1)/6., rd.y*.5 + .5);
        colL = mix(colL, fogCol, smoothstep(0., .95, td/FAR));
        
        
        // This is a more subtle way to blend layers. 
        //col = mix(col, min(colL, 1.), 1./float(1 + j)*alpha);
        // In you face additive blend. Sometimes, I prefer this.
        col += min(colL, 1.)*alpha;
        
        // If the hit object's reflective factor is zero, or the ray has reached
        // the far horizon, break.
        if(objRef<.001 || t >= FAR) break;
        
        // Decrease the alpha factor (ray power of sorts) by the hit object's reflective factor.
        alpha *= objRef;
    }
   
    
    /*
    // Cheap hash pattern. Needs work... Much more work. :)
    float gry = dot(col, vec3(.299, .587, .114));
    gry = sqrt(gry);
    float pat = 1.;
      
    const int NN = 5;
    const float fn = float(NN);
    float lns = 200.*iResolution.y/450.;
    float sf = 1./iResolution.y;
    for(int i = 0; i<NN; i++){
        
        vec2 rp = rot2(3.14159/3. - float(i)*6.2831/fn/2.)*uv;
        rp += float(i)/fn;
        float patL = abs(fract((rp.x)*lns) - .5)*2. - .05;
        
        if(gry<(fn - float(i))/(fn + 1.)) pat = min(pat, patL);
    }
    
    pat = smoothstep(0., sf*lns*2., pat);
    col = vec3(pat*;
    */
    
    // Rough gamma correction.
    fragColor = vec4(sqrt(max(col, 0.)), 1);
}