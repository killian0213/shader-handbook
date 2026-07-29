// Image (image) — Transparent Truchet by Shane
// https://www.shadertoy.com/view/3l2fDt

/*

	Transparent Truchet
	-------------------

	This is a basic refractive example. The scene isn't particularly exciting,
	but the refractive element adds a little extra flavor... Not much, but a
	little. :) 

	A few years ago, GPUs didn't enjoy branching, and seemed to hate nesting. 
    Even now, I try not to nest things too much. Anyway, for whatever reason,
    these are not as big an issue as they once were, so we can at least put
	together simple scenes with multiple bounces.

    By the way, in case it needs to be said, a real refractive\reflective example 
    would require a stack to handle simultaneous reflective and refractive passes, 
    whereas this takes a lesser approach. By that, I mean this will attempt to 
    refract the surface normal of a refractive surface, then continue without 
    reflecting, and only reflect in the invent that it's not possible. The results 
    are good enough for simple examples like this, but definitely not production
	grade.

	If this were a path tracing example, I'd put a lot more effort into the
	correctness of the coloring. However, it's not, since I've basically thrown
	stuff in that I felt suited the situation, so don't pay too much attention
	to it. Having said that, I was going for a kind of smokey glass casing look, 
    and it's close enough, so it'll do. :) The refractive based logic is from 
    memory... Visually, things seem about right, but if you spot any mistakes, 
    feel free to let me know.

	For anyone interested, the background is a custom version of the box divide 
    formula, which is related to KD trees. The coloring is provided via IQ's 
    versatile cosine palette formula.
    

    
    Other examples:

	// An old favorite. Simple and pretty.
    Spout - P_Malin
	https://www.shadertoy.com/view/lsXGzH

    // If you're trying to implement a basic multipass refraction and reflection 
    // example, I'd recommend this one. There are subtle differences, but I'm
    // using similar logic. I adopted some of the naming conventions as well.
    Glass Polyhedron - Nrx
    https://www.shadertoy.com/view/4slSzj

 
*/

// Far plane, or max ray distance.
#define FAR 20.

// Minimum surface distance. Used in various calculations.
#define DELTA .001


// Ray passes: For this example, this is about the minimum I could
// get away with. However, not all passes are used on each pixel, so
// it's not as bad as it looks.
#define PASSES 5

// Global block scale.
#define GSCALE vec2(1./3.)



// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// IQ's vec2 to float hash.
//float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.609, 57.583)))*43758.5453); }

// Based on the UE4 random function: I like this because it incorporates a modulo
// 128 wrap, so in theory, things shouldn't blow up with increasing input. Also, 
// in theory, you could tweak the figures by hand to get a really scrambled output... 
// When I'm feeling less lazy, I might do that.
//
// By the way, GPU's are fickle things, so if this isn't working on your
// system, feel free to let me know.
float hash21(vec2 p) {
    
    //p -= floor(p/128.)*128. + vec2(64.340627, 72.465623);
    //return fract(dot(p.xyx*p.xyy, vec3(20.390625, 60.703123, 2.4281207)));
    
    p = fract(p*2.014371)*128. - vec2(63.537567, 64.484713);
    return fract(dot(p.xyx*p.xyy, vec3(128.390654, 128.713193, 2.1396217)));
 
}

/*
// My own experimental hash 
// Seems to work for the right range, but I don't trust it yet.

float hash21(vec2 p){
    
    p = fract(p*2.0143)*128. - vec2(63.537567, 64.484713);
    return fract(dot(p.xyx*p.xyy, vec3(128.390654, 128.713193, 2.1396217)));
    //p.x = dot(p.xyx*p.xyy, vec3(128.390654, 128.713193, 2.1396217));
    //return p.x - floor(p.x);
}

// Another, based on the "17*17 = 289" thing.
float hash21(vec2 p) {
    float x = dot(p, vec2(97, 37));
    x *= 288./289.;                
    x = (x - floor(x))*289.;                         
    x = (x*34. + 113.)*x/289.;                       
    return x - floor(x);                            
}
*/

