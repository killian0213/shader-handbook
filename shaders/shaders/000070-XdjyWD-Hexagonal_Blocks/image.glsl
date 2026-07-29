// Image (image) — Hexagonal Blocks by Shane
// https://www.shadertoy.com/view/XdjyWD

/*

	Hexagonal Blocks
	----------------

	Some hexagonal surface tiling: It's been done many times before, and this is my take on it.
	I coded it off the top of my head, so I'd imagine there'd be more efficient methods out there. 
	Having said that, I tried to keep the operation count down to reasonable levels.

	As anyone who's tried it can testify, it's impossible to draw repeat objects right up against
	one another - unless boundary tiling tricks are involved, or you take a voxelized approach. 
	At any rate, rendering overlapping objects on a plane definitely isn't possible with a one 
	object pass. The only way it appears possible to draw overlapping repeat objects on a 2D plane
    is to take a brute-force approach and draw four objects, which is what I've done here. It seems 
	a little wasteful, but drawing four hexagon pylons in a single pass isn't that great a challenge 
	for a modern GPU. Plus, I've managed to group some figures to minimize the instruction count.
    By the way, technically, it's four objects on a square grid. With a simplex grid, you could get
	away with rendering three.

	These objects are only touching, so technically not overlapping. However, the algorithm 
	does allow for overlap - Uncomment OVERLAP, if you're curious. In fact, this is just a practice 
	run for a more interesting overlapping example I'm working on.

*/

#define FAR 40. // Maximum ray distance.
#define zRot 1./20. // XY plane rotation factor.

// Overlapped version. Overlapping pylons wouldn't move, so movement's been disabled.
//#define OVERLAP 

// Object (hexagonal pylon) ID, and it's associated random factor.
vec4 vObjID, rndID;

// Fabrice's consice, 2D rotation formula.
mat2 r2(float th){ vec2 a = sin(vec2(1.5707963, 0) + th); return mat2(a, -a.y, a.x); }

// Vec2 to float hash routine.
float hash21(vec2 p){ return fract(sin(dot(p, vec2(41.97, 289.13)))*43758.5453); }

// Tri-Planar blending function. Based on an old Nvidia tutorial by Ryan Geiss.
vec3 tex3D( sampler2D t, in vec3 p, in vec3 n ){ 
    
    n = n = max(n*n - .2, 0.001); // max(abs(n), 0.001), etc.
    n /= dot(n, vec3(1));
	vec3 tx = texture(t, p.yz).xyz;
    vec3 ty = texture(t, p.zx).xyz;
    vec3 tz = texture(t, p.xy).xyz;
    
    // Textures are stored in sRGB (I think), so you have to convert them to linear space 
    // (squaring is a rough approximation) prior to working with them... or something like that. :)
    // Once the final color value is gamma corrected, you should see correct looking colors.
    return (tx*tx*n.x + ty*ty*n.y + tz*tz*n.z);
}


// The individual objects. In this case, hexagonal pylons. 
float rObj(in vec3 q, in vec3 b){
    
    #if 1
    q = abs(q);
    return max(q.x - b.x, max(q.y*.866025 + q.z*.5 - b.y, q.z - b.z)); // Hexagonal pylon.
    //return max(max(q.x - b.x, q.y - b.y), q.z - b.z); // Box shape.
    #else
    // More correct, more expensive distance field. The differences werent' that noticeable, 
    // so the cheaper one above it used.
    q = abs(q);
    q.yz = vec2(q.y*.866 + q.z*.5, q.z);
    q -= b;
    return max(min(max(q.y, q.z), 0.) + length(max(q.yz, 0.)), q.x);
    //return min(max(max(q.x, q.y), q.z), 0.) + length(max(q, 0.));
    #endif
}

