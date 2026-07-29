// Image (image) — Droste 3D by Shane
// https://www.shadertoy.com/view/lfGczc

/*

    Droste 3D
    ---------
    
    A while ago I came across Athibaul's "Stone Circle" shader, which is a really 
    nicely coded piece of work. The thing that initially attracted me to it was the
    minimal coloring and shadow routine, which I really liked.
    
    Anyway, I got bored and started replacing a few things, like the terrain and 
    rock routines, then tweaked the color and ran a gradient algorithm over it to
    give it more of a hand painted look, etc.. I don't believe that in and of itself
    would be enough to warrant a reposting, but then I added a picture frame, and 
    applied a 3D Droste transformation, which gave it a new look, so here it is. :)
    
    Apologies in advance to those with slower systems. The framerate is OK in 
    windowed mode, but could do with some tweaking. One obvious way to improve 
    visuals and framerate quite a bit would be to encode the ground textures into 
    a buffer. I wasn't interested in the extra work this time around, but I will 
    get that done at a later date.


    
    Based on:
    
    // Athibaul has some really nice work on here. This is just
    // one of many worth looking at.
    Stone Circle - athibaul
    https://www.shadertoy.com/view/wstcDH
    
    // To my knowledge, there's only one other 3D Droste spiral shader on 
    // here featuring a 3D frame, but there might be others lurking around. 
    // Anyway, it's an awesome looking example. This one has mouse movement, 
    // which is pretty cool.
    Portal 1 - tmst 
    https://www.shadertoy.com/view/tl3GW2
    
    // 2D Droste spiral code. Easier to learn from.
    Droste Cyclic Expansion Spiral - Shane
    https://www.shadertoy.com/view/lcdcRM
    
    // It's a bit hard to post a Droste\Escher related example 
    // without referencing this awesome piece of work. :)
    Escher's prentententoonstelling - reinder 
    https://www.shadertoy.com/view/Mdf3zM
    
    // Not a 3D Droste spiral per se, but it's pretty cool and
    // is a Droste transformation of sorts... and it involves
    // Amiga nostalgia which will appease any demoscene fan. :)
    Tux is Worried - dr2
    https://www.shadertoy.com/view/tsfcRj
    
    
*/
////////

// Apply a Droste spiral transform to the scene. The scene without the
// transform applied 
#define DROSTE

// Far plane distance.
#define FAR 100.


// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }


// The cellular tile routine. Draw a few gradient shapes (six to eight spheres, in this 
// case)  using the darken (min(src, dst)) blend at various 3D locations on a cubic tile. 
// Make the tile wrappable by ensuring the objects wrap around the edges. That's it.
//
// Believe it or not, you can get away with as few as four spheres. Of course, there is 
// 8-tap Voronoi, which has the benefit of scalability, and so forth, but if you sum the 
// total instruction count here, you'll see that it's way, way lower. Not requiring a hash 
// function provides the biggest benefit, but there is also less setup.
// 
// The result isn't perfect, but 3D cellular tiles can enable you to put a Voronoi looking 
// surface layer on a lot of 3D objects for little cost. In fact, it's fast enough to 
// raymarch.
//
float drawSphere(in vec3 p){
    
    // Anything that wraps the domain will work.
    //p = cos(p*6.2831853)*.25 + .25; 
    //p = abs(cos(p*3.14159)*0.5);
    
    p = fract(p) - .5;    
    return dot(p, p);
   
    //p = abs(fract(p) - .5);
    //return dot(p, vec3(1)/sqrt(3.));
    

    //p = abs(fract(p) - .5);
    //return max(max(p.x, p.y), p.z);
 
    
}


// The same as above, but with an extra two spheres. This is used by the bump map function,
// which although expensive, isn't too bad. Just for the record, even bump mapping a
// reasonably fast cellular function, like 8-Tap Voronoi, can still be a drain on the GPU.
// However, the GPU can bump map this function in its sleep.
//
float cellTile2(in vec3 p){
    
    float c = .25; // Set the maximum.
    
    c = min(c, drawSphere(p - vec3(.81, .62, .53)));
    c = min(c, drawSphere(p - vec3(.39, .2, .11)));
    
    c = min(c, drawSphere(p - vec3(.62, .24, .06)));
    c = min(c, drawSphere(p - vec3(.2, .82, .64)));
    
    p *= 1.4142;
    
    c = min(c, drawSphere(p - vec3(.48, .29, .2)));
    c = min(c, drawSphere(p - vec3(.06, .87, .78)));

    c = min(c, drawSphere(p - vec3(.6, .86, .0)));
    c = min(c, drawSphere(p - vec3(.18, .44, .58)));
        
    return (c*4.);    
} 


