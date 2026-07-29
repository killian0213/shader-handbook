// Image (image) — Mobius Spiral Sphere Projection by Shane
// https://www.shadertoy.com/view/7fl3DX

/*

    Mobius Spiral Sphere Projection
    -------------------------------
    
    This is a simple demonstration displaying the relationship between complex
    transforms and stereographic projection. In particular, this is an animated 
    unit sphere containing hexagons packed along (loxodromic) spiral lines 
    stereographically projected down to the plane. The resultant plane pattern 
    formed is a standard Mobius spiral.
    
    I studied all this stuff back in the day, but equations on paper don't really 
    mean that much. It's one thing to be told that there is a relationship between 
    stereographic projection and complex transforms on a plane, and another to see 
    it in action. If you're having trouble falling asleep, I could give you the 
    formal mathematical description, but this should be enough to give anyone 
    interested a starting point. :)
    
    For those not familiar with the process, here it is in practical terms: Place 
    a sphere on a plane, then obtain the scene hit point. Depending on what you
    wish to achieve, you'll either want to map a planar pattern to a sphere, or a
    spherical pattern to a plane. Regardless, you construct a unit direction ray 
    from the sphere's north pole to the hit point, trace from the sphere to the 
    plane (or vice versa), then obtain the pattern color value from the new hit 
    point. It's very similar to the way in which you'd obtain a reflected value.
     
    The naive lighting style was produced very quickly and is mostly fake, so I 
    wouldn't pay too much attention to it. Having said that, it has a certain 
    charm, and it displays the patterns well.
    
    You can use this process to map any plane pattern to a sphere, or vice versa.
    In my case, I was interested in creating one of those cool 3D spherical Doyle 
    spiral objects. Doyle spirals look similar to the pattern here, but have a 
    circle packing element to them that looks really interesting. I have one that 
    I intend to tidy up and post later. By the way, you can get a rough idea of
    what that looks like by setting the "SHAPE" define to one.
    
 
    
    Related examples:
    
    // A Mobius spiral transform without all the code.
    // Fabrice has a lot of cool Mobius related examples,
    // but this one is nice and simple.
    Log Moebius Transfo psychedelic -- FabriceNeyret2
    https://www.shadertoy.com/view/XdyXD3
    //
    // Based on the following:
    Logarithmic Mobius Transform - Shane
    https://www.shadertoy.com/view/4dcSWs
    
    // MLA has much more involved examples than this, 
    // but this is easier to get your head around. :)
    Möbius Spiral with Hex Grid -- mla
    https://www.shadertoy.com/view/wtjczR
    
    // nr4 has a few really nice Mobius related examples, and
    // shaders in general. This one is really pleasing to 
    // the eye.
    Moebius Log-Rotator -- nr4
    https://www.shadertoy.com/view/WcyfRK

    
*/



///// Variable defines.

// The grid element. The circles almost look like a mapped
// spherical Doyle spiral, but not quite... I have one of 
// those that I'll post later.
//
// Grid shape: Hexagons: 0, Circles: 1.
#define SHAPE 0
   
// Display the sphere.
#define SHOW_SPHERE
 
////////////////////


#define PI 3.14159265358979323846
#define TAU 6.28318530717958647693

// Max ray distance.
#define FAR 20.


// Scene object ID.
int objID;


// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }

// Hash without Sine -- Dave Hoskins
// https://www.shadertoy.com/view/4djSRW
// 1 out, 2 in...
float hash21(vec2 p) {
 
    p = fract(p*vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x*p.y);
}

// IQ's box function.
float sBoxS(in vec2 p, in vec2 b, in float rf){
  
  vec2 d = abs(p) - b + rf;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - rf;
    
}

 
// Object distance holder. We're only using two, so this
// is a bit of overkill.
vec4 vObj;

// The extruded image.
float map(vec3 p){
    
    // Floor.
    float fl = p.y + .5;
     
    // Sphere.
    #ifdef SHOW_SPHERE
    float sph = length(p) - .5;
    #else
    float sph = 1e5;
    #endif
      
       
    // Object IDs.
    vObj = vec4(fl, sph, 1e5, 1e5);
    
    // Minimum scene distance.
    return min(fl, sph); 
 
}

 
// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    // Overall ray distance and scene distance.
    float t = 0., d;
    
    for(int i = min(0, iFrame); i<128; i++){
    
        d = map(ro + rd*t);
        // For stereographic projection, accuracy at the poles matter, so there
        // is the extra condition that the distance be negative. Without it, 
        // a kind of singularity artifact will appear at the pole. There'd be a 
        // reason for it, but I'm not sure what it would be... Something to do 
        // with sciece would be ny guess. :D 
        if((abs(d)<.001 && d<0.) || t>FAR) break;
        
        t += d*.9; 
    }

    return min(t, FAR);
}


