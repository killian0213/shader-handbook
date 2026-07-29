// Buffer A (buffer) — Semi-regular 3,3,4,3,4 Extrusion by Shane
// https://www.shadertoy.com/view/DllSWB

/*

    Semi-regular 3,3,4,3,4 Extrusion
    --------------------------------
    
    This is a semi-regular 3,3,4,3,4 tiling in variable height extruded form. I like 
    the overlapping elliptical nature of the pattern. The 2D version isn't what I'd 
    call common in the real world, but thanks to math people who like to code, you'll 
    see it a lot in the 2D graphics world. Oddly enough, the extruded quasi 3D form 
    is not common at all. In fact, I couldn't find an example anywhere. I've noticed 
    this for virtually all semi-regular tilings, which I find perplexing for various 
    reasons... I'll put it down to the mysteries of the graphics world. :)
    
    Anyway, I have an almost unhealthy compulsion to drag a 2D pattern off the plane, 
    so I'm slowly growing a collection of extruded semi-regular arrangements on 
    Shadertoy. Like the previous pattern, I coded it up quickly in order to get the 
    job done, so I'd imagine there'd be better ways to do it.
    
    I wasn't feeling very creative when it came to presentation, so I attempted to 
    dress the scene up with a few graphics cliches and post processing. Post
    processing algorithms are mostly common sense, and easy to put together, provided
    you can use a lot of samples. Unfortunately, slower machines don't like that, so
    I've attempted to write some lower sampled ones, which are not ideal. They're
    OK for this... Kind of. The 25 tap DOF isn't too bad, but the hacky bokeh routine
    is not my best work. :) By the way, if you know of ways to make those functions
    better, feel free to let me know.
    
    
    
    Related examples:
    
    // I like this example, since it's a simple 2D semi-regular tiling 
    // visual reference. The floret pattern is contained in it somewhere.
    Wythoff Uniform Tilings + Duals - Fizzer 
    https://www.shadertoy.com/view/3tyXWw
    
    // Hyperbolic semi-regular tilings. A really nice example. As an aside,
    // I have an extruded hyperbolic regular tiled example somewhere.
    Wythoffian Tiling Generator - mla
    https://www.shadertoy.com/view/wlGSWc
    
    // An unlisted 2D parallelogram grid example that, hopefully, will 
    // show roughly how the pattern was made.
    Parallelogram Grid - Shane 
    https://www.shadertoy.com/view/dlBSRG
    
    
*/


#define FAR 40.

// Animate the pattern. By rotating respective tile angles, it's possible
// to change the packing arrangement.
//#define ANIMATE


#ifndef ANIMATE
// I didn't arrange for holes to work during animation -- I may fix that later. You 
// can comment out the following line and override the holes entirely, if desired.
#define HOLES
#endif



// IQ's vec2 to float hash.
float hash21(vec2 p){ return fract(sin(dot(p, vec2(117.619, 57.623)))*43758.5453); } 

// IQ's vec2 to float hash.
float hash31(vec3 p){  
    return fract(sin(dot(p, vec3(113.619, 57.583, 27.897)))*43758.5453); 
}


// Standard 2D rotation formula.
mat2 r2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// Tri-Planar blending function. Based on an old Nvidia tutorial by Ryan Geiss.
vec3 tex3D(sampler2D t, in vec3 p, in vec3 n){ 

    
    n = max(abs(n) - .2, 0.001); // max(abs(n), 0.001), etc.
    //n /= dot(n, vec3(1)); 
    n /= length(n);
    
	vec3 tx = texture(t, p.yz).xyz;
    vec3 ty = texture(t, p.zx).xyz;
    vec3 tz = texture(t, p.xy).xyz;
    
    // Textures are stored in sRGB (I think), so you have to convert them to linear space 
    // (squaring is a rough approximation) prior to working with them... or something like that. :)
    // Once the final color value is gamma corrected, you should see correct looking colors.
    return mat3(tx*tx, ty*ty, tz*tz)*n;
}


// Commutative smooth maximum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smax(float a, float b, float k){

   float f = max(0., 1. - abs(b - a)/k);
   return max(a, b) + k*.25*f*f;
}