float cellTile2nd(in vec3 p){ 
    
    vec3 d = (vec3(.75)); // Set the maximum, bearing in mind that it is multiplied by 4.
    //float c2 = .25;    
    
    // Draw four overlapping shapes (circles, in this case) using the darken blend 
    // at various positions on the tile.
    d.z = drawSphere(p - vec3(.81, .62, .53));
    d.y = max(d.x, min(d.y, d.z)); d.x = min(d.x, d.z);
    p.xy = vec2(p.y-p.x, p.y + p.x)*.7071;
    d.z = drawSphere(p - vec3(.39, .2, .11));
    d.y = max(d.x, min(d.y, d.z)); d.x = min(d.x, d.z);
    
    
    p.yz = vec2(p.z-p.y, p.z + p.y)*.7071;
     
   
    d.z = drawSphere(p - vec3(.62, .24, .06));
    d.y = max(d.x, min(d.y, d.z)); d.x = min(d.x, d.z);
    p.xz = vec2(p.z-p.x, p.z + p.x)*.7071; 
    d.z = drawSphere(p - vec3(.2, .82, .64));
    d.y = max(d.x, min(d.y, d.z)); d.x = min(d.x, d.z);

 

    return ((d.y) - (d.x))*2.66;
    //return (1.-sqrt(d.x)*1.33);    
}


// IQ's signed box formula.
float sBoxS(in vec2 p, in vec2 b, in float sf){

  vec2 d = abs(p) - b + sf;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - sf;
}

