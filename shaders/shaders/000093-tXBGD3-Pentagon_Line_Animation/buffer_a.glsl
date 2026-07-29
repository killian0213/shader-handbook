// Buffer A (buffer) — Pentagon Line Animation by Shane
// https://www.shadertoy.com/view/tXBGD3

/*

    Pentagon Line Animation
    -----------------------
    
    This is based on a pretty common animation that involves crcles and lines
    rotating within larger circles. There are so many variations, of which
    this is just one. I wrote a 2D version ages ago, and couldn't think of a
    decent way to present it until recently... I'm not sure what influenced the 
    theme, but I have been watching one of the Star Wars series, so probably 
    that. :)
    
    I'm not sure why, but I initially expected this animation to be annoying to
    code. However, it turned out to be reasonbly easy, which was a pleasant
    surprise. In the end, I spent more time choosing a background pattern than 
    I did writing the distance function. It took me a while to realize that a
    background pattern will never look quite right on a polar mapped scene, 
    unless it's also polar mapped. :)    
    
    There's a pretty cool way to map the paths of the rotating lines perfectly,
    in order to create the concave pentagon holes. It involves keeping track of 
    three equispaced smaller circles rotating within the larger circle. However,
    I wanted to keep things simple, so I used a central pentagon in unison with
    some carved out closely approximated superelliptical boundaries.
    
    The character count isn't what I'd call small, but virtually all of it 
    consists of add-on functions -- like testure and function bump mapping, post
    processing, curvature, and so forth. Each are small enough on their own, but
    when you put them altogether, it tends to blow out the character count. 
    Having said all that, for anyone who's coded things with 100 thousand lines
    or more, it's still pretty small. Plus, you don't have to sift through three 
    gazillion GitHub files just to find that one section you're interested in. :)
    

    
    Other examples:
    
    // The pentagon objects I created used a very hacky process.
    // Here's a much nicer way to make similar objects.
    Deltoid SDF - SnoopethDuckDuck 
    https://www.shadertoy.com/view/wXBGzD
    
    // A keyframed line animation.
    Synchronized Line Animation - Shane
    https://www.shadertoy.com/view/flj3Wm
    
    // I love demonstations like these... I've been meaning to make a 
    // circuit example using similar techniques.
    pseudo-Tron screensaver -- FabriceNeyret2 
    https://www.shadertoy.com/view/wly3DW
    
*/





// Global tile scale.
vec2 scale = vec2(1./8.);

// Max ray distance.
#define FAR 20.


// Scene object ID.
float objID;
 

/////////////////////////////

// Tri-Planar blending function: Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: http://http.developer.nvidia.com/GPUGems3/gpugems3_ch01.html
vec3 tex3D(sampler2D tex, in vec3 p, in vec3 n){    
    
    // Abosolute normal with a bit of tightning.
    n = max(n*n - .2, .001); // max(abs(n), 0.001), etc.
    n /= dot(n, vec3(1)); 
    //n /= length(n); 
    
    // Texure samples. One for each plane.
    vec3 tx = texture(tex, p.zy).xyz;
    vec3 ty = texture(tex, p.xz).xyz;
    vec3 tz = texture(tex, p.xy).xyz;
    
    // Multiply each texture plane by its normal dominance factor.... or however you wish
    // to describe it. For instance, if the normal faces up or down, the "ty" texture 
    // sample, represnting the XZ plane, will be used, which makes sense.
    
    // Textures are stored in sRGB (I think), so you have to convert them to linear space 
    // (squaring is a rough approximation) prior to working with them... or something like
    // that. :) Once the final color value is gamma corrected, you should see correct 
    // looking colors.
    return mat3(tx*tx, ty*ty, tz*tz)*n;
}

// Unsigned distance to the segment joining "a" and "b".
float distLine(vec2 p, vec2 a, vec2 b){

    p -= a; b -= a;
    float h = clamp(dot(p, b)/dot(b, b), 0., 1.);
    return length(p - b*h);
}


// IQ's extrusion formula.
float opExtrusion(in float sdf, in float pz, in float h){
    
    vec2 w = vec2( sdf, abs(pz) - h );
  	return min(max(w.x, w.y), 0.) + length(max(w, 0.));

    /*
    // Slight rounding. A little nicer, but slower.
    const float sf = .015;
    vec2 w = vec2( sdf, abs(pz) - h - sf/2.);
  	return min(max(w.x, w.y), 0.) + length(max(w + sf, 0.)) - sf;
    */
}