// Signed distance to a line passing through "a" and "b".
float distLineS(vec2 p, vec2 a, vec2 b){

   b -= a; 
   return dot(p - a, vec2(-b.y, b.x)/length(b));
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


// IQ;s signed distance to an equilateral triangle.
// https://www.shadertoy.com/view/Xl2yDW
float getTri(in vec2 p, in float r){

    const float k = sqrt(3.0);
    p.x = abs(p.x) - r;
   
    p.y = p.y + r/k; 
    if(p.x + k*p.y>0.) p = vec2(p.x - k*p.y, -k*p.x - p.y)/2.;
    p.x -= clamp(p.x, -2.*r, 0.);
    return -length(p)*sign(p.y);
   
    /*   
    const float k = sqrt(3.0);
    p.y = abs(p.y) - r; // This one has been reversed.
    p.x = p.x + r/k;
    if( p.y + k*p.x>0.) p = vec2(-k*p.y - p.x, p.y - k*p.x)/2.0;
    p.y -= clamp( p.y, -2.0, 0.0 );
    return -length(p)*sign(p.x);
    */  
}

// Pylon height function.
float hMap(vec2 p){
    return hash21(p)*.1 + .025;// + (dot(sin(p.xy*2. - cos(p.yx*4.)*2.), vec2(.25)) + .5)*.15;     
}

vec4 gVal;
//vec3 glow, lCol; // Global glow and glow color variables.


float m(vec3 p){
   
 
    // The floor.
    float fl = -p.z;
    
    
    
    // The semi-regular 3,3,4,3,4 extrusion. By the way, for anyone not familiar with
    // the nomenclature process, choose any vertex, then count the number of shapes
    // that surround it -- In this case, you'll see that it is five. Now list the number
    // of vertices for each shape, then put them in order from smallest (including repeats)
    // to largest. In this case it'll be, triangle, triangle, square, triangle, square,
    // which have vertex numbers, 3,3,4,3,4. Simple... Well, I get it wrong all the time,
    // but it's still a simple process. :D
    
    // Scaling variables.
    float sc = 1./4.5, s = sc*2.;
    
    #ifdef ANIMATE
    // Variable angle. This will work, but the holes will need to be removed.
    float ang = atan(1., 2.)*(cos(iTime*.5)*.5 + .25);//
    #else
    // The angle necessary to make the squares and equilateral triangles pattern...
    // I can't remember how I came up with it... I probably used math. :D
    float ang = atan(1., 4.);
    #endif
    // h = 1./cos(ang) = R*(1. + sqrt(3.)/2.);
    // => R = 1./cos(ang)/(1. + sqrt(3.)/2.);
    //float dim = 1./sin((3.14159/2. + ang))/4.;
    
    // The dimensions of the two squares and the two skewed squares (parallelograms).
    // The two parallelograms are split along the diagonal to form triangles.
    float dim = 1./cos((ang))/2.;
    float dim2 = dim*cos(ang*2.);
    mat2 matA = r2(ang);
    mat2 matB = r2(-ang);
    
    float d = 1e5;
    const mat4x2 offs = mat4x2(vec2(-.25), vec2(-.25, .25), vec2(.25), vec2(.25, -.25));
    
    // Rendering four objects per pass, two of which are split down the center, so 
    // that's six all up.
    for(int i = min(0, iFrame); i<4; i++){
    
        // Local coordinats and ID.
        vec2 q = p.xy;
        vec2 iq = floor(q/s - offs[i]) + .5; // Local tile ID.
        
        // Correct positional individual tile ID.
        vec2 idi = (iq + offs[i])*s;
        
        q -= idi; // New local position.
        
        
        // Rotating q by two different matrices. Mixing the coordinates will produce
        // two squares and two skewed parallelograms, which will be split across the
        // diagonal to form triangles.
        vec2 qA = matA*q, qB = matB*q;

        // This forms the 2D coordinates for four parallelograms -- Two are mutually
        // perpendicular (qr = qA and qr = qB), so remain square. The other two
        // coordinate sets are mixed, so will be skewed... It's a simple trick that I
        // take for granted in situation like this, and is handy to know.
        vec2 qr = vec2((i==0 || i ==3)? qA.x : qB.x, i<2? qA.y : qB.y);
        
         
        // Edge width and smoothing factor.
        const float ew = .003, sm = .035; 
        float dm = ((i&1)==0)? dim : dim2;
        qr = abs(qr) - dm*sc + sm + ew;
        // 2D parallelogram (or square) distance. Most certainly not a correct distance,
        // field but it passes the visual test, so it's fine for this demonstration.
        float d2 = min(max(qr.x, qr.y), 0.) + length(max(qr, 0.)) - sm; 
       
       
        vec2 tOffs = i==1 || i==2? vec2(1) : vec2(-1, 1);
        vec2 idOffs = tOffs*(.7071 + sin(ang)*dim)/4.;
        
        float d3, h;
        
        if(i==0 || i==2){
            // The two squares.
            
            if(i==0) tOffs *= 0.;
            
            #ifdef HOLES
            // Bore out random holes.
            if(hash21(idi + .03)<.35){ 
                float hlSz = (hash21(idi - tOffs*s/2. + .04)*.2 + .2)*sc;
                 d2 = max(d2, -(d2 + hlSz));//abs(d2 + .125) - .125;  
                //d2 = max(d2, -(length(q) - hlSz/2.5));//abs(d2 + .125) - .125;  
            }
            #endif
        
           
            h = hMap(idi - tOffs*s/2.); // Prism height.
            d3 = opExtrusion(d2, p.z + h/2., h/2.);  // Prism.
            d3 += d2*.1; // Face slope. 
        }
        else {
            
        
            // Splitting the parallelograms across the diagonal to 
            // create two triangles.
            
            // Triangle dividing line.
            float triLn;
            if(i==1) triLn = distLineS(q, vec2(-1, 1)*dim*sc/2., vec2(1, -1)*dim*sc/2.);
            else triLn = distLineS(q, vec2(0), vec2(1)*dim*sc/2.);
            
            float d2B = smax(d2, triLn + ew, sm);
            d2 = smax(d2, -triLn + ew, sm);
            
            
            #ifdef HOLES
             // Bore out random holes.
            if(hash21(idi - tOffs*s/4. + .03)<.35){ 
                float hlSz = (hash21(idi - tOffs*s/4. + .04)*.25 + .25)*sc;
                //d2 = max(d2, -(d2 + hlSz));//abs(d2 + .125) - .125;  
                //d2 = max(d2, -(length(q - r2(dir*3.14159/4.)*vec2(sc*.31, 0)) - hlSz/4.));
                //d2 = max(d2, -(length(q - tOffs*(.7071 + sin(ang)*dim)*sc/4.) - hlSz/3.5));
                
                // Triangle holes.
                vec2 qrr = q - tOffs*(.7071 + sin(ang)*dim)*sc/4.;
                qrr *= r2(3.14159 - tOffs.x*ang);
                d2 = max(d2, -getTri(qrr,  hlSz/2.5));
                 
            }
            
            if(hash21(idi + tOffs*s/4. + .03)<.35){ 
                float hlSz = (hash21(idi + tOffs*s/4. + .04)*.25 + .25)*sc;
                //d2B = max(d2B, -(d2B + hlSz));//abs(d2 + .125) - .125; 
                //d2B = max(d2B, -(length(q - r2(-dir*3.14159/4.)*vec2(sc*.31, 0).yx) - hlSz/4.));
                //d2B = max(d2B, -(length(q + tOffs*(.7071 + sin(ang)*dim)*sc/4.) - hlSz/3.5));

                // Triangle holes.
                vec2 qrr = q + tOffs*(.7071 + sin(ang)*dim)*sc/4.;
                qrr *= r2(-tOffs.x*ang);
                d2B = max(d2B, -getTri(qrr,  hlSz/2.5));
                
            }
            #endif
           
            // The two triangle prisms on either side of the split.
            h = hMap(idi - tOffs*s/4.);
            d3 = opExtrusion(d2, p.z + h/2., h/2.);
            float hB = hMap(idi + tOffs*s/4.);
            float d3B = opExtrusion(d2B, p.z + hB/2., hB/2.);
            d3 += d2*.1;
            d3B += d2B*.1;
            
            // Determine the minimum triangle prism distance.
            if(d3B<d3){            
                idi -= tOffs/4.;
                d3 = d3B;
                d2 = d2B;
                h = hB;            
            }
            else {
                idi += tOffs/4.;
            }
            
        
        }
 
        // Closest of all the prisms.
        if(d3<d){
        
           d = d3; // Set the new minimum.
           
           // Saving the 2D face distance, height, and ID
           // for this particular prism.
           gVal = vec4(d2, h, idi);
        
        } 
        
        //if(d<-1e5) break;
    
    }
    
    // Check to see if the floor is closer.
    if(fl<d) gVal = vec4(-1);
    
    /*
    // Glow calculations.
    lCol = vec3(0);
    if((d)<.25 && d<fl && hash21(gVal.zw + .13)>=.7){
       float rnd = hash21(gVal.zw);
       vec3 gCol = .5 + .45*cos(6.2831*rnd/8. + (vec3(0, 1.2, 2) + .5)*1.5 + 1.5);
       lCol = gCol*smoothstep(0., .5, -(gVal.x));
    }    
    */
    
    // Minimum scene distance.
    return min(fl, d);
    
}


// Basic raymarcher.
float tr(in vec3 ro, in vec3 rd){

    // Overall ray distance and scene distance.
    // Adding some jitter to the jump off point to alleviate banding.
    float t = hash31(fract(ro/7.319) + rd)*.1, d;
    
    //glow = vec3(0);
    
    for(int i = min(0, iFrame); i<96; i++){
    
        d = m(ro + rd*t);
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, as
        // "t" increases. It's a cheap trick that works in most situations... Not all, though.
        if(abs(d)<.001 || t>FAR) break; // Alternative: 0.001*max(t*.25, 1.), etc.
        
         // Accumulate the glow color.
        //glow += lCol;///(1. + t);
        
        // Note that the ray is capped (to .1). It's slower, but is necessary for the
        // glow to work. I guess it could also help with overstepping the mark a bit.
        t += min(d*.7, .1); 
    }

    return min(t, FAR);
}

// fb39ca4's inverse mix function.
// Inverse mix takes a value between "a" and "b" and maps it to zero to one range.
float invMix(float a, float b, float x) {
	x = (x - a)/(b - a);
    return x*x; // Returning the square for darker tones... My tweak, and not correct.
}

// IQ's soft shadow function.
float sha(vec3 ro, vec3 lp, vec3 n, float k) {
	
    // Use penumbra modifications.
    #define PENUM
    
	// More would be nicer. More is always nicer, but not always affordable. :)
    const int iter = 32; 
    
    ro += n*.0015; // Coincides with the hit condition in the "trace" function.  
    vec3 rd = lp - ro; // Unnormalized direction ray.

    float shade = 1.; // Initialize the shadow to 1., or no shadow.
    float t = 0.;//hash31(fract(ro/7.319) + n)*.01; // Scene distance.
    float maxD = max(length(rd), .0001); // Max light distance.
    //float stepDist = end/float(maxIterationsShad);
    rd /= maxD; // Normalize.
	
    // Max shadow iterations - More iterations make nicer shadows, but slow things down. 
    // Obviously, the lowest number to give a decent shadow is the best one to choose. 
	for (int i = 0; i<iter; i++) {
 	 
		float d = m(ro + rd*t); // Distance to the scene.
        #ifdef PENUM
        // This is a tweak I found in fb39ca4's Loxodrom example. It makes sense,
        // but I'd need to investigate further. The shadows are more succint, but lighter.
        // https://www.shadertoy.com/view/MsX3D2
		float penumbraDist = t/k;
		shade = min(shade, invMix(-penumbraDist, penumbraDist, d));
		t += min((d + penumbraDist)*.5, .2);
        #else
        // IQ's simpler calculation. If feel the shade itself is more constistant, but
        // the shape isn't perfect. Emulating soft shadows isn't easy, if not impossible.
        shade = min(shade, k*d/t);
        //shade = min(shade, smoothstep(0., 1., k*d/t)); // Thanks to IQ for this tidbit.
        t += clamp(d, .005, .2);
        #endif
		
        // Early exit, and not exceeding the maximum light distance.
        if(d<0. || t>maxD) break;
	}
    
    #ifdef PENUM
    // Another one of fb39ca4's additions. Penumbra stuff. :) 
    shade = max(shade, 0.)*2. - 1.;
	return ((sqrt(1. - shade*shade)*shade + asin(shade)) + 3.14159265/2.)/3.14159265;
    #else
    return max(shade, 0.);
    #endif
    
}

// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float cao(in vec3 p, in vec3 n){

	float sca = 5., occ = 0.;
    for( int i = 0; i<5; i++ ){
    
        float hr = float(i + 1)*.1/5.;        
        float d = m(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
        //if(occ>1e5) break;
    }
    
    return clamp(1. - occ, 0., 1.);  
    
}

/*
// Standard normal function.
vec3 nr(in vec3 p) {
	const vec2 e = vec2(.001, 0);
	return normalize(vec3(m(p + e.xyy) - m(p - e.xyy), 
                          m(p + e.yxy) - m(p - e.yxy),	
                          m(p + e.yyx) - m(p - e.yyx)));
}
*/

// Normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 nr(in vec3 p) {
	
    //return normalize(vec3(m(p + e.xyy) - m(p - e.xyy), m(p + e.yxy) - m(p - e.yxy),	
    //                      m(p + e.yyx) - m(p - e.yyx)));
    
    // This mess is an attempt to speed up compiler time by contriving a break... It's 
    // based on a suggestion by IQ. I think it works, but I really couldn't say for sure.
    float sgn = 1.;
    vec3 e = vec3(.001, 0, 0), mp = e.zzz; // Spalmer's clever zeroing.
    for(int i = min(iFrame, 0); i<6; i++){
		mp.x += m(p + sgn*e)*sgn;
        sgn = -sgn;
        if((i&1)==1){ mp = mp.yzx; e = e.zxy; }
    }
    
    return normalize(mp);
}
 