// Hash functions by Dave Hoskins.
// https://www.shadertoy.com/view/4djSRW
vec3 hash32(vec2 p){

	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

vec3 tri(vec3 p){ return abs(fract(p) - .5) - .25; }

// Global camera variables to orientate the viewing frame.
mat3 gCam;
vec3 gRo;
// Saving the global 3D coordinates.
vec3 gP;
// Object distances.
vec4 objD;


float map( vec3 p){

    // Saving the original unaltered coordinates.
    vec3 q0 = p;

    // Terrain deformation via coordinate perturbation.
    //p.y -= cos(p.z*.15) - cos(p.x*0.162);
    p.y += dot(sin(p.xz*.15 + sin(p.zx*.25)), vec2(1));
    
    // Repeat polar setup.
    float aNum = 12.; // Stone prism number.
    float rad = 4.12; // Radial distance.
  
    vec3 q = p;
    q.xz *= rot2(TAU/aNum); // Extra rotation to move into position.
    float a = atan(q.z, q.x)/TAU; // Angle.
    float ai = (floor(a*aNum) + .5)/aNum; // Angle ID.
    // Rotate.
    q.xz *= rot2(ai*TAU);
    
    // Clever way to put hidden wedges on the cell boudaries to ensure the 
    // rays don't encroach upon the next stone. There are more sophisticated
    // ways to do this, but it works here.
    float d = length(abs(q.xz) - rad*cos(TAU/aNum + vec2(0., -TAU/4.))) - 1.;
 
    
    // Random block size.
    vec3 blockSize = max(.2 + vec3(.5, .5, 1.5)*hash32(vec2(ai, 8)), .3);
    // Move out to the radial distance, and randomly move the stones up.
    q.xy -= vec2(rad, .25*blockSize.z);
  
    // Random tilt.
    float rnd = hash32(vec2(ai, 7)).x;
    q.xy *= rot2(floor(rnd*4.)/32.*6.2831);

    // Creating the stone prisms.
    vec3 pq = abs(q);
    // Hexagon: IQ's formula would be better, but this will do.
    float d2 = max(pq.z*.8660254 + pq.x*.5, pq.x); 
    //float d2 = sBoxS(pq.xz, vec2(.9), .6) + .9; // Hacky rounded square.
    //float d2 = length(pq.xz); // Round.
    float dPris = sBoxS(vec2(d2, pq.y), blockSize.xz, 0.);//, 
    //float dPris = max(d2 - blockSize.x, pq.y - blockSize.z);
    dPris += (max(d2, .2) - .5)*.75; // Beveled prism tops.
   
    
    // Surface deformation.
    vec3 q2 = p;
    q2.yz *= mat2(.5, .7, -.7, .5);
    float tn = dot(tri(q2/3. - tri(q2.zxy/2. + .6)), vec3(1.5)) - .5;
    dPris += .2*tn;
    
    float cellNoise = (cellTile2(p*1.03 + .35) - .75);
    dPris -= .1*cellNoise;
    d = min(d, dPris);
    
    // Extra subtle marks in the sand.
    p.y -= .025*cellNoise;
    
    d = min(d, p.y);
    
    // The Droste frame. There's a bit of an artform to getting it right. 
    // For now, I'm using a mixture of science and "magic" numbers, but at 
    // some stage I'll get in there and program it all correctly.
    #ifdef DROSTE
    vec3 qq = q0 - gRo*2./3.; // Relates to the FOV angle.
    qq = inverse(gCam)*(qq);
    // Droste frame distance metric. There are a few to choose from.
    float d2D = distMetric(qq.xy, vec2(scale*2.)); // Twice the Droste scale.
    d2D = abs(d2D);
    float obj = sBoxS(vec2(d2D, qq.z), vec2(.5, 2)/8., 0.);
    obj += d2D*.25; // Frame bevel.
    #else
    float obj = 1e5;
    #endif
    
    
    // Ground stones... I'm using a cellular algorithm that I wrote
    // years ago. It's great for realtime use, but I'd prefer to 
    // embed something into a repeat texture and use that. I was in
    // a hurry this time, plus I wanted to keep it simple.
    #if 1
    float groundRocks = .1 + tn*.2 + .25*sin(p.x*.7)*cos(p.z*.8 + 1.4) - 
                        .2*(cellTile2nd(p*1.5 + tn*.05 + .21) - .5);
    
    d = min(d, p.y + groundRocks);
    #endif
    
    // Saving the object distances for later.
    objD = vec4(d, obj, 1e5, 1e5);
 
    // Saving the coordinates for later... It's a bit wasteful doing
    // it here, but it's easier to tweak things in the map function.
    gP = p;
    
    // Minimum distance. Either the terrain or the frame.
    return d = min(d, obj);
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

 
// A rough version of XT95's ambient occlusion routine.
float calcAO(in vec3 p, in vec3 n){
 
	float sca = 2., occ = 0.;
    for(int i = 0; i<12; i++){
    
        float hr = .01 + (float(i))*.35/12.; 
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
// Athibaul's original shadow routine.
float softShadow( vec3 ro, vec3 rd, float softness, vec2 uv)
{
    float transm = 1.;
    float d, t = .01 + texelFetch(iChannel0, ivec2(mod(uv, 1024.)), 0).x*map(ro);
    for(int i=0; i<256; i++)
    {
        float w = softness*t;
        d = map(ro + t*rd);
        transm = min(transm, smoothstep(-w, w, d));
        if(transm<.01 || t>100.) break;
        t += d + w;
        //t += max(d, 0.02);
    }
    return transm;
}
*/

// The same as above, but modified from IQ's soft shadow forumula.
// Fewer iterations are being used in an attempt to speed thing up a bit.
float softShadow(in vec3 p, in vec3 ld, in float lDist, in float k, vec2 coo) {
    
    float res = 1.;
    float t = texelFetch(iChannel0, ivec2(mod(coo, 1024.)), 0).x*max(map(p), 0.);

    for (int i=0; i<96; i++){
   
        float d = map(p + ld*t);
        float w = t/k;
        res = min(res, smoothstep(-w, w, d));
        //res = min(res, k*d/t);
        if (res<.01 || t>lDist) break;
        
 
        t += max(d, .0) + w;//clamp(d, .02, .25);
    }
    
    return max(res, 0.);
}
 

// Slightly modified version of Nimitz's curve function. The tetrahedral and normal six
// tap versions are in there. If four taps gives you what you want, then that'd be the
// one to use.
//
// I think it's based on a discrete finite difference approximation to the continuous
// Laplace differential operator? Either way, it gives you the curvature of a surface, 
// which is pretty handy.
//
// Original usage (I think?) - Cheap curvature: https://www.shadertoy.com/view/Xts3WM
// Other usage: Xyptonjtroz: https://www.shadertoy.com/view/4ts3z2
//
// spr: sample spread, amp: amplitude, offs: offset.
float curve(in vec3 p, in float spr, in float amp, in float offs){

    float d = map(p);
    
    spr /= 450.;
    
    #if 0
    // Tetrahedral.
    vec2 e = vec2(-spr, spr); // Example: ef = .25;
    float d1 = map(p + e.yxx), d2 = map(p + e.xxy);
    float d3 = map(p + e.xyx), d4 = map(p + e.yyy);
    return clamp((d1 + d2 + d3 + d4 - d*4.)/e.y/2.*amp + offs + .5, 0., 1.);
    #else  
    // Cubic.
    vec2 e = vec2(spr, 0); // Example: ef = .5;
	float d1 = map(p + e.xyy), d2 = map(p - e.xyy);
	float d3 = map(p + e.yxy), d4 = map(p - e.yxy);
	float d5 = map(p + e.yyx), d6 = map(p - e.yyx);
    return clamp((d1 + d2 + d3 + d4 + d5 + d6 - d*6.)/e.x/1.5*amp + offs + .5, 0., 1.);
    
    //d *= 2.;
    //return 1. - smoothstep(-.05, .05, (abs(d1 + d2 - d) + abs(d3 + d4 - d) + 
    //                       abs(d5 + d6 - d))/e.x/2.*amp + offs + .0);
    #endif

}


void mainImage(out vec4 fragColor, in vec2 fragCoord){

   
    // Screen coordinates.
    vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
     
    // Tripping things out even more... A little too Salvador Dalí for me. :)
    //uv *= 1. - dot(uv, uv)*.2;
    
    // Applying the Droste transformation.
    #ifdef DROSTE
    uv = DrosteTransform(uv, iTime/2.);
    #endif

    // Camera setup.
    float th = .25*asin(.9*sin(.25*iTime));
    vec3 lk = vec3(0);
    vec3 ro = vec3(10.*sin(th), 1.5, 10.*cos(th));
    vec3 fwd = normalize(lk - ro);
    vec3 rgt = normalize(cross(vec3(0, 1, 0), fwd));// Right. 
    vec3 up = cross(fwd, rgt); // Up.    
    float FOV = 3.14159/3.;
    
    // Camera and unit direction ray.
    mat3 cam = mat3(rgt, up, fwd);
    vec3 rd = cam*normalize(vec3(uv, 1./FOV));
    
    // Global camera and origin. Used in the map function to
    // render the Droste spiral frame.
    gCam = cam;
    gRo = ro;
    
    
    // Raymarching.
    float d, t = 0.;
    for(int i=0; i<160; i++){
    
        d = map(ro + rd*t);
        if(abs(d)<.001 || t>FAR) break;
        t += d*.7;
    }
    
    t = min(t, FAR);
    
    // Object ID.
    int objID = objD.x<objD.y? 0 : 1;
    
    // Perturbed terrain coordinates.
    vec3 svGP = gP;
    
    
    // Simple but effective sky routine. No mie calculations
    // were harmed during the making of this. :D
    vec3 skyCol = vec3(.4, .5, .8); // Sky color.
    vec3 sunDir = normalize(vec3(1, .1, -1)); // Direction.
    vec3 sunCol = vec3(1, .25, .1); // Sunset
    
    // Adding the sun.
    vec3 rdMod = normalize(vec3(rd.xz + sunDir.xz, rd.y*5.));
    skyCol += sunCol*pow(clamp(dot(rdMod, sunDir), 0., 1.), 10.)*.6; 
    skyCol += 5.*sunCol*pow(clamp(dot(rd, sunDir), 0., 1.), 10000.); // Sun center.
 
    // Initialize to the sky color.
    vec3 col = skyCol;
    
    // If we've hit something, color it.
    if(t<FAR){
      
        // Position and normal.
        vec3 p = ro + t*rd;
        vec3 n = normal(p);
    
        // Ambient occlusion.                  
        float ao = calcAO(p, n);
        
        // Shadows,
        //float sh = softShadow(p + .002*n, sunDir, .1, fragCoord);
        float lDist = FAR;
        float sh = softShadow(p + n*.0015, sunDir, lDist, 16., fragCoord);
        
        // Scene curvature.
        float spr = 6., amp = 1., offs = .0;
        float crv = curve(p, spr, amp, offs);
      
        // Ground based stone and sand coloring.
        vec3 sandCol = vec3(.35, .35, .2);
        vec3 stoneCol = vec3(.3, .315, .33);
        vec3 surfCol = mix(sandCol, stoneCol, smoothstep(0., .05, svGP.y));
 
        // Apply the shadows and coloring.
        col = sunCol*surfCol*sh*8.;
        col += sunCol*skyCol*(.5 + .5*n.y)*ao*.5;
        // Backfill color.
        vec3 fillDir = vec3(-sunDir.xz, 0.);
        vec3 fillCol = sunCol*sandCol*.05;
        col += fillCol * clamp(dot(n, fillDir), 0., 1.)*4.;
       
        // Adding some sky reflection.
        if(objID==1) col += skyCol*(.25*sh*sunCol + .25*(ao + .5));                  
        else col += skyCol*(.25*sh*sunCol + .25*(ao + .5))/3.;
        
    
        col *= crv  + .5; // Curvature.
        //col *= 1. - abs(crv - .5)*2.*.5; // Dark lines.
        
      
    }
    
    
    // Apply some fog.
    float fog = 1. - exp(-.02*max(t - 10., 0.));
    col = mix(col, skyCol, fog);


    // Extra foreground sun. 
    col += sunCol * pow(clamp(dot(rd, sunDir),0.,1.), 8.);

    // Tone mapping. Thanks, Chronos. :)
    col = mix(col, 1. - 1./(col*col*27./4.), step(2./3., col));

    // Rough gamma correction.
    fragColor = vec4(pow(max(col, 0.), vec3(1./2.2)), 1);
    
}