// IQ's signed distance to a regular pentagon.
// https://www.shadertoy.com/view/llVyWW
float sdPentagon(in vec2 p, in float r )
{
    const vec3 k = vec3(.809016994, .587785252, .726542528); // pi/5: cos, sin, tan
    p.y = -p.y;
    p.x = abs(p.x);
    p -= 2.*min(dot(vec2(-k.x, k.y), p), 0.)*vec2(-k.x, k.y);
    p -= 2.*min(dot(vec2( k.x, k.y), p), 0.)*vec2( k.x, k.y);
	//p -= vec2(clamp(p.x,-r*k.z,r*k.z),r);
    p.x = abs(p.x);
    p -= vec2(min(p.x, r*k.z), r); 
    return length(p)*sign(p.y);
}


// Glow.
vec3 glow;
// 2D value.
float gD2D;
// Line object ID.
vec2 gID;


// The distance function... This is based on old code I hacked together ages
// ago. Not my finest work, but it does the job. :)
float map(vec3 p3){
    
    // Floor.
    float fl = -p3.z;
       
    // Rotation.
    vec2 p = rot2(iTime/16.)*p3.xy;
  
    // Scene field calculations.
    gID.x = 0.;
    
    // Using polar repetition to create five more pentagon
    // objects around the center one. 
    if(length(p)>.5){
        float aN1 = 5.;
    
        p *= rot2(-TAU/20. - iTime/6.*0.);
      
        float a1 = atan(p.y, p.x)/TAU;
        gID.x = mod(floor(a1*aN1), aN1) + 1.;

        float ia1 = (floor(a1*aN1) + .5)/aN1;
        
        p = rot2(ia1*TAU)*p;
        float ix = floor(p.x/1.8);
        p.x -= (ix + .5)*1.8;
        p *= rot2(TAU/20.);
    } 

    // The little regular pentagon in the center.
    float pentagon = sdPentagon(rot2(TAU/10.)*p, .115);
   
    
    float rL = .4; // Large radius.
    float rad = rL*2./3.;
    
    // Scene object.
    float dd = length(p) - rL;
    
    // Five surrounding superelliptical arcs. Each will form the concave boundaries.
    float aN = 5.;
    vec2 q = rot2(TAU/aN/4.)*p;
   
    float a = atan(q.y, q.x)/TAU;
    float ia = (floor(a*aN) + .5)/aN;
    q = rot2(ia*TAU)*q;
    q.x -= rL*2.*2.5;
    // Superelliptical curve.
    float d2 = pow(dot(pow(abs(q), vec2(1.5)), vec2(1)), 1./1.5) - (rL*2.*2.5 - rad + .02);
    
    dd = smax(dd, -d2, .015*0.); // Curved pentagon borders.
    dd -= .035;
    
    // Adding the small pentagon to the carved out larger pentegon. 
    float d3 = max(dd, pentagon);
     
    // Hole depth.
    float h = .06;
    
    // Floor pentagon object.
    float pent = opExtrusion(dd, p3.z + h/2.*0., h/2.);
    pent = smax(pent, -d3, .015*0.); // Central pentagon.
   
    // Global used for bump mapping. This includes the surrounding floor,
    // but the not the recessed star sections.
    gD2D = -dd + .03;
    //gD2D = -pent + .03;
    //gD2D = 1e5;
    //gD2D = -min(abs(dd - .015) - .015, abs(pentagon + .015) - .015);//
   
    // Carving the pentagons out of the floor.
    fl = smax(fl, -pent + .005, .015*0.);
    fl = max(fl, -max(abs(pent - .03) - .005, fl - .0015));
    

    
    
//////////

     
    // Circle path.
    float cir = length(p) - rad;
    cir = abs(cir);// - .005;
    // Adding it to the floor.
    fl = max(fl, -max(cir - .005, p3.z - .04));

    
    // Rotating lines and vertices.
    vec3 vert3;
    float minD = 1e5;
    
    // Create three lines rotating in a circle, whilst spinning about 
    // each lines center of mass.
    for(int i = 0; i<3; i++){
        
        float t = iTime*.75;
        vec2 p0 = rot2(t + TAU/3.*float(i) + float(i)*.172 - gID.x*.065)*
                       vec2(0, 1)*(rad - .0);
        float pnt = length(p - p0) - .015;
    
        vec2 q2 = p - p0;
        q2 = rot2(t*3./2. + float(i)*.172*3./2. - gID.x*.065*3./2.)*q2;
        
        // Line distance.
        float ln = distLine(q2, vec2(0, -(rL - rad)),  vec2(0, (rL - rad)));
        
        // Minimum distance and ID for the closest line.
        if(ln<minD){ minD = ln; gID.y = float(i); }
        
        // Vertices.
        vert3[i] = length(q2);
   
    }    
    
    
    // Constructing the extruded lines.
    float ln2 = minD - .015;
    float v = min(min(vert3.x, vert3.y), vert3.z) - .016;
    // Hole depth: .1;
    h = .02;
    float d = opExtrusion(ln2, p3.z - (.06 - .02)/2. + h/2.*0., h/2.);
    
    
    // Adding colored glow to each lines.
    float rnd = hash21(gID + .13);
    vec3 gCol = .5 + .45*cos(TAU*rnd/12. + vec3(0, 1, 2)*1. - .0);
    gCol *= sqrt(gCol);
    // Individual line glow color.
    if(gID.y==2.) gCol = gCol.xzy;
    else if(gID.y==1.) gCol = gCol.zyx;
    else gCol = mix(gCol, gCol.xzy, .35);
    // Apply the glow.
    if(d<.1) glow += gCol/max(d*d, .001)/100.;
    
    // Add the central line vertices.
    d = min(d, opExtrusion(v, p3.z - (.06 - .02)/2. + h/2.*0., h/2. + .01));
    
    
  
    // Overall object ID.
    objID = fl<d? 1. : 0.;
    
    // Combining the floor with the extruded object.
    return  min(fl, d);
 
}

 
// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    // Overall ray distance and scene distance.
    float d, t = hash31(ro + rd*.577 + fract(iTime))*.15;
    
    glow = vec3(0);
    
    for(int i = min(0, iFrame); i<96; i++){
    
        d = map(ro + rd*t);
        if(abs(d)<.001 || t>FAR) break;  
        
        t += min(d*.7, .25); 
    }

    return min(t, FAR);
}