// Tri-Planar blending function. Based on an old Nvidia tutorial by Ryan Geiss.
vec3 tex3D(sampler2D t, in vec3 p, in vec3 n){ 
    
    n = max(abs(n) - .2, 0.001); // max(abs(n), 0.001), etc.
    //n /= dot(n, vec3(1)); 
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

// Vector container for the object IDs. We make a note of the individual
// identifying number inside the main distance function, then sort them
// outside of it, which tends to be faster.
vec4 vObjID; 

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
    float crv = abs( min(d2.x, d2.y) - hsc.x);
    
    // Flipping the direction on alternate squares so that the animation
    // flows in the right directions -- It's a standard move that I've
    // explained in other examples.  
    float dir = mod(iq.x + iq.y, 2.)<.5? -1. : 1.;
    // Using repeat polar coordinates to create the moving metallic balls.
    vec2 pp = d2.x<d2.y? vec2(q - hsc) : vec2(q + hsc);
    pp *= rot2(iTime*dir); // Animation occurs here.
    float a = -atan(pp.y, pp.x); // Polar angle.
    a = (floor(a/6.2831853*8.) + .5)/8.; // Repeat central angular cell position.
    // Polar coordinate.
    vec2 qr = rot2(-a*6.2831853)*pp; 
    qr.x -= hsc.x;
     
    // Ridges, for testing purposes.
    //crv += clamp(cos(a*16. + dir*iTime*3.)*2., 0., 1.)*.003;
    
    // A rounded square Truchet tube. Look up the torus formula, if you're
    // not sure about this. However, essentially, you place the rounded curve
    // bit in one vector position and the Z depth in the other, etc. Trust me,
    // it's not hard. :)
    //float tr = length(vec2(crv, (p.z) + .05/2. + .02)) - .035;
    float tr = sBoxS(vec2(crv, (p.z) + .05/2. + .01), vec2(.035, .035), .01);
    
    // 3D ball position.
    vec3 bq = vec3(qr,  p.z + .05/2. + .01);
    //float ball = max(length(bq.zx) - .05, abs(bq.y) - .06);
    float ball = length(bq) - .015; // Ball.
    ball = min(tr + .03, ball); // Adding in the railing.
    
    // Hollowing out the Truchet tubing. If you don't do this, it can cause
    // refraction issues, but I wanted the tubes to be hollow anyway.
    tr = max(tr, -(tr + .01));
 
    // Metallic elements, which includes the joins, metal ball joints
    // and the tracks they're propogating along.
    q = abs(abs(q) - .5/sc);
    float mtl = min(q.x, q.y) - .01;
    mtl = max(max(mtl, tr - .015), -(tr - .005));
    
    // Adding the balls. I should probably give them their own ID, but this 
    // involves less work, and I'm always up for that. :D
    mtl = min(mtl, ball);
    
    // Storing the object ID.
    vObjID = vec4(wall, tr, mtl, 1e5);
    
    // Returning the closest object.
    return min(min(wall, tr), mtl);
 
}

 
// Basic raymarcher, but with an added distance factor that is
// required when refracting through the inside of an object.
float trace(vec3 ro, vec3 rd, float distanceFactor){

 
    // Overall ray distance and scene distance.
    float t = 0., d;
    
    for(int i = 0; i<72; i++){
    
        d = map(ro + rd*t)*distanceFactor;
   
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, as
        // "t" increases. It's a cheap trick that works in most situations... Not all, though.
        //if(d*d<DELTA*DELTA || t>FAR) break; // Alternative: .001*max(t*.25, 1.), etc.
        if((d<0. && abs(d)<DELTA) || t>FAR) break; 
       
        t += d*.9; 
        //t += max(d, DELTA); // For cheap on pass refraction... Not used here.
         
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
    for(int i = 0; i<6; i++){
		mp[i] = map(p + sgn*e6[i/2]);
        sgn = -sgn;
        if(sgn>2.) break; // Fake conditional break;
    }
    
    return normalize(vec3(mp[0] - mp[1], mp[2] - mp[3], mp[4] - mp[5]));
}

 
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
 



// Custom box divide formula: I wrote this from scratch, and based it on various 
// techniques, but changed a lot of it to cut down on operations. I also went to
// some trouble to take a space and position preserving approach, which should make
// it much easier to work with. The routines I've come across don't do that. :)
//
// The idea is simple, in theory, and the solution was simple, but as usual, I had
// to make way too many mistakes to get there. Basically, you start in one of the
// corners of the grid square, produce a random number, then split space vertically 
// or horizontally, according to the random factor. For instance, if the random number
// is ".6," then split the space in a 60% to 40% ratio, update postions (depending
// which side of the line you're on), reduce the space dimensions accordingly, etc.
//
// Simple, right? It should have been. :D Anyway, it's done now, so feel free to
// use it for whatever you want.
//
vec4 boxDivide(in vec2 p){
    
    
    // Scaling factor. If changing this, you may need to change a few settings
    // here and there to suit your needs.
    const float sc = 1.;
    p *= sc;
    
    // Basid grid tile ID. This will be further split into subtiles, which will
    // each have their own ID based on postion.
    vec2 ip = floor(p); 
    
    // Vertical offset. 
    #define VERT_OFFSET
   
    // If using the vertical offset option, update the position and ID accordingly.
    #ifdef VERT_OFFSET
    if(mod(ip.x, 2.)>.5){
        p.y -= 1./2.;
        ip = floor(p);
    }
    #endif
   
    p -= ip + .5; // The original grid tile's base local coordinates.

    
    // Block dimension. Every time there's a random split, it'll be factored down
    // according to the random split factor.
    vec2 l = vec2(1, 1);  
    
    // The starting point, which represents the bottom left corner (or is it the top left corner?)
    // of the grid cell. With every split, it will be moved to the new split position.
    vec2 s = vec2(-.5);    
    
    // Split number.
    const int iNum = 8;
    
    float count = 0.;
    
    
    // Create a box, divide it randomly, then do the same with the 
    // divided portions. Ad infinitum...
    for(int i=0; i<iNum; i++) {
 
        float r = hash21(ip + l + float(i)/float(iNum))*.35 + (1. - .35)/2.;
        // Forcing a vertical to horizontal split (and vice versa) every
        // iteration. It's not necessary, but I think it looks nicer.
        float r2 = mod(float(i), 2.)>.5? 0. : 1.;
        
        
        // Minimum width... Thrown in at the last minute to enforce a
        // minimum box size. There are probably better ways, but it works
        // well enough.
        const float mW = .125;
        if(l.x<mW && l.y<mW) break;
        if(l.x<mW && r2>.5) { r2 = 0.; }// r = .5;
        if(l.y<mW && r2<=.5) { r2 = 1.; }
        
        //if(hash21(ip + 113.523 + l.yx + float(i)/float(iNum))<.3) continue;
        
        // If the second random number is above a certain threshold, split 
        // vertically. Otherwise, split horizontally.
        if(r2>.5){ 
            
            // This line splits the current cell down the middle, in accordance with
            // the random factor, "r," and the cell width "l.x." 
            if(p.x>s.x + l.x*r) {

                s.x += l.x*r; // Advance the position to the right of the split.
                l.x *= (1. - r); // Reduce the width by a factor of "1 - r."
            }
            else l.x *= r; // No need to advance position, but we need to reduce the width.
        
        }
        else {
            
              // This line splits the current cell horizontally, in accordance with
             // the random factor, "r," and the cell height "l.y." 
             if(p.y>s.y + l.y*r) {

                s.y += l.y*r; // Advance the position above (or below?) the split.
                l.y *= (1. - r); // Reduce the height by a factor of "1 - r."

             }
             else l.y *= r; // No need to advance position, but we need to reduce the height.
        }
        
        // There are many ways to vary the line width.
        #ifdef VARIABLE_LINE_WIDTH
        l *= 1. - r*.03;
        //l *= 1. - length(l)*.02;
        //l *= .986;
        #endif

    }
    
    
    // Constructing the box itself: Actually, once you have the box coordinates, you can 
    // do whatever you want with them.
    //
    // Rounding factor: This depends on the look you're after. It could be a constant, 
    // or you could choose to have no rounding at all. After experimenting, I decided 
    // to make the roundedness of the tile dependent on the minimum side length.
    float rf = min(l.x, l.y); 
    float d = sBoxS(p - s - l/2., l/2., .05*sqrt(rf));// + .001*sc;
    
   
    
    // Smoothing factor.
    float sf = 1./450.*sc;//1./iResolution.y*sc;
    
    // Individual, position-based tile ID. Note that it'll read into the texture
    // at the correct position.
    vec2 id = ip + s + l/2.;
    
    // If using the vertical offset, the ID needs to follow suit.
    #ifdef VERT_OFFSET
    if(mod(ip.x, 2.)>.5){
        id.y += .5;
    }
    #endif
    
    
    
    // Using the ID to color the individual tile.
   
    // Random colors using IQ's cosine palette.
    float rnd = hash21(id/sc);
    vec3 pCol = .5 + .5*cos(6.2831853*rnd + vec3(0, 1, 2)*1.6);
    pCol = mix(pCol, pCol.xzy, .2);//vec3(.2 + rnd*.4);//
    
    
    // Another random colored version.
    //pCol = vec3(1, hash21(id), hash21(id*57. + .5)*.8);
    //pCol = mix(pCol, pCol.xzy, .35);//vec3(.2 + rnd*.4);
    
     // Textured version. Note that this is not an overlay -- Each tile has 
    // a uniform color.
    //vec3 tx = texture(iChannel0, id/sc + .5).xyz; tx *= tx;
    //vec3 pCol = smoothstep(0., .5, tx);
    
    
   
    // Rectangular cell border and coloring.
    vec3 col = mix(vec3(.1), vec3(0), 1. - smoothstep(0., sf, d)); // Rounded pavers.
    col = mix(col, pCol, 1. - smoothstep(0., sf, d + .003*sc)); 
    //col = mix(col, vec3(0), 1. - smoothstep(0., sf, abs(d + .01*sc) - .001*sc)); 
    
    // Center, space preserving dots.
    // Just the center dot.
    //float d2 = length(p - s - l/2.) - .004/sc;
    // Splitting space to produce four rivot-looking dots.
    p = abs(p - s - l/2.) - l/2. + .015;
    float d2 = length(p) - .004/sc;
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, d2)); // Rounded pavers.  
    
    // Very subtle bump element for some highlighting.
    sf *= 2.;
    d += .002*sc;
    float b = mix(.05, 0., 1. - smoothstep(0., sf, d)); // Rounded pavers.
    b = mix(b, .5, 1. - smoothstep(0., sf, d + .003*sc)); 
    //b = mix(b, 0., 1. - smoothstep(0., sf, abs(d + .01*sc) - .001*sc)); 
    b = mix(b, 0., 1. - smoothstep(0., sf, d2)); // Rounded pavers.  
    
      
    // Return the color and the bump value.
    return vec4(col, b);
    
}