// Standard normal function. It's not as fast as the tetrahedral calculation, 
// but more symmetrical.
vec3 getNormal(in vec3 p, float t) {
	const vec2 e = vec2(.001, 0);
	return normalize(vec3(map(p + e.xyy) - map(p - e.xyy), map(p + e.yxy) - map(p - e.yxy),	
                          map(p + e.yyx) - map(p - e.yyx)));
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
        //shade = min(shade, smoothstep(0., 1., k*d/t)); // Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += clamp(d, .01, stepDist), etc.
        t += clamp(d, .005, .15); 
        
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (d<0. || t>end) break; 
    }

    // Cap above zero.
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
    }
    
    return clamp(1. - occ, 0., 1.);  
}

// Standard complex transform functions. 
vec2 cmul(vec2 a, vec2 b){ return mat2(a, -a.y, a.x)*b; }
vec2 cinv(vec2 a){ return vec2(a.x, -a.y)/dot(a, a); }
vec2 cdiv(vec2 a, vec2 b){ return cmul(a, cinv(b)); }
vec2 clog(in vec2 z){ return vec2(log(length(z)), atan(z.y, z.x)); }
vec2 cexp(vec2 z){ return exp(z.x)*vec2(cos(z.y), sin(z.y)); }
vec2 cpow(vec2 a, vec2 b){ return cexp(cmul(b, clog(a))); }


// Rolling the ball on the plane.
vec3 rollObj(vec3 p){

    //p.xy *= rot2(iTime/4.);
    p.xz *= rot2(iTime/2.);
    p.yz *= rot2(iTime/1.);
    return p;
}

 

// Stereographically maps the unit sphere sittin on a plane
// to the plane itself.
vec2 stereographic(vec3 p){
 
    // Projecting from the "vec3(0, 1, 0)" point down to the plane.
    return p.xz/(1. - p.y);
}

// Reverse stereographic mapping of the plane to a unit sphere
// sitting on it.
vec3 stereographicInverse(vec2 p){
 
    float r2 = dot(p, p);
    return vec3(2.*p.x, r2 - 1., 2.*p.y)/(1. + r2);    
}
  


// Floor. 
vec2 fFloor(vec3 p){
     
    // Floor.    
    
    // Move the pattern to the ball, rotate it, then 
    // project it back down to the floor.    
    p = stereographicInverse(p.xz);
    p = rollObj(p);
    return stereographic(p);

}

// Spiral repetition factor. Positive integers will work.
vec2 rep = vec2(4, 8);

vec3 transform(vec3 p){
    
    // If there were no rolling movement, you wouldn't need this.
    p.xz = fFloor(p);
 
      
    // 2D plane transformations.
    
    // The three lines below will produce a standard Mobius spiral
    // pattern. Commenting in the other two lines will produce something
    // more interesting, but I figured it was a bit much for this 
    // example.
    //p.xz = cpow(p.xz - vec2(1, .5), vec2(3., 0));   
    
    #if 1
    // Mobius transformation -- Probably the simplest one.
    p.xz = cdiv(p.xz - vec2(1, 0), p.xz + vec2(1, 0));
    // p.xz += cdiv(p.xz - vec2(.5, 0).yx, p.xz + vec2(.5, 0).yx);
    // This turns the Mobius transform (above) into a double spiral.
    p.xz = clog(p.xz);
    #else
    // Something more interesting -- Cool looking, but a bit much for this example.
    float N = 2.; // N-tuples of spirals... 3, 4, etc.
    p.xz = clog(cdiv(vec2(2, 0), cpow(p.xz, vec2(N, 0)) - vec2(1, 0)) + vec2(1, 0));
    #endif
    
    // The "rep" factor controls how the spiral looks.
    p.xz = cmul(p.xz, rep*vec2(1, sqrt(3.)/2.)/TAU);
    
     
    return p;

}

 
// Numeric transform function derivative. You could determine this analytically.
// In fact, I usually do, but this allows you try out more interesting complex
// transform combinations.
vec3 funcD(vec3 p){
     
    // Numeric derivative.
    float px = 1e-4;
    vec3 f = transform(p);
    vec3 dtX = (transform(p + vec3(px, 0, 0)) - f)/px;
    vec3 dtY = (transform(p + vec3(0, px, 0)) - f)/px;
    vec3 dtZ = (transform(p + vec3(0, 0, px)) - f)/px;
    //return vec3(length(dtX), length(dtY), length(dtZ))/sqrt(3.);
    return (mat3(dtX, dtY, dtZ)*vec3(1))/sqrt(3.);

}

// Decorative circle distances... Added in at the last minutes.
float gCir;
float gCir2;