// Standard normal function. It's not as fast as the tetrahedral calculation, 
// but more symmetrical.
vec3 getNormal(in vec3 p, float t) {
	
    //const vec2 e = vec2(.001, 0);
    //return normalize(vec3(map(p + e.xyy) - map(p - e.xyy),
    //                      map(p + e.yxy) - map(p - e.yxy),	
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


// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with 
// limited iterations is impossible... However, I'd be very grateful if someone could 
// prove me wrong. :)
float softShadow(vec3 ro, vec3 lp, vec3 n, float k){

    // More would be nicer. More is always nicer, but not always affordable. :)
    const int maxIterationsShad = 32; 
    
    ro += n*.0015; // Coincides with the hit condition in the "trace" function.
    vec3 rd = lp - ro; // Unnormalized direction ray.
    

    float shade = 1.;
    float t = 0.; 
    float end = max(length(rd), .0001);
    //float stepDist = end/float(maxIterationsShad);
    rd /= end;
    

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. 
    // Obviously, the lowest number to give a decent shadow is the best one to choose. 
    for (int i = min(iFrame, 0); i<maxIterationsShad; i++){

        float d = map(ro + rd*t);
        
        
        shade = min(shade, k*d/t);
        //shade = min(shade, smoothstep(0., 1., k*h/dist)); // Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += min(h, .2), 
        // dist += clamp(h, .01, stepDist), etc.
        t += clamp(d, .005, .15); 
        
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (d<0. || t>end) break; 
    }

    // Shadow.
    return max(shade, 0.); 
}


// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.

// For anyone not familiar with the process, the idea of the function is to very 
// roughly approximate the self shadowing that occurs around a surface when light 
// is being bounced all over the place. In particular, it marches out from the 
// surface in the direction of the surface normal, then determines the overall light
// occlusion based on how far the ray is from any given surface. It also factors in 
// how far away the ray is from orginating surface point itself. You can see all that 
// in the workings.
float calcAO(in vec3 p, in vec3 n){

	float sca = 3., occ = 0.;
    for( int i = 0; i<5; i++ ){
    
        float hr = float(i + 1)*.25/5.;        
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
    }
    
    return clamp(1. - occ, 0., 1.);  
}

// Texture bump mapping. Four tri-planar lookups, or 12 texture lookups in total. 
// I tried to make it as concise as possible. Whether that translates to speed, 
// or not, I couldn't say.
vec3 texBump( sampler2D tx, in vec3 p, in vec3 n, float bf){
   
    const vec2 e = vec2(.001, 0);
    
    // Three gradient vectors rolled into a matrix, constructed with offset greyscale 
    // texture values.    
    mat3 m = mat3(tex3D(tx, p - e.xyy, n), tex3D(tx, p - e.yxy, n), 
                  tex3D(tx, p - e.yyx, n));
    
    vec3 g = vec3(.299, .587, .114)*m; // Converting to greyscale.
    g = (g - dot(tex3D(tx,  p , n), vec3(.299, .587, .114)))/e.x; 
    
    // Adjusting the tangent vector so that it's perpendicular to the normal -- Thanks 
    // to EvilRyu for reminding me why we perform this step. It's been a while, but I 
    // vaguely recall that it's some kind of orthogonal space fix using the Gram-Schmidt 
    // process. However, all you need to know is that it works. :)
    g -= n*dot(n, g);
                      
    return normalize( n + g*bf ); // Bumped normal. "bf" - bump factor.
	
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
    

    // By the way, I take a lot of liberties with this part of the formula. 
    // Dividing by the sample-spread squared (e.x*e.x) is technically correct, 
    // but I'll sometimes divide by other things to get the result I want.
    //
    //return clamp((d1 + d2 + d3 + d4 + d5 + d6 - d*6.)/e.x*amp + offs + .05, 0., .1)/.1;
    return smoothstep(-.05, .05, (d1 + d2 + d3 + d4 + d5 + d6 - d*6.)/e.x/2.*amp + offs);
    
    #endif

}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    
    // Screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
    
    // Screen warp.
    //uv *= .95 + dot(uv, uv)*.1;

    tm = iTime;
    
	// Camera Setup.
    vec3 ro = vec3(cos(iTime/4.)*.0 - .2, sin(iTime/4.)*.1 - .7, -1.5); // Camera position, doubling as the ray origin.
	vec3 lk = vec3(-.05, -.1, 0);//vec3(0, -.25, iTime);  // "Look At" position.
 
    // Light positioning. One is just in front of the camera, and the other is in front of that.
 	vec3 lp = lk + vec3(1, 1, -.7);// Put it a bit in front of the camera.
	

    // Using the above to produce the unit ray-direction vector.
    float FOV = .75; // FOV - Field of view.
    vec3 fwd = normalize(lk - ro); // Forward.
    //if(dot(fwd, vec3(fwd.z, 0, -fwd.x))==0.) fwd = normalize(fwd - vec3(0, 0, .00001));
    vec3 rgt = normalize(cross(vec3(0, 1, 0), fwd));// Right. 
    // "right" and "forward" are perpendicular normals, so the result is normalized.
    vec3 up = cross(fwd, rgt); // Up.
    
    // Camera.
    //mat3 mCam = mat3(rgt, up, fwd);
    // rd - Ray direction.
    //vec3 rd = mCam*normalize(vec3(uv, 1./FOV));//
    vec3 rd = normalize(uv.x*rgt + uv.y*up + fwd/FOV);
 
    
    // Raymarch to the scene.
    float t = trace(ro, rd);
    
    // Save the object ID, 2D distance and line ID.
    float svObjID = objID;
    float svD2D = gD2D;
    vec2 svID = gID;
    
    vec3 svGlow = glow; // Glow.
  
	
    // Initiate the scene color to black.
	vec3 col = vec3(0);
	
	// The ray has effectively hit the surface, so light it up.
	if(t < FAR){
        
  	
    	// Surface position and surface normal.
	    vec3 sp = ro + rd*t;
        vec3 sn = getNormal(sp, t);
        
        // Function based bump mapping.
        if(svObjID>.5 && svD2D<0.)  sn = doBumpMap(sp, sn, .25);
        
        
        if(svObjID>.5){
        
            vec3 txP = sp;
            vec3 txN = sn;
            txP.xy = rot2(iTime/16.)*txP.xy;
            txN.xy = rot2(iTime/16.)*txN.xy;
        
            // Texture base bump mapping.
            sn = texBump(iChannel0, txP*2., txN, .01);///(1. + t/FAR)
 
        }
        
        // Light direction vector.
	    vec3 ld = lp - sp;
 

        // Distance from respective light to the surface point.
	    float lDist = max(length(ld), .001);
    	
    	// Normalize the light direction vector.
	    ld /= lDist;

        
        
        // Shadows and ambient self shadowing.
    	float sh = softShadow(sp, lp, sn, 16.);
    	float ao = calcAO(sp, sn); // Ambient occlusion.
        //sh = min(sh + ao*.25, 1.);
        
        // Scene curvature.
        float spr = 2., ampC = 1., offs = .0;
        float crv = curve(sp, spr, ampC, offs);

	    
	    // Light attenuation, based on the distances above.
	    float atten = 1./(1. + lDist*.05);

    	
    	// Diffuse lighting.
	    float diff = max( dot(sn, ld), 0.);
       
    	// Specular lighting.
	    float spec = pow(max(dot(reflect(ld, sn), rd ), 0.), 32.); 
	    
	    // Fresnel term. Good for giving a surface a bit of a reflective glow.
        //float fre = pow(clamp(1. - abs(dot(sn, rd))*.5, 0., 1.), 2.);
        
		// Schlick approximation. I use it to tone down the specular term. 
		float Schlick = pow( 1. - max(dot(rd, normalize(rd + ld)), 0.), 5.);
		float freS = mix(.15, 1., Schlick);  //F0 = .2 - Glass... or close enough. 
        
          
        // Obtaining the texel color. 
	    vec3 texCol; 
        
        vec3 txP = sp;
        float sf = 1.5/iResolution.y;
        float ew = .003;

       
        if(svObjID<.5){
            
            // Line objects.
            
            mat3x3 lCol = mat3x3(vec3(1, .2, .4), vec3(1, .4, .2), vec3(.4, .2, 1));
   
            
            float rnd = hash21(svID + .13);
            texCol = .5 + .45*cos(TAU*rnd/12. + vec3(0, 1, 2));
            texCol *= 2.;
              
            if(svID.y==2.) texCol = texCol*1.2;//.xzy*vec3(1, 3, .5);
            else if(svID.y==1.) texCol = texCol.zyx*vec3(2.5, 1, 1.5);
            else texCol = texCol*vec3(1, 1.5, 3.5);//texCol.yxz*vec3(.7, .7, 2);
         
            // Darken the sides of the line objects.
            texCol = mix(texCol, texCol*.2, abs(sn.y));
            
            float d = abs(svD2D) - ew;
            float h = .2; // Object height.
            d = max(d, abs(txP.z + h) - ew);
            
            texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, d)); 
      
            if(sp.z<.002){ texCol = vec3(.2); diff = pow(diff, 4.)*2.; }
            else diff *= .2;
            
        
        }
        else {
            
            
            // The floor pattern.
 
            // Ground rim.
            float d = abs(svD2D) - ew*1.5;
            texCol = mix(vec3(.2, .15, .1), vec3(0), 1. - smoothstep(0., sf, d)); 
            
            // Darkening the recessed flooring a touch.
            if(sp.z>0.) texCol *= .7;
            
            // Texture.
            vec3 txP = sp;
            vec3 txN = sn;
            txP.xy = rot2(iTime/16.)*txP.xy;
            txN.xy = rot2(iTime/16.)*txN.xy;
            vec3 tx = tex3D(iChannel0, txP, txN);
            texCol *= tx*3.;
            
            
            diff = pow(diff, 4.)*2.; // Ramping up the diffuse.
    	
          
        }
        
        
        
        // Cheap specular reflections.
        float speR = pow(max(dot(normalize(ld - rd), sn), 0.), 5.);
        vec3 rf = reflect(rd, sn); // Surface reflection.
        vec3 rTx = texture(iChannel1, rf).xyz; rTx *= rTx;
        texCol = texCol + texCol*speR*rTx*.5;
        
 
        // Apply the glow.
        texCol *= 1. + svGlow/12.;
  
       
        // Combining the above terms to produce the final color.
        col = texCol*(diff*sh + .3 + vec3(1, .97, .92)*spec*freS*2.*sh);
        
        // Edge darkening, depending on object.
        float lF = svObjID<.5? .9 : .5;
        col *= 1. - abs(crv - .5)*2.*lF;
      
        // Shading.
        col *= ao*atten;
        
        // It's sometimes helpful to check things like shadows and AO by themselves.
        //col = vec3(ao);
          
	
	}
    
    // Horizon fog. Not visible here, but provided for completeness.
    col = mix(col, vec3(0), smoothstep(0., .99, t/FAR));
          
    
    // Rought gamma correction.
	fragColor = vec4((max(col, 0.)), t);
	
}