// The distance function: Some hexagons rendered onto a couple of planes, with some spatial 
// contortion thrown in.
float m(in vec3 p){
    
	// XY plane rotation about the Z-axis. It's a very common raymarching move.
    p.xy *= r2(p.z*zRot); 

    // YZ plane perturbation - just for a bit of variation.
    p.x -= dot(sin(p*3.14159/4. - cos(p.zxy*3.14159/4.)), vec3(.2));
    
    

    // Left and right YZ planes. Also a common raymarching move.
    float signX = sign(p.x); // IDs which plane we're on. Used in the "hash" function.
    p.x = signX*p.x - 2.; // Same as "abs(p.x)."  // abs(p.x) - .25;
    

    // The hexagonal surface.
    //
    p.yz /= 2.; // YZ-plane scaling.
    
    #ifdef OVERLAP
    const float w = .3; // Hexagonal face width.
    #else
    const float w = .25; // Hexagonal face width.
    #endif
    

    // Transformation factor: If you see the number ".866" (sqrt(3)/2) inside a
    // 2D vector, there'll be a good chance that something related to triangles 
    // or hexagons will be involved. It's based on boring high school math. :)
    const vec2 c = vec2(.866025, 1);
    
    // Draw four hexagonal pylons (protruding from two walls). The two on the left
    // are above and below one another, and the ones on the right are rendered in
    // the same arrangement, but moved up by half a grid cell. For a visual, just 
    // look at a 2D hexagonal grid, or simply look at the example.
    
    // Setting up the positioning of the four shapes. Note the transformation
    // factor also. These also serve as unique position IDs.
    vec4 v12 = floor(vec4(p.yz, p.yz - vec2(0, .5))/c.xyxy);
    vec4 v34 = floor(vec4(p.yz - vec2(.5, .25), p.yz - vec2(.5, .75))/c.xyxy);
   
    // Produce four unique random IDs from the positions above.
    vec4 rnd = vec4(hash21(v12.xy + signX), hash21(v12.zw + vec2(0, .5) + signX), 
               		hash21(v34.xy + vec2(.5, .25) + signX), hash21(v34.zw + vec2(.5, .75) + signX));
    
    // Save the IDs, while they're still in the zero to one range. They'll be used
    // to give the individual hexagonal pylons unique characteristics, like color
    // and height.
    rndID = rnd; // Range: [0, 1].
    
    #ifndef OVERLAP
    // Animate the heights, using the standard hash animation trick.
    rnd = sin(rnd*6.283 + iTime*(rnd + .5))*.5;
    #endif
    
    
    // Render the four hexagonal pylons in the arrangement described above.
    // Note the inverse transformation factor.
    vec4 n;

    // Bottom left, bottom right, top left, top right. The random hights are
    // passed in also.
    //
    // By the way, it's possible to to group a lot of the following into vector entities,
    // etc, and cut down on "min/max" operations considerably, but it'd be at the expense
    // of readability and changeability, so I've left it in this form.
    n.x = rObj(p - vec3(rnd.x, (v12.xy + vec2(.5, .5))*c.xy), vec3(.5, w, w));
    n.y = rObj(p - vec3(rnd.y, (v12.zw + vec2(.5, 1))*c.xy), vec3(.5, w, w));   
    n.z = rObj(p - vec3(rnd.z, (v34.xy + vec2(1, .75))*c.xy), vec3(.5, w, w));
    n.w = rObj(p - vec3(rnd.w, (v34.zw + vec2(1, 1.25))*c.xy), vec3(.5, w, w));
 
    
    // Save all the object IDs here - then sort them later. It's a little more complicated, 
    // but saves quite a few operations.
    vObjID = n;
 
    // Return the minimum of the contorted hexagon blocks above.
    return min(min(n.x, n.y), min(n.z, n.w))*.75;
 

 
}

// Cheap shadows are the bain of my raymarching existence, since trying to alleviate artifacts is an excercise in
// futility. In fact, I'd almost say, shadowing - in a setting like this - with limited  iterations is impossible... 
// However, I'd be very grateful if someone could prove me wrong. :)
float shad(vec3 ro, vec3 lp, float k, float t){

    // More would be nicer. More is always nicer, but not really affordable... Not on my slow test machine, anyway.
    const int iter = 16; 
    
    vec3 rd = lp-ro; // Unnormalized direction ray.

    float shade = 1.;
    float dist = .0025*(t*.125 + 1.);  // Coincides with the hit condition in the "trace" function.  
    float end = max(length(rd), 0.0001);
    //float stepDist = end/float(maxIterationsShad);
    rd /= end;

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. Obviously, the lowest 
    // number to give a decent shadow is the best one to choose. 
    for (int i=0; i<iter; i++){

        float h = m(ro + rd*dist);
        //shade = min(shade, k*h/dist);
        shade = min(shade, smoothstep(0.0, 1.0, k*h/dist)); // Subtle difference. Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += min(h, .2), dist += clamp(h, .01, stepDist), etc.
        dist += clamp(h, .02, .2); 
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (h<0. || dist > end) break; 
    }

    // I've added a constant to the final shade value, which lightens the shadow a bit. It's a preference thing. 
    // Really dark shadows look too brutal to me. Sometimes, I'll add AO also just for kicks. :)
    return min(max(shade, 0.) + .3, 1.); 
}

// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float cAO(in vec3 p, in vec3 n){
	
    float sca = 5., occ = 0.;
    for(float i=1.; i<6.; i++){
    
        float hr = i*.175/6.;        
        float dd = m(p + n*hr);
        occ += (hr - dd)*sca;
        sca *= 0.7;
    }
    return clamp(1.0 - occ, 0., 1.);    
}

/*
// Standard normal function.
vec3 nr(in vec3 p) {
	const vec2 e = vec2(0.002, 0);
	return normalize(vec3(m(p + e.xyy) - m(p - e.xyy), m(p + e.yxy) - m(p - e.yxy),	m(p + e.yyx) - m(p - e.yyx)));
}
*/