vec3 getPattern(vec3 p3){
    
    // Pattern scale.
    vec2 sc = vec2(1)/2.;
    
    // Transform derivative. Used to produce border lines of equal
    // width... Not technically correct, but close enough for this example.
    float tdF = length(funcD(p3));
    
    // Perform the complex transform. In this case, a
    // Mobius spiral.
    p3 = transform(p3);
    
    // Floor (2D grid) coordinates.
    vec2 p = p3.xz;
 
    // Produce the hexagon grid.
    vec4 p4 = getHex(p);
    // Local coordiantes and ID.
    p = p4.xy;
    vec2 ip = p4.zw;
    
     
    // Grid shape: Circles or hexagons.
    #if SHAPE == 1
    // Circles.
    float poly = length(p) - s.y/2.;
    #else 
    float poly = hex(p) - s.y/2.;
    #endif
    
    
    // Cut out a dot in the center.
    poly = max(poly, -(length(p) - sc.x/32.));
    
    // Divide by the transform derivative. This will give you equal
    // cell border widths, in a lot of cases.
    poly /= tdF;
    
   
    // Last minute circle functions, to use for decorative
    // purposes. Not really necessary.
    vec2 offs = s*vec2(1, -1); // Offsets.
    vec2 offs2 = s*vec2(1, -1)/8.;
 
    gCir = -(length(p - offs2) - s.y/2./.866);
    gCir /= tdF;
    
    gCir2= length(p - offs2.yx/2.)- sc.x/5.;
    gCir2 /= tdF;
    
    
    // Cell distance and cell ID.
    return vec3(poly, ip);
}

/*
// Planar to spherical camera. Not quite, but close enough.
vec3 sphereCam(in vec2 p){

    //return normalize(vec3(p, 1)); // Debug.

    float t = 1./(1. + dot(p,p)/3.);
    return vec3(p*t, 2.*t - 1.);
}
*/

