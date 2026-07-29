// Buffer A (buffer) — Glass And Metal Tubing by Shane
// https://www.shadertoy.com/view/NdVXWy

/*

	Glass And Metal Tubing
	----------------------

    Creating an antialiased, glass and metal, animated two-tiled 
    hexagonal Truchet scene in realtime. I put this together some 
    time ago, but took a while to put in the finishing touches. It 
    runs at full speed in the large canvas window on my laptop, but 
    it's pretty GPU intensive, so apologies in advance for anyone 
    who experiences slowdown.
    
    There are more than a few challenges associated with creating
    glassy materials in a shader. For anything but the simplest of
    scenes, execution speed is definitely one of them, as you require 
    multiple bounces -- For this particular example, any fewer than 5 
    won't look right. On top of that, the finished product tends to 
    look more sparkly and aliased than usual due to contrasty edges. 
    There's an easy solution, and that is to use multisampling on 
    each frame.
    
    Unfortunately, that's not viable. Rendering slightly offset pixel
    samples to a buffer then combining can help mitigate the aliasing
    to a degree, but with a moving camera, you're then left with 
    temporal camera ghosting. That too can be mitigated with IQ's 
    awesome temporal camera reprojection code -- Speaking of helpful 
    material, going to fullscreen won't utterly slay performance
    thanks to spalmer's maximum resolution and upscaling idea.
    
    Once you've solved those problems, you're still left with ghosting
    due to objects that move relative to the camera, and unfortunately,
    there's not a lot that can be done about it... so I'm declaring any
    motion blur effects a feature. :D Seriously though, if someone
    knows a way around that, I'd love to hear it.
    
    I guess the last thing I should mention is that the distance
    field is an animated two-tiled hexagon Truchet, which wasn't as
    difficult to produce as I thought it'd be. However, it wasn't 
    particularly easy either. Anyway, hopefully the code will make
    it easier for the next person who wants to try it. :) By the way,
    I have one that includes a crossover tubing tile that I'll
    post later.    
    

    
    Useful examples:

	// An old favorite. Simple and pretty.
    Spout - P_Malin
	https://www.shadertoy.com/view/lsXGzH

    // If you're trying to implement a basic multipass refraction and reflection 
    // example, I'd recommend this one. There are subtle differences, but I'm
    // using similar logic. I adopted some of the naming conventions as well.
    Glass Polyhedron - Nrx
    https://www.shadertoy.com/view/4slSzj
    
    // 3D temporal reprojection: IQ puts up a lot of difficult to find code with
    // very little fanfare. This is one example.
    Some boxes - iq
    https://www.shadertoy.com/view/Xd2fzR
    
    // A fullscreen upscaling example, amongst other things.
    Lights, Camera, Action! - spalmer 
    https://www.shadertoy.com/view/sdKXD3
 
*/

// Make use of IQ's well written temporal reprojection code. Unfortunately, 
// if you have a slow machine, all you'll see is blur, so you'll need
// to turn it off.
#define REPROJECTION

// Use the simpler (and faster) square Truchet tiles. In fact, I prefer
// this, since it's faster and looks more antialiased. However, I figured 
// people would appreciate the alternative two tiled animated hexagon 
// Truchet, which is by far the more unique of the two.
//#define SQUARE_TRUCHET

// Ray passes: For this example, this is about the minimum I could
// get away with. However, not all passes are used on each pixel, so
// it's not as bad as it looks.
#define PASSES 5

// Far plane, or max ray distance.
#define FAR 20.

// Minimum surface distance. Used in various calculations.
#define DELTA .001



// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(23.527, 57.683)))*43758.5453); }

/*
// Based on the UE4 random function: I like this because it incorporates a modulo
// 128 wrap, so in theory, things shouldn't blow up with increasing input. Also, 
// in theory, you could tweak the figures by hand to get a really scrambled output... 
// When I'm feeling less lazy, I might do that.
//
// By the way, GPU's are fickle things, so if this isn't working on your
// system, feel free to let me know.
float hash21(vec2 p) {
    
    p -= floor(p/128.)*128. + vec2(64.340627, 72.465623);
    return fract(dot(p.xyx*p.xyy, vec3(20.390625, 60.703123, 2.4281207)));
    
    // My own experimental hash. Seems to work for the right range, but 
    // I don't trust it yet.
    //p = fract(p*2.014371)*128. - vec2(63.537567, 64.484713);
    //return fract(dot(p.xyx*p.xyy, vec3(128.390654, 128.713193, 2.1396217)));
    
    // Another, based on the "17*17 = 289" thing.
    //float x = dot(p, vec2(97, 37));
    //x *= 288./289.;                
    //x = (x - floor(x))*289.;                         
    //x = (x*34. + 113.)*x/289.;                       
    //return x - floor(x);    
 
}
*/


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