// Normal calculation, with some edging bundled in.
vec3 nr(vec3 p, inout float edge) { 
	
    // Edge spread of a few pixels, regardless of resolution.
    vec2 e = vec2(6./iResolution.y, 0);

	float d1 = m(p + e.xyy), d2 = m(p - e.xyy);
	float d3 = m(p + e.yxy), d4 = m(p - e.yxy);
	float d5 = m(p + e.yyx), d6 = m(p - e.yyx);
	float d = m(p)*2.;

    edge = abs(d1 + d2 - d) + abs(d3 + d4 - d) + abs(d5 + d6 - d);
    //edge = abs(d1 + d2 + d3 + d4 + d5 + d6 - d*3.);
    edge = smoothstep(0., 1., sqrt(edge/e.x*2.));

    
    e = vec2(.0015, 0); //iResolution.y - Depending how you want different resolutions to look.
	d1 = m(p + e.xyy), d2 = m(p - e.xyy);
	d3 = m(p + e.yxy), d4 = m(p - e.yxy);
	d5 = m(p + e.yyx), d6 = m(p - e.yyx);
	
    return normalize(vec3(d1 - d2, d3 - d4, d5 - d6));
}



// Minimum - with corresponding object ID.
vec2 objMin(vec2 a, vec2 b){ 
    
    // Returning the minimum distance along with the ID of the
    // object. This is one way to do it. There are others.
    
    // Equivalent to: return a.x < b.x ? a: b; 
    float s = step(a.x, b.x);
    return s*a + (1. - s)*b;
}

 
// Oldschool hatching effect: Interesting under the right circumstances. Without going into
// too much detail, obtain the grey scale value of the pixel, then draw a series of crosses 
// depending on how light or dark the pixel is. Ligher parts of the image will have larger 
// crosses drawn, and darker ones will have additional smaller crosses drawn. The end result 
// is some crosshatching - albeit non organic, but still pretty cool.
//
// The idea has been around for years. I'm not sure who came up with the original, but this is
// a generalized version of something I came across a while back.
vec3 ch(in vec3 col, in vec2 p){
    
    float gr = dot(col, vec3(.299, .587, .114)); // Grey scale value.
    
    // Crosses. Right diagonal, plus a left diagonal.
    //p *= r2(3.14159/8.); // + hash21(uv)*.002
    float rgt = p.x + p.y; 
    float lft = p.x - p.y;
    
    const float levels = 3.;
    const float iter = pow(2., levels) - 1.;
        
    // Choose these factors to suit the effect you're going for. I wanted low contrast.
    // High contrast (col*4.) with darker hatching (col *= .5) will give it more of a 
    // traditional crosshatched feel.
    vec3 fCol = col*1.5; col *= .7;
    
    float a = 2.; // Related to cross size.
    
    // Basically, the darker a pixel is, the more hatching lines it'll receive.
    for(float i=1.; i<iter; i+=2.){

        fCol = mix(fCol, mix(fCol, col, step(0., .5 - mod(lft, a))), step(gr, i/iter));
        fCol = mix(fCol, mix(fCol, col, step(0., .5 - mod(rgt, a))), step(gr, (i + 1.)/iter));        
        a *= 2.; // Increase the cross size factor.
        
    }
    
    return min(fCol, 1.);
}

 