void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    
    // Screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;


	// Camera Setup.
    vec3 ro = vec3(0, 1.5, -2); // Camera position, doubling as the ray origin.
	vec3 lk = vec3(0, -.25, 0);//vec3(0, -.25, iTime);  // "Look At" position.
 
    // Light position. 
 	vec3 lp = ro + vec3(.75, 0, 1.5);// Put it a bit in front of the camera.
	

    // Using the above to produce the unit ray-direction vector.
    float FOV = .85; // FOV - Field of view.
    vec3 fwd = normalize(lk - ro); // Forward.
    vec3 rgt = normalize(cross(vec3(0, 1, 0), fwd));// Right. 
    // "right" and "forward" are perpendicular normals, so the result is normalized.
    vec3 up = cross(fwd, rgt); // Up.
    
     
    // rd - Ray direction.  
    vec3 rd = normalize(uv.x*rgt + uv.y*up + fwd/FOV );
    // Camera.
    //mat3 cam = mat3(rgt, up, fwd);
    // rd - Ray direction.
    //vec3 rd = cam*normalize(vec3(uv, 1./FOV));
    // A bit of lens mutation to increase the scene peripheral, if that's your thing.
    //vec3 rd = cam*sphereCam(uv*PI*.2/FOV);
   
    
 
    
    // Raymarch to the scene.
    float t = trace(ro, rd);
    
    // Save the object ID.
   float minDist = 1e5;
    
    // Only two objects. Identify the closest one.
    objID = vObj.x<vObj.y? 0 : 1;
    
    /*
    // Sorting four objects. Not needed here.
    objID = 0; 
    for(int i = 0; i<4; i++){
       if(vObj[i]<minDist){
           minDist = vObj[i];
           objID = i;
       }
    }
    */
  
	
    // Initiate the scene color to black.
	vec3 col = vec3(0);
	
	// The ray has effectively hit the surface, so light it up.
	if(t < FAR){
        
  	
    	// Surface position and surface normal.
	    vec3 sp = ro + rd*t;
        vec3 sn = getNormal(sp, t);
        
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
	    
	    // Light attenuation, based on the distances above.
	    float atten = 1./(1. + lDist*.05);

    	
    	// Diffuse lighting.
	    float diff = max( dot(sn, ld), 0.);
        //diff = pow(diff, 4.)*2.; // Ramping up the diffuse.
    	
    	// Specular lighting.
	    float spec = pow(max(dot(reflect(ld, sn), rd ), 0.), 32.); 
	    
	    // Fresnel term. Good for giving a surface a bit of a reflective glow.
        //float fre = pow(clamp(1. - abs(dot(sn, rd))*.5, 0., 1.), 2.);
        
		// Schlick approximation. I use it to tone down the specular term. It's pretty subtle,
        // so could almost be aproximated by a constant, but I prefer it. Here, it's being
        // used to give a hard clay consistency... It "kind of" works.
		float Schlick = pow( 1. - max(dot(rd, normalize(rd + ld)), 0.), 5.);
		float freS = mix(.15, 1., Schlick);  //F0 = .2 - Glass... or close enough. 
        
          
        // Obtaining the texel color. 
	    vec3 texCol = vec3(.6); 
        
        // Texture coordinates.
        vec3 txP = sp;
        
        // Smooth factor and edge width.
        float sf = .005;
        float ew = .018;
        
        // Pattern variable: Distance and ID.
        vec3 d3;

        // Object coloring.
        if(objID>0){
            
            // Ball. 
           
            ////
            // Raytrace from the ball to the floor, then obtain the 
            // Mobius spiral pattern value.
            
            // North pole to hit point unit direction vector.
            vec3 rd2 = normalize(txP - vec3(0, .5, 0));
            // Use it to trace from the hit point to the plane.
            float t2 = tracePlane(txP, rd2, vec3(0, 1, 0), vec3(0, -.5, 0));
            // Intersection point on the plane.
            vec3 txP2 = txP + rd2*t2;
            // Obtain the pattern values for coloring: Distance and ID.
            d3 = getPattern(txP2);
            ////
            
            // Applying a hack to approximate equi-spaced lines... I was in a 
            // hurry... I haven't decided whether a precise calculation is possible.
            // Either way, this looks OK for the purpose of this demonstration.
            ew *= 2./length(txP - vec3(0, 1, 0));
            //ew *= 2.*pow(1. + txP.y, 2.);

        }
        else {
            
            // Floor.
            d3 = getPattern(txP);
          
        }
        
        // Wrapping the cell ID with the Mobius spiral repetition factor.
        vec2 id = mod(d3.yz, rep.yx)/(rep.x*rep.y);
        
        // Rand, or non-random ID value.
        float rnd = hash21(id + .1);
        //rnd = (d3.y + d3.z*4.)/(4.*4.);
        //rnd = id.y + id.x*rep.y;
        //rnd = id.x*rep.x + id.y*rep.y;
        rnd = dot(id, rep);
 
        // Use the ID to color the cell in some way.
        // Two slightly different shades.
        vec3 cCol = .5 + .45*cos(TAU*rnd + vec3(0, PI/2., PI));
        vec3 cCol2 = .5 + .45*cos(TAU*rnd + .25 + vec3(0, PI/2., PI));
        // Order the two shades according to brightness.
        if(dot(cCol2 - cCol, vec3(299, .587, .114))<0.){
          vec3 tmp = cCol; cCol = cCol2; cCol2 = tmp;
        }
        // Render.
        cCol = mix(cCol, cCol2*1.2 + .05, 1. - smoothstep(0., sf*2., gCir));
        cCol = mix(cCol, cCol*1.5 + .1, 
                   1. - smoothstep(0., sf*2., abs(gCir + ew/4.) - ew/4.));

 
        // Background.
        texCol = vec3(.0);
        // Cell color.
        texCol = mix(texCol, cCol, 1. - smoothstep(0., sf, d3.x + ew));
      
      
        // Rendering an edge ring around the sphere.
        //
        // Adapted from one of IQ's world to screen space examples. 
        // I'll track down the particular one later.
        #ifdef SHOW_SPHERE
        mat3 cam = mat3(rgt, up, fwd);
        mat4 cam4 = mat4(rgt, 0, up, 0, fwd, 0, ro, 1.);
        mat4 invCam = inverse(cam4);
        vec3 qq = (invCam*vec4(vec3(0), 1.)).xyz;
        // 2D Screen space.
        vec2 s = (uv - qq.xy/qq.z/FOV)*qq.z;
        float r = .5/FOV;
        texCol = mix(texCol, vec3(0), 
                     1. - smoothstep(0., .003, abs(length(s) - r - .015) - .01));
        #endif
        
        
        
        // Combining the above terms to produce the final color.
        col = texCol*(diff*sh + .3 + vec3(1, .97, .92)*spec*freS*2.*sh);
        
        // Extra light.
        //col += col/(1. + lDist*lDist);
      
        // Shading.
        col *= ao*atten;
        
    
    }
    
    
    // Horizon fog. Not visible here, but provided for completeness.
    col = mix(col, vec3(0), smoothstep(0., .99, t/FAR));
    
    
    // Subtle vignette. Designers use them to frame things and guide
    // the viewer's eyes toward the center... or something like that.
    vec2 w = vec2(iResolution.x/iResolution.y, 1);
    col *= 1.05 - smoothstep(0., .1, sBoxS(uv, w/2., .15) + .1)*.15;
 
    
    // Rought gamma correction.
	fragColor = vec4(sqrt(max(col, 0.)), 1);
	
}