// IQ's extrusion formula.
float opExtrusion(in float sdf, in float pz, in float h, in float sf){

    // Slight rounding. A little nicer, but slower.
    vec2 w = vec2( sdf, abs(pz) - h - sf/2.);
  	return min(max(w.x, w.y), 0.) + length(max(w + sf, 0.)) - sf;
}

/*
// IQ's unsigned box formula.
float sBoxSU(in vec2 p, in vec2 b, in float sf){

  return length(max(abs(p) - b + sf, 0.)) - sf;
}
*/

// IQ's signed box formula.
float sBoxS(in vec2 p, in vec2 b, in float sf){

  //return length(max(abs(p) - b + sf, 0.)) - sf;
  p = abs(p) - b + sf;
  return length(max(p, 0.)) + min(max(p.x, p.y), 0.) - sf;
}


// Helper vector. If you're doing anything that involves regular triangles or hexagons, the
// 30-60-90 triangle will be involved in some way, which has sides of 1, sqrt(3) and 2.
const vec2 s = vec2(1, 1.7320508);


// Vector container for the object IDs. We make a note of the individual
// identifying number inside the main distance function, then sort them
// outside of it, which tends to be faster.
vec4 vObjID; 


#ifdef SQUARE_TRUCHET

// The scene. All of it is pretty standard. There's a wall, extruded
// hollowed out Truchet tubing and some metallic elements. To be honest, 
// this was a little rushed, but the field doesn't have a lot going on, 
// so tightening it up wasn't as important as it sometimes is.
float map(vec3 p){
    
    // Back wall
    float wall = -p.z + .01; // Thick wall: abs(p.z - .2) - .21;
     
    // Truchet object and animated metallic balls: This is just a
    // standard 2D animated Truchet with an extruded factor. If you're
    // not sure how it works, myself and others have plenty of 
    // animated Truchet examples on Shadertoy to refer to.
    //
    // Grid construction: Cell ID and local cell coordinates.
    const vec2 GSCALE = vec2(1./3.);
    const vec2 sc = 1./GSCALE, hsc = .5/sc;    
    vec2 iq = floor(p.xy*sc) + .5;    
    vec2 q = p.xy - iq/sc; // Equivalent to: mod(p.xy, 1./sc) - .5/sc;
    
    // Flip random cells. This effectively rotates random cells,
    // but in a cheaper way.
    float rnd = hash21(iq + .37);
    if(rnd<.5) q.y = -q.y;
      
    // Circles on opposite square vertices.
    vec2 d2 = vec2(length(q - hsc), length(q + hsc));
    // Using the above to obtain the closest arc.
    float crv = abs(min(d2.x, d2.y) - hsc.x);
    
    // Flipping the direction on alternate squares so that the animation
    // flows in the right directions -- It's a standard move that I've
    // explained in other examples.  
    float dir = mod(iq.x + iq.y, 2.)<.5? -1. : 1.;
    // Using repeat polar coordinates to create the moving metallic balls.
    vec2 pp = d2.x<d2.y? vec2(q - hsc) : vec2(q + hsc);
    pp *= rot2(iTime*dir); // Animation occurs here.
    float a = atan(pp.y, pp.x); // Polar angle.
    a = (floor(a/6.2831853*8.) + .5)/8.; // Repeat central angular cell position.
    // Polar coordinate.
    vec2 qr = rot2(a*6.2831853)*pp; 
    qr.x -= hsc.x;
     
    // Ridges, for testing purposes.
    //crv += clamp(cos(a*16. + dir*iTime)*2., 0., 1.)*.003;
    
    // A rounded square Truchet tube. Look up the torus formula, if you're
    // not sure about this. However, essentially, you place the rounded curve
    // bit in one vector position and the Z depth in the other, etc. Trust me,
    // it's not hard. :)
    float tr = length(vec2(crv, (p.z) + .05/2. + .02)) - .05;
    //float tr = sBoxS(vec2(crv, (p.z) + .05/2. + .02), vec2(.05, .05), .035);
    
    
 
    // Metallic elements, which includes the joins, metal ball joints
    // and the tracks they're propogating along. This operation needs to be
    // performed prior to hollowing out the tubes. See below.
    q = abs(abs(q) - .5/sc);
    float mtl = min(q.x, q.y) - .01;
    mtl = max(max(mtl, tr - .015), -(tr - .005));
    
    // Adding in the railing.
    float rail = tr + .035 + .01;
    

    // 3D ball position.
    vec3 bq = vec3(qr,  p.z + .05/2. + .02);
    //float ball = max(length(bq.zx) - .02, abs(bq.y) - .03);
    float ball = length(bq) - .02; // Ball.
    //ball = abs(ball + .005) - .005; // Hollow out.
    
    float mtl2 = ball;//max(ball, -(rail - .0025));
    mtl = min(mtl, rail);
    
    // Hollowing out the Truchet tubing. If you don't do this, it can cause
    // refraction issues, but I wanted the tubes to be hollow anyway.
    tr = max(tr, -(tr + .01 + .01));

    // Debug: Take out the glass tubing.
    //tr += 1e5;
    
    // Storing the object ID.
    vObjID = vec4(wall, tr, mtl, mtl2);
    
    // Returning the closest object.
    return min(min(wall, tr), min(mtl, mtl2));
 
}

#else


// Hexagonal grid coordinates. This returns the local coordinates and the cell's center.
// The process is explained in more detail here:
//
// Minimal Hexagon Grid - Shane
// https://www.shadertoy.com/view/Xljczw
//
vec4 getGrid(vec2 p){

    vec4 hC = floor(vec4(p, p - vec2(.5, 1))/s.xyxy) + .5;
    
    // Centering the coordinates with the hexagon centers above.
    vec4 h = vec4(p - hC.xy*s, p - (hC.zw + .5)*s);
    //vec4 h = p.xyxy - vec4(hC.xy + .5, hC.zw)*s.xyxy;
    return dot(h.xy, h.xy)<dot(h.zw, h.zw) ? vec4(h.xy, hC.xy) : vec4(h.zw, hC.zw + .5);

}


// The hexagon field.
float map(vec3 q){

    // Debug usage to compare rigid moving objects with
    // objects that flow with the Truchet tubing.
    #define RIGID_OBJECTS

    // Scaling factor.
    const float sc = 2.;
    
    // Moving object time; A bit redundant here, but helpful when 
    // you want to change the speed without having to refactor everywhere.
    float tm = iTime;
  

    // Back wall
    float wall = -q.z + .1; // Thick wall: (abs(p.z - .2) - .2) + .1;


    // Local hexagonal cell coordinate and cell ID.
    vec4 h = getGrid(q.xy*sc);
    
    // Using the idetifying coordinate - stored in "h.zw," to produce a unique random number
    // for the hexagonal grid cell.
    float rnd = hash21(h.zw + vec2(.11, .31));
    //rnd = fract(rnd + floor(iTime/3.)/10.); // Periodically changing the random number.
    float rnd2 = hash21(h.zw + vec2(.37, 7.83)); // Another random number.
   
    
    // It's possible to control the randomness to form some kind of repeat pattern.
    //rnd = mod(h.z + h.w, 2.)/2.;
    
    
    // Storing the local hexagon cell coordinates in "p". This serves no other
    // purpose than to not have to write "h.xy" everywhere. :)
    vec2 p = h.xy;
    

    // Using the local coordinates to render three arcs, and the cell ID
    // to randomly rotate the local coordinates by factors of PI/3.
    rnd = floor(rnd*144.);
    
    // Random rotation and flow direction..
    float dir = mod(rnd, 2.)*2. - 1.;
    float ang = rnd*3.14159/3.;

    p = rot2(ang)*p; // Random rotate.
    
    
    // Arc radii and thickness variables.
    const float rSm = s.y/6.; // .5/1.732 -> 1.732/2./3.
    const float th = .1; // Arc thickness.

    // The three segment (arc) distances.
    vec3 d;
    
   
    // Metal.
    float mtl = 1e5;
 
    #ifndef RIGID_OBJECTS
    // Angle for non rigid objects.
    float a3;
    #endif
    
    // The Truchet distance.
    float tr = 1e5;
    
    // A scaling constant.
    const float aSc = 1.;
    
    // Is the piece and arc or not. This is an orientation hack that I'll
    // fix later.
    float isArc = 1.;
    
    // Z-based value and a redundant height value that gets used in
    // another example.
    vec3 qZ3, hgt = vec3(0);
    
    // Rotation and minimum coordinate.
    vec2 qR, minP;
    
    if(rnd2<.5){
    
        // Relative local coordinate centers of the two arc and line.
        vec2 p0 = p - vec2(0, -s.y/3.);
        vec2 p1 = p - vec2(0, s.y/3.);
        vec2 p2 = p;
        // Distances.
        d.x = length(p0) - rSm;
        d.y = length(p1) - rSm;
        d.z = abs(p2.y);
        
        d = abs(d)/sc; // Turning the circles into arc segments and scaling.

        // Move the Z-position out to the correct position for all three tubes. 
        // There's a redundant relative height value there for crossover tubes.
        qZ3 = q.z + .045 + hgt;

        // A rounded or square Truchet tube. Look up the torus formula, if you're
        // not sure about this. However, essentially, you place the rounded curve
        // bit in one vector position and the Z depth in the other, etc. Trust me,
        // it's not hard. :)

        // Technically, I could get away with using the minimum 2D arc length and 
        // calculate just one of these, but I'll be extending to include crossover
        // arcs, so I'll leave it in this form.
        d.x = length(vec2(d.x, qZ3.x)) - .05;
        d.y = length(vec2(d.y, qZ3.y)) - .05;
        d.z = length(vec2(d.z, qZ3.z)) - .05;
    /*    
        d.x = sBoxS(vec2(d.x, qZ3.x), vec2(.05, .05), .025);
        d.y = sBoxS(vec2(d.y, qZ3.y), vec2(.05, .05), .025);
        d.z = sBoxS(vec2(d.z, qZ3.z), vec2(.05, .05), .025);
    */    

        
        
        // Arc segment angle calculation.
        if(min(d.x, d.y)<d.z){
            
            // Minimum 
            minP = p1;
            
            // Reverse the direction of the first arc.
            if(d.x<d.y) {
               minP = p0; 
               dir *= -1.;
            }
            
            #ifdef RIGID_OBJECTS
            minP *= rot2(dir*tm); // Animation occurs here.
            float a = atan(minP.y, minP.x); // Polar angle.
            a = (floor(a/6.2831853*6.) + .5)/6.; // Repeat central angular cell position.
            // Polar coordinate.
            qR = rot2(a*6.2831853)*minP; 
            qR.x -= rSm; 
            #else
            a3 = atan(minP.x, minP.y);
            a3 = (a3*(6./6.2831)*aSc - tm*dir);
            #endif
            
        }
        else {
            
            // I guessed a time dialation figure of 3.14159 based on the relative 
            // length of a full circle tube (broken into thirds) and a straight
            // tube (broken into thirds). Pure fluke, but I'll take it. :)
            // Circle tube: length = diameter*PI;
            // Straight tube:  length = diameter;
            // Basically, the objects in the tube will travel just a few percentage
            // points slower than those in the arcs in order to meet up perfectly, 
            // but you'll never notice.
            minP = p2;
            #ifdef RIGID_OBJECTS
            qR = p2;
            qR.x = mod(qR.x - dir*tm/3.14159, 1./3.) - 1./6.;
            isArc = 0.; // Not an arc piece.
            #else
            a3 = minP.x;
            a3 = (a3*(3.)*aSc - tm*dir - aSc*.5);
            #endif
            
        }

    }
    else {
    
        vec2 p0 = p - vec2(-.5, -.5/s.y);
        vec2 p1 = p - vec2(.5, -.5/s.y);
        vec2 p2 = p - vec2(0, s.y/3.);
        d.x = length(p0) - rSm;
        d.y = length(p1) - rSm;
        d.z = length(p2) - rSm;
        
        d = abs(d)/sc; // Turning the circles into arc segments and scaling.

        // Move the Z-position out to the correct position for all three tubes.
        qZ3 = q.z + .045 + hgt;

        // A rounded or square Truchet tube.
        d.x = length(vec2(d.x, qZ3.x)) - .05;
        d.y = length(vec2(d.y, qZ3.y)) - .05;
        d.z = length(vec2(d.z, qZ3.z)) - .05;
    /*    
        d.x = sBoxS(vec2(d.x, qZ3.x), vec2(.05, .05), .025);
        d.y = sBoxS(vec2(d.y, qZ3.y), vec2(.05, .05), .025);
        d.z = sBoxS(vec2(d.z, qZ3.z), vec2(.05, .05), .025);
    */    
        
        // Since the moving objects reside within the tubes, the minimum 3D arc 
        // distance should provide the minimum coordinate upon which to calculate 
        // the angle of the object flowing through it... It will work with this 
        // example, but sometimes, you'll have to calculate all three.
        minP = d.x<d.y && d.x<d.z? p0 : d.y<d.z? p1 : p2;
        
        ///// 
        #ifdef RIGID_OBJECTS
        
        minP *= rot2(dir*tm); // Animation occurs here.
        float a = atan(minP.y, minP.x); // Polar angle.
        a = (floor(a/6.2831853*6.) + .5)/6.; // Repeat central angular cell position.
        // Polar coordinate.
        qR = rot2(a*6.2831853)*minP; 
        qR.x -= rSm; 
        
        #else
      
        // Calculating, scaling and moving the angles.
        a3 = atan(minP.x, minP.y);
        a3 = (a3*(6./6.2831)*aSc - tm*dir);
        
        #endif
        ///// 
    
    }
    
    // The Truchet tube distance is the minimum of all. I could save a couple
    // of "min" calls and set this above, but this will do.
    tr = min(min(d.x, d.y), d.z);
 

    ///// 
    #ifdef RIGID_OBJECTS
    
    // 3D ball position. "qR" is based on "p," which has been scalle
    // by the factor "sc," so needs to be scaled back. "q.z" has not been
    // scaled... Yeah, it can be confusing. :)
    vec3 bq = vec3(qR/2.,  qZ3.x); // All heights are equal, in this example.
    //if(isArc==0.) bq = bq.yxz;
    //float obj =  max(length(bq.zx) - .02, abs(bq.y) - .04); // Cylinder.
    float obj = length(bq) - .02; // Ball.
    // obj = min(tr + .035 + .01, ball); // Adding in the railing.
    
    #else
   
    a3 = abs(fract(a3) - .5) - .25;
    a3 /= (6.*aSc/sc);
    float obj = max(tr + .0325, a3);
    
    #endif
    ///// 
    
    
    // Metallic elements, which includes the joins, metal ball joints
    // and the tracks they're propogating along.
    //
    // Joins.
    vec2 rp = p;
    rp *= rot2(-3.14159/6.); // Animation occurs here.
    float a = atan(rp.y, rp.x); // Polar angle.
    a = (floor(a/6.2831853*6.) + .5)/6.; // Repeat central angular cell position.
    // Polar coordinate.
    rp = rot2(a*6.2831853)*rp; 
    rp.x -= .5; // Moving the element along the radial line to the edge.

    // Construct the joiner rings.
    rp = abs(rp);
    mtl = rp.x - .02;//max(rp.x, rp.y) - .025;
    mtl = max(max(mtl, tr - .015), -(tr - .005));
    
    // Tracks.
    mtl = min(mtl, tr + .045);
    

    
    
    // Hollowing out the Truchet tubing. If you don't do this, it can cause
    // refraction issues, but I wanted the tubes to be hollow anyway. I've 
    // made the walls kind of thick. Obviously, the thickness can effect
    // the way light bounces around, and ultimately the look.
    tr = max(tr, -(tr + .02)); 
    
    
   
    // Debug: Take out the glass tubing, brackets, tracks, etc, to see the inner
    // objects unobstructed.
    //tr += 1e5;
    //mtl += 1e5;
    
   
    // Storing the object ID.
    vObjID = vec4(wall, tr, mtl, obj);
    
    // Returning the closest object.
    return min(min(wall, tr), min(mtl, obj));



}
#endif
 
float trace(vec3 ro, vec3 rd, float distanceFactor){

    float tmin = 0.;
    float tmax = FAR;
    
    // IQ's bounding plane addition, to help give some extra performance.
    //
    // If ray starts above bounding plane, skip all the empty space.
    // If ray starts below bounding plane, never march beyond it.
    const float boundZ = -.11;
    float h = (boundZ - ro.z)/rd.z;
    if(h>0.){
    
        if( ro.z<boundZ ) tmin = max(tmin, h);
        else tmax = min(h, FAR);
    }
 
    float t = tmin;
    for(int i = 0; i<72; i++){
    
        float d = map(ro + rd*t)*distanceFactor;
        if( abs(d)<DELTA ) return t;
        if( t>tmax) break; 
        t += d*.9; 
    }

    return FAR;
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
        //if (d<0. || t>end) break; 
        // Bounding plane optimization, specific to this example. Thanks to IQ. 
        if (d<0. || t>end || (ro.z + rd.z*t)<-0.11) break;
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


// Normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 getNormal(in vec3 p) {
	
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


// Random hash setup.
vec2 seed = vec2(.13, .27);

vec2 hash22() {
    
    seed += vec2(.723, 643);
    seed = fract(seed);
    return fract(sin(vec2(dot(seed.xy, vec2(12.989, 78.233)), dot(seed.xy, vec2(41.898, 57.263))))
                      *vec2(43758.5453, 23421.6361));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){


    #ifdef REPROJECTION
    // Initial hit point and distance.
    vec3 resPos = vec3(0);
    float resT = 1e8;
    #endif
    
    
    // Setting a maximum resolution, then upscaling. I picked up this tip when
    // looking at one of spalmer's examples, here:
    // https://www.shadertoy.com/view/sdKXD3
    const float maxRes = 540.;
    float iRes = min(iResolution.y, maxRes);
    ivec2 iR = ivec2(fragCoord);
    if(iR.y > 0 || iR.x>3){
        fragColor = vec4(0, 0, 0, 1);
        vec2 uv2 = abs(fragCoord - iResolution.xy*.5) - iRes/2.*vec2(iResolution.x/iResolution.y, 1.);
        if(any(greaterThan(uv2, vec2(0)))) return;  // if(uv2.x>0. || uv2.y>0.) return;
       
    }
    
    
    // Screen coordinates.
    seed += fract(iTime)*113.87;
	//vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
    vec2 uv = (fragCoord - iResolution.xy*.5 + (hash22() - .5)/4.)/iRes;
    
    
	

    // Ray origin.
	vec3 ro = vec3(iTime/48.*s.y, iTime/64.*s.x, -1); 
    // "Look At" position.
    vec3 lk = ro + vec3(.04, -.03, .25); 
 
    // Light positioning.
 	vec3 lp = ro + vec3(-.5, 1, 0); 
	

    // Using the above to produce the unit ray-direction vector.
    float FOV = 1.; // FOV - Field of view.
    vec3 fwd = normalize(lk - ro);
    vec3 rgt = normalize(vec3(fwd.z, 0., -fwd.x )); 
    // "right" and "forward" are perpendicular, due to the dot product being zero. Therefore, I'm 
    // assuming no normalization is necessary? The only reason I ask is that lots of people do 
    // normalize, so perhaps I'm overlooking something?
    vec3 up = cross(fwd, rgt); 
    
    mat3 mCam = mat3(rgt, up, fwd);

    // Unit direction ray.
    //vec3 rd = normalize(uv.x*rgt + uv.y*up + fwd/FOV);
    vec3 rd = mCam*normalize(vec3(uv, 1./FOV));
    
    
    // Camera position. Initially set to the ray origin.
    vec3 cam = ro;
    // Surface postion. Also initially set to the ray origin.
    vec3 sp = ro; 
    
    // Global shadow variable and a reflection power variable. The reflection
    // power also applies to refracted objects.
    float gSh = 1.;
    float objRef = 1.;
     
    vec3 col = vec3(0);
   
    // The refraction ratio for the Truchet tubing. Normally, you'd have
    // diferent ones for different objects, but we only need one for this example.
    float refractionRatio = 1./1.5;
    float distanceFactor = 1.;
     
    float alpha = 1.;
    
    // Intersection and coloring for each ray and subsequent bounces.
    for(int j = 0; j<PASSES; j++){
        
        // Layer or pass color. Each pass color gets blended in with
        // the overall result.
        vec3 colL = vec3(0);

        
        // Raymarch to the scene.
        float t = trace(sp, rd, distanceFactor);

        // Objtain the ID of the closest object: With more objects, you'd use a looping
        // mechanism, but I'd imagine this hideous expression is a little faster.
        float svObjID = (vObjID.x<vObjID.y && vObjID.x<vObjID.z && vObjID.x<vObjID.w)? 0. : 
                        vObjID.y<vObjID.z && vObjID.y<vObjID.w? 1. : vObjID.z<vObjID.w? 2. :  3.;

        // Advance the ray to the surface. This becomes the new ray origin for the
        // next pass.
        sp += rd*t;
        
        
        // If the ray hits a surface, light it up. By the way, it's customary to put 
        // all of the following inside a single function, but I'm keeping things simple.
        // Blocks within loops used to kill GPU performance, but it doesn't seem to
        // effect the new generation systems.
      
        if(t<FAR){
         
         
            #ifdef REPROJECTION
            if(j==0){
                // Only save the initial hit point and 
                // distance. Ignore other bounces.
                resPos = sp;
                resT = t;
            }
            #endif
            
            // Surface normal. Refractions, and therefore ray traversal inside
            // of object surfaces are now possible, to the direction of the
            // normal matters... This is yet one of many things that I forget
            // when I haven't done this for a while. :)
            vec3 sn = getNormal(sp)*distanceFactor; // For refractions.
            
            
            // Texture size factor.
            float sz0 = 2.;
            /*
            // Integrating bump mapping -- Not used here. It's possible
            // to bump map on a pass by pass basis to save cycles.
            vec3 smSn = sn;
            sn = texBump(iChannel1, sp*sz0, sn, .007);///(1. + t/FAR)
            //vec3 reflection = reflect(rd, normalize(mix(smSn, sn, .35)));
            */
            
            
            vec3 reflection = reflect(rd, sn);
            vec3 refraction = refract(rd, sn, refractionRatio);
       
            
            vec3 ld = lp - sp; // Point light direction.
            float lDist = length(ld); // Surface to light distance.
            ld /= max(lDist, .0001); // Normalizing.
            
            
            // Shadows and ambient self shadowing.
            //
            // Shadows are expensive. It'd be nice to include shadows on each bounce,
            // but it's still not really viable, so we just perform them on the 
            // first pass... Years from now, I'm hoping it won't be an issue.
            float sh = 1.;
            #if 0
            // Shadows on each bounce.
            sh = softShadow(sp, lp, sn, 12.);
            gSh = min(sh + .5, 1.); // Adding brightness to the shadow.
            #else
            // Shadows on just two bounces.
            if(j < 2){ 
                sh = softShadow(sp, lp, sn, 12.);
                gSh = min(gSh, min(sh + .53, 1.)); 
            }
            #endif
            
            float ao = calcAO(sp, sn); // Ambient occlusion.
            

            float att = 1./(1. + lDist*lDist*.025); // Attenuation.

            float dif = max(dot(ld, sn), 0.); // Diffuse lighting.
            float spe = pow(max(dot(reflection, ld), 0.), 8.);
            
            float fre = max(1. - max(dot(-rd, sn), 0.), 0.); // Fresnel reflection term.
            
            // Fresnel.
            float Schlick = pow(1. - clamp(dot(rd, normalize(rd + ld)), 0., 1.), 5.);
            float freS = mix(.25, 1., Schlick);  //F0 = .2 - Glass... or close enough.
            
            
            // Object color.
            vec3 oCol;
            
             
           if(svObjID == 0.){ // Back wall.
               
               // Texturing. 
               vec3 tx = tex3D(iChannel1, sp, sn);
               tx = smoothstep(-.05, .5, tx);
      
               // Stripes.
               vec2 q = rot2(-3.14159/3.)*sp.xy;
               float str = abs(fract(q.x*12.) - .5)*2. - .4;
               str = min(str, abs(str - .15) - .05);
               oCol = mix(vec3(.5), vec3(.05), 1. - smoothstep(0., .05, str));
               
               oCol *= min(tx*2., 1.);

               // The wall has no reflection of refraction, so setting the
               // reflective or transmission power to zero will cause the
               // loop to terminate early, which saves a lot of work.
               objRef = 0.;

               spe *= freS;

               // Reflection only override. This ensures that no refraction
               // will occur... It's hacky, but it works. :)
               refraction *= 0.; 
            }
            else if(svObjID == 1.) {  // Glass Truchet tubes.

                // Coloring the glass tubes. Note that we keep the object
                // color dark, in order to look transparent.
                vec3 tx = tex3D(iChannel1, sp, sn);
                tx = smoothstep(.05, .5, tx);
                oCol = tx*.125;//*vec3(1, 2, 3); // Color.
                objRef = 1.; 
                
                // Faking more of a glass look.
                oCol *= tx;
                objRef = 1.2; 
                
            }
            else { // Metallic stuff.            
            
                // Technically, I should be moving the texture
                // hit point of the metallic moving objects in
                // relation to their movement, but I wanted to
                // save the calculations. Hopefully, the sliding
                // texture movement isn't too perceptable.
                
                // Joins, tracks and animated metal objects.
                vec3 tx = tex3D(iChannel1, sp, sn);
                tx = smoothstep(.05, .5, tx);
                oCol = tx*vec3(.5);//*vec3(3, 1.6, .8);
                
                
                objRef = .25; // Only a bit of reflectance.
                
                // Ramping up the diffuse on the metal joins.
                dif = pow(dif, 4.)*4.; 
                
                // Reflection only override. This ensures that no refraction
                // will occur... It's hacky, but it works. :)
                refraction *= 0.; 
                
                /*
                // The moving metal objects.
                if(svObjID==3.){
                   oCol *= vec3(3, 1.5, .8); // Gold option.
                   //objRef = 1.;
                }
                */
                
            }
            
            // Simple coloring for this particular ray pass.
            colL = oCol*(dif + .2 + vec3(1, .4, .2)*spe*32.);
            
            if(svObjID==1.) colL += oCol*vec3(.2, .4, 1)*pow(fre, 5.)*16.;
            
            // Shading.
            colL *= gSh*ao*att;
            
            // Used for refraction (Beer's Law, kind of), but not used here.
            //if(distanceFactor<0.)  colL *= exp(-colL*t*5.);
            
            
            // Set the unit direction ray to the new reflected or refracted direction, and 
            // bump the ray off of the hit point by a fraction of the normal distance. 
            // Anyone who's been doing this for a while knows that you need to do this to 
            // stop self intersection with the current launch surface from occurring... It 
            // used to bring me unstuck all the time. I'd spend hours trying to figure out 
            // why my reflections weren't working. :)
 
            // You see this in most refraction\reflection examples. If refraction is possible
            // refract, reverse the distance factor (inside to outside and vice versa) and 
            // bump the ray off the surface. If you can't refract (internal reflection, a 
            // non-refractive surface, etc), then reflect in the usual manner. If the surface
            // neither reflects nor refracts, the object reflectance factor will cause the
            // loop to terminate... I could check for that here, but I want to keep the 
            // decision making simple.
            //
            if (dot (refraction, refraction)<DELTA){
                rd = reflection;
                // The ray is just behind the surface, so it has to be bumped back to avoid collisions.
                sp += sn*DELTA*2.; 
            }   
            else {

                rd = refraction;
                distanceFactor = -distanceFactor;
                refractionRatio = 1./refractionRatio;
                sp -= sn*DELTA*2.;//1.1;
            } 
            
 
        }

        // Fog: Redundant here, since the ray doesn't go far, but necessary for other setups.
        float td = length(sp - cam); 
        vec3 fogCol = vec3(0);
        colL = mix(colL, fogCol, smoothstep(0., .95, td/FAR));
      
        // This is a more subtle way to blend layers. 
        //col = mix(col, colL, 1./float(1 + j)*alpha);
        // Additive blend. Makes more sense for this example.
        col += colL*alpha;///float(PASSES);
        
        // If the hit object's reflective factor is zero, or the ray has reached
        // the far horizon, break. Breaking saves cycles, so it's important to 
        // terminate the loop early when you can.
        if(objRef < .001 || t >= FAR) break;
        
        // Object based breaking. Also possible, but I prefer the above.
        //if(svObjID == 0.)break; 
        
        // Decrease the alpha factor (ray power of sorts) by the hit object's reflective factor.
        alpha *= objRef;
        
    }
    
    
    
    // This is IQ's temporal reprojection code: It's well written and
    // it makes sense. I wrote some 2D reprojection code and was not
    // looking forward to writing the 3D version, and then this 
    // suddenly appeared on Shadertoy. If you're interested in rigid 
    // realtime path traced scenes with slowly moving cameras, this is 
    // much appreciated. :)
    //
    #ifdef REPROJECTION
    //-----------------------------------------------
	// Reproject to previous frame and pull history.
    //-----------------------------------------------
    
    float kFocLen = 1./FOV;
    vec3 pos = resPos;
    ivec2 q = ivec2(fragCoord);
    col = clamp(col, 0., 1.);

    // fetch previous camera matrix from the bottom left three pixels
    mat3x4 oldCam = mat3x4(texelFetch(iChannel0, ivec2(0, 0), 0),
                           texelFetch(iChannel0, ivec2(1, 0), 0),
                           texelFetch(iChannel0, ivec2(2, 0), 0));
    // World space point.
    vec4 wpos = vec4(pos, 1.);
    // Convert to camera space (note inverse multiply).
    vec3 cpos = wpos*oldCam;
    // Convert to NDC space (project).
    vec2 npos = (kFocLen*2.)*cpos.xy/cpos.z*iRes/iResolution.y;
    // Convert to screen space.
    vec2 spos = .5 + .5*npos*vec2(iResolution.y/iResolution.x, 1);
	// Convert to raster space.
    vec2 rpos = spos*iResolution.xy;

    // Read color+depth from this point's previous screen location.
    vec4 ocolt = textureLod( iChannel0, spos, 0.);
    // If we consider the data contains the history for this point.
    if(iFrame>0 && resT<FAR && (rpos.y>1.5 ||rpos.x>3.5)){
    
        // Blend with history (it's an IIR low pas filter really).
        col = mix( ocolt.xyz, col, 1./4.);
    }
    
    // Color and depth.
    fragColor = vec4(col, resT);
    
    // Output.
	if(q.y == 0 && q.x<3){
    
    	// Camera matrix in lower left three pixels, for next frame.
        if(q.x == 0) fragColor = vec4(mCam[0], -dot(mCam[0], ro));
        else if(q.x == 1) fragColor = vec4( mCam[1], -dot(mCam[1], ro));
        else fragColor = vec4( mCam[2], -dot(mCam[2], ro));
    } 
    #else
    // Mix the previous frames in with no camera reprojection.
    // It's OK, but full temporal blur will be experienced.
    vec4 preCol = texelFetch(iChannel0, ivec2(fragCoord), 0);
    float blend = (iFrame < 2) ? 1. : 1./4.; 
    fragColor = mix(preCol, vec4(clamp(col, 0., 1.), 1), blend);
    
    // No reprojection or temporal blur, for comparisson.
    //fragColor = vec4(max(col, 0.), 1);
    #endif
    
    
}