void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    
    // Screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
	

    // Ray origin.
	vec3 ro = vec3(iTime/8., 0, -1); 
    // "Look At" position.
    vec3 lk = ro + vec3(.03, -.02, .25); 
 
    // Light positioning.
 	vec3 lp = ro + vec3(-.5, 1., 0); 
	

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
    // diferent ones for different object, but we only need one for this example.
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

        // Objtain the ID of the closest object.
        float svObjID = vObjID.x<vObjID.y && vObjID.x<vObjID.z? 0. : vObjID.y<vObjID.z? 1. : 2.;
 

        // Advance the ray to the surface. This becomes the new ray origin for the
        // next pass.
        sp += rd*t;
        
        
        // If the ray hits a surface, light it up. By the way, it's customary to put 
        // all of the following inside a single function, but I'm keeping things simple.
        // Blocks within loops used to kill GPU performance, but it doesn't seem to
        // effect the new generation systems.
      
        if(t<FAR){
        //if((d<0. && abs(d)<delta) && t<FAR){

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
            sn = texBump(iChannel0, sp*sz0, sn, .007);///(1. + t/FAR)
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
            //if(j < 2) 
                gSh = softShadow(sp, lp, sn, 12.);
            float ao = calcAO(sp, sn); // Ambient occlusion.
            float sh = min(gSh + .3 + ao*.3, 1.); // Adding a touch of light to the shadow.
            

            float att = 1./(1. + lDist*lDist*.025); // Attenuation.

            float dif = max(dot(ld, sn), 0.); // Diffuse lighting.
            float spe = pow(max(dot(reflection, ld), 0.), 8.);
            float fre = clamp(1. - abs(dot(rd, sn))*.7, 0., 1.); // Fresnel reflection term.
            
            
            float Schlick = pow( 1. - max(dot(rd, normalize(rd + ld)), 0.), 5.);
            float freS = mix(.25, 1., Schlick);  //F0 = .2 - Glass... or close enough.
            
            
            // Object color.
            vec3 oCol;
            
             
           if(svObjID == 0.){ // Back wall.
               
               // Texturing... but I decided against it. 
               //vec3 tx = tex3D(iChannel1, (sp*1.), sn);
               //tx = smoothstep(0., .5, tx);

               // The box divide color and bump factor.
               vec4 bxD = boxDivide(sp.xy);
               // A second sample for some highlighting.
               vec4 bxD2 = boxDivide(sp.xy - normalize(ld.xy)*.003);
               float b = max(bxD2.w - bxD.w, 0.)/.003;
               oCol = bxD.xyz*(b*.015 + .95);//*(tx*.5 + .5);//vec3(.05);//
        
               // Stripes.
               //vec2 q = rot2(-3.14159/4.)*(sp.xy);
               //float str = abs(fract(q.x*15.*1.4142) - .5)*2. - .35;
               //oCol = mix(vec3(1), vec3(0), 1. - smoothstep(0., sf*8., str));

               // The wall has no reflection of refraction, so setting the
               // reflective or transmission power to zero will cause the
               // loop to terminate early, which saves a lot of work.
               objRef = .0;

               spe *= freS;

               // Reflection only override. This ensures that no refraction
               // will occur... It's hacky, but it works. :)
               refraction *= 0.; 
            }
            else if(svObjID == 1.) {  // Glass Truchet tubes.

                // Coloring the glass tubes. Note that we keep the object
                // color dard, in order to look transparent.
                vec3 tx = tex3D(iChannel0, (sp*sz0), sn);
                tx = smoothstep(.05, .5, tx);
                oCol = tx*.125;//*vec3(1, 2, 3); // Color.
                objRef = 1.; 
                
                // Faking more of a glass look.
                //oCol *= tx;
                //objRef = 1.2; 
                
            }
            else { // Metallic stuff.
                
                // Joins and animated metal portion.
                vec3 tx = tex3D(iChannel0, (sp*1.), sn);
                tx = smoothstep(0.05, .5, tx);
                oCol = tx*vec3(1, .85, .6)/3.;
                objRef = .125; // Only a bit of reflectance.
                
                // Ramping up the diffuse on the metal joins.
                dif = pow(dif, 4.)*2.; 
                
                // Reflection only override. This ensures that no refraction
                // will occur... It's hacky, but it works. :)
                refraction *= 0.; 

                
            }
            
            // Simple coloring for this particular ray pass.
            colL = oCol*(dif + .25 + vec3(1, .5, .3)*spe*16. + vec3(.1, .25, 1)*pow(fre, 2.)*8.);
            
            // Shading.
            colL *= sh*ao*att;
            
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
    
    // Rough gamma correction.
    fragColor = vec4(sqrt(max(col, 0.)), 1);
}