void mainImage( out vec4 fc, in vec2 u )
{
    
    // Unit direction vector with some "fish eye" lens distortion.
    vec3 r = vec3(u - iResolution.xy*.5, iResolution.y*.75);
    r = normalize(vec3(r.xy, sqrt(max(r.z*r.z - dot(r.xy, r.xy)*.5, 0.)) ));
    
    // Camera - or ray origin, plus a light vector.
    vec3 o = vec3(0, 0, iTime*2.), l = o + vec3(0, 0, 4);
 
    // A bit of camera rotation.
    r.xy = r2(-o.z*zRot*2.)*r.xy;
    r.xz = r2(cos(o.z*zRot*3.14159)/2.)*r.xz;
    
    // Raymarching loop.
    float d, t = 0.;
    
    for(int i=0; i<128;i++){
        
        d = m(o + r*t);
        if(abs(d)<0.001*(t*.125 + 1.) || t>FAR) break;
        t += d;
        //t += (1. - step(.5, d)*.25)*d;
    }
    
    t = min(t, FAR); // Camera to surface distance.
    
    // Of the four rendered hexagonal pylons, use the global object distance vector
    // to determine the closest. Ie; the ID of the pylon we've hit.
    vec2 vObj = objMin(vec2(vObjID.x, 0.), vec2(vObjID.y, 1.));
    vObj = objMin(vObj, objMin(vec2(vObjID.z, 2.), vec2(vObjID.w, 3.)));
    
    // Save the random ID vector here, or before the distance field function is called
    // again for normal calculations, etc.
    vec4 svRndID = rndID;
    
    // The object ID, which is an integer from zero to three inclusive.
    //
    // In regards to non constant integer array access: This is a WebGL 2 thing, and far more 
    // convenient than doing it the old way, which involved setting up a "for" loop. However, 
    // I'm at that age where I'm suspicious of new things, so if it gives anyone any trouble, 
    // feel free to let me know, and I'll make the appropriate changes. :)
    int iObjID = int(vObj.y); 
    

    // Initiate the scene color to zero.
    vec3 col = vec3(0);
    
    
    // If we hit the surface, light it up.
    if(t<FAR){
    
        // Surface position and normal calculation.
        float edge = 0.;
        vec3 p = o + r*t, n = nr(p, edge);

        // Shadows and occlusion.
        float sh = shad(p + n*.005, l, 16., t);
        float ao = cAO(p, n);        
        
        l -= p; // Light to surface vector. Ie: Light direction vector.
        d = max(length(l), 0.001); // Light to surface distance.
        l /= d; // Normalizing the light direction vector.
        
        

		float attn = 1./(1. + d*d*.25); // Attenuation - based on light-to-surface distance. 
        float diff = pow(max(dot(l, n), 0.), 1.); // Diffuse.
        float spec = pow(max(dot(reflect(l, n), r), 0.), 8.); // Specular.
        
        // Texturing the object.
        vec3 tP = p, tN = n;
        
        // Transforming the texture position to match the contortions in the distance function.
        tP.xy *= r2(tP.z*zRot); // XY-plane rotation about Z.
        tP.x -= dot(sin(tP*3.14159/4. - cos(tP.zxy*3.14159/4.)), vec3(.2)); // Perturbation.
        #ifndef OVERLAP
        // Moving the texture up and down with the pylons to match the distance function.
        float hgt = sin(svRndID[iObjID]*6.283 + iTime*(svRndID[iObjID] + .5))*.5 + .5;
        tP.x += -sign(tP.x)*hgt;
        #endif
 
        // Rotating the normal about the XY-plane to match the same in the distance function.
        tN.xy *= r2(p.z*zRot);
        
		// Surface texel.
    	vec3 tx = tex3D(iChannel0, tP/2., tN)*4.;
    	tx = mix(tx, vec3(1)*dot(tx, vec3(.299, .587, .114)), .5); // Toning down a little.
 
        // Coloring some random pylons pink and blue, according to the individual IDs generated
        // in the distance function.
        if(svRndID[iObjID]>.9){
            tx = mix(tx, tx*vec3(1, .2, .4)*2.5, .5);
        }
        else if(svRndID[iObjID]>.75) {
            tx = mix(tx, tx*vec3(.2, .6, 1)*2.5, .5); 

        }

		// Combining the surface color with the other properties.
        col = tx*(diff + ao*.75 + vec3(1, .6, .2)*spec);

        col *= 1. - edge*.8; // Adding the dark edges.
        
        col *= ao*sh*attn; // Shading and attenuation.
        
        
    }
    
    
    // FOG
    //
    // Adding a bit of fog.
    vec3 fog = vec3(1.3)*(-r.x*.5 + .5);
    //fog = mix(fog, pow(vec3(1.5, 1, 1)*fog, vec3(1, 3, 16)), .15).zyx;
    col = mix(col, fog, smoothstep(0., .99, t/FAR));
    
    
    
    // POSTPROCESSING
    // 
    // The rendering was pretty basic, so I thought I'd try to make it look a little
    // more artsy by throwing in some pretty cheap postprocessing effects. 
    
    // A bit of sepia. I was in two minds as to whether I'd use it. I'm pretty sure "col" 
    // is always positive, but it's clamped for the Mac users, just in case. :)
    col = mix(col, pow(max(col, 0.), vec3(1, 2, 10)), .25);
 
  
    // Rotated vertical and horizontal line overlay. 
    //vec2 u2 = u*r2(3.14159/6.);
    //col *= .9 + .2*sin(u2.x*3.14159*450./8.);
    //col *= .9 + .2*sin(u2.y*3.14159*450./8.);
    
    // Very basic crosshatching effect. Not realistic, but still artsy. I've mixed it in
    // with the original to tone it down a little.
    col = mix(col, ch(col, u), .75); 
    
   
    // Subtle vignette.
    u /= iResolution.xy;
    col *= pow(16.*u.x*u.y*(1. - u.x)*(1. - u.y) , .125)*.5 + .5;
    

    // SCREEN PRESENTATION
    //
    // Approximate gamma correction.
    fc = vec4(sqrt(clamp(col, 0., 1.)), 1);
    
    
}