void mainImage(out vec4 c, vec2 u){

    
    // Unit direction vector, camera (moving along Z), and point light (above the camera).
    // A "to" and "from" camera system is better, and only requires a few more lines, but
    // we're keeping things simple.
    vec3 r = normalize(vec3(u - iResolution.xy*.5, iResolution.y)), 
         o = vec3(0, iTime/6., -1.25), l = o + vec3(-.25, 4.75, -.5);
    
    // Rotating the unit direction ray, for a bit of visual interest.
    r.xz = r2(.35)*r.xz;
    r.yz = r2(.75)*r.yz;
    r.xy = r2(-.5)*r.xy;

    // Raymarching.
    float t = tr(o, r);
      
    // Save the distance function prism information.
    vec4 svVal = gVal;
    
    // Scene color, initialized to zero.
    c = vec4(0);
    
    // If we've hit an object, light it up.
    if(t<FAR){
    
        // Hit point and normal.
        vec3 p = o + r*t, n = nr(p);
        
        // Shadow and ambient occlusion.
        float sh = sha(p, l, n, 8.);
        float ao = cao(p, n);
      
        l -= p; // Light to surface vector. Ie: Light direction vector.
        float d = max(length(l), .001); // Light to surface distance.
        l /= d; // Normalizing the light direction vector.
        
  
        // Diffuse, half vector specular, and reflective specular.
        float dif = max(dot(l, n), 0.); //dif = pow(dif, 4.)*2.;
        float speR = pow(max(dot(normalize(l - r), n), 0.), 16.);
        float spe = pow(max(dot(reflect(l, n), r), 0.), 5.);
        
        // Schlick approximation. I use it to tone down the specular term.
		float Schlick = pow(1. - max(dot(r, normalize(r + l)), 0.), 5.);
		float freS = mix(.7, 1., Schlick);  //F0 = .2 - Glass... or close enough. 
        

        // Scene object color.
        
        // Coloring the grid objects.
        float rnd = hash21(svVal.zw);
        c = .5 + .45*cos(6.2831*rnd/8. + (vec4(0, 1.2, 2, 0) + .5)*1.5 + 2.25);
        
        // Giving the foreground prisms a different color, just for fun.
        c = mix(c.yxzw, c, smoothstep(0., 1., t/3. - .1));
        
        // Setting most of the prisms to grey.
        if(hash21(svVal.zw + .13)<.75){ 
            c = mix(c, vec4(.2)*dot(c, vec4(.299, .587, .114, 0)) + .15, .95);
            //glow *= 0.;
        }
        
        // One flat color, if you'd prefer that.
        //c = vec4(.45, .15, 1, 0); 

        // Extra shading.
        c *= hash21(svVal.zw + .143)*.5 + .5;
        
        
        // Floor.
        if(abs(svVal.y + 1.)<.001) c = vec4(.05);
        
        
        // Adding some texture.
        vec3 tx = tex3D(iChannel1, p - vec3(0, 0, svVal.y*2.), n);
        c.xyz *= (tx*3. + .2);
         
        // Cheap specular reflections.
        vec3 rf = reflect(r, n); // Surface reflection.
        vec4 rTx = texture(iChannel0, rf); rTx *= rTx;
        c += (c*.6 + .4)*speR*rTx*1.5;
        
        
        if(svVal.y > 0.){
            // Face edge distance.
            float d = max(abs(svVal.x), abs(p.z + svVal.y));
            c = mix(c, c*.1, 1. - smoothstep(0., .006, d - .002));
        }
        
        // Glow. Not used here.
        //c.xyz += c.xyz*glow*24.;
        
        
         
        // Applying diffuse lighting, ambient lighting, and attenuation.
        c.xyz = c.xyz*(dif*sh + vec3(1, .9, .7)*spe*freS*4.*sh + .35)*1./(1. + d*d*.125)*ao;
        
    }
    
    // Applying fog: This fog begins at 90% towards the horizon.
    c = mix(clamp(c, 0., 1.), vec4(0), smoothstep(0., .9, t/FAR));
    
    // Clamp.
    c = vec4(clamp(c.xyz, 0., 1.), t);
    
    // Mix the previous frames in with no camera reprojection.
    // It's OK, but minor temporal blur will be experienced.
    vec4 preCol = texelFetch(iChannel2, ivec2(u), 0);
    float blend = (iFrame < 2) ? 1. : 1./4.; 
    c = mix(preCol, c, blend);
    
    
    
    
}