// Image (image) — Abstract Water Tunnel by Shane
// https://www.shadertoy.com/view/MsScRD

/*

	Abstract Water Tunnel
	---------------------

	This is merely an abstract representation of some water flowing through a 
	tunnel, so isn't in any way supposed to be a treatise on water physics...
    or even a loose reference. :)

	I've been meaning to do a basic reflection\refraction example for a while. 
	I made the setting abstract to avoid having to deal with the physics - 
	and ultimately, GPU effort - that tend to accompany realistic scenes. 
	Having said that, the edges required to give a pseudo polygonal effect 
	kind of complicated things a little.

	The scene geometry is reasonably cheap. When including extra passes, it kind 
	of has to be. I chose a watery setting, because I could get away with just 
	one refractive bounce. In fact, if I'd chosen deep water, I probably could 
	have got away with just the reflection, but I thought clear shallow water
	would look more interesting.

	I coded this on my fast machine, which can run it in fullscreen without a 
	problem, but I targeted it toward the 800x450 canvas. I was too afraid to 
	test it on my slow machine, just in case the FPS was much lower than I 
    expected. :) Regardless, I've done my best to keep operations, iterations, 
	etc, down to a reasonable level. Hopefully, it'll run well enough on the 
	average machine.

	By the way, I rushed in the comments, but I'll tidy them up in due course.
	If you spot any errors, feel free to let me know - especially if I've done
	something stupid, like invert the refracted ray, etc. I make dumb mistakes 
    like that all... the... time. :D
    

    // Other examples:

    // A more physically realistic example... that I proabably should have 
    // referred to. :)
    Where the River Goes (+ PostFX) - P_Malin
    https://www.shadertoy.com/view/XdG3zd

    // Really nice.
    Tunnel with lamps - TambakoJaguar
	https://www.shadertoy.com/view/MsVXzK
 

*/

#define FAR 40. // Maximum ray distance. Analogous to the far plane.

// Coyote's snippet to provide a virtual reality element. Really freaky. It gives the scene 
// physical depth, but you have to do that magic picture focus adjusting thing with your eyes.
//#define THREE_D 

//#define NO_RERACTION // Displays just the reflected water. Cheaper.


// Scene object ID. Either water (0) or the tunnel walls (1).
float objID;
float svObjID; // Global ID to keep a copy of the above from pass to pass.

// Fabrice's consice, 2D rotation formula.
mat2 r2(float th){ vec2 a = sin(vec2(1.5707963, 0) + th); return mat2(a, -a.y, a.x); }

// Tri-Planar blending function. Based on an old Nvidia tutorial.
vec3 tex3D( sampler2D t, in vec3 p, in vec3 n ){
    
    n = max(abs(n), 0.001);
    n /= dot(n, vec3(1));
	vec3 tx = texture(t, p.yz).xyz;
    vec3 ty = texture(t, p.zx).xyz;
    vec3 tz = texture(t, p.xy).xyz;
    
    // Textures are stored in sRGB (I think), so you have to convert them to linear space 
    // (squaring is a rough approximation) prior to working with them... or something like that. :)
    // Once the final color value is gamma corrected, you should see correct looking colors.
    return (tx*tx*n.x + ty*ty*n.y + tz*tz*n.z);
}

// Compact, self-contained version of IQ's 3D value noise function.
float n3D(vec3 p){
    
	const vec3 s = vec3(7., 157., 113.);
	vec3 ip = floor(p); p -= ip; 
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    //p = p*p*(3. - 2.*p);
    p *= p*p*(p*(p * 6. - 15.) + 10.);
    h = mix(fract(sin(h)*43758.5453), fract(sin(h + s.x)*43758.5453), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z); // Range: [0, 1].
}

// Used as shorthand to write things like vec3(1, 0, 1) in the short form, e.yxy. 
const vec2 e = vec2(0, 1);



/*
// The standard vec3 to vec3 hash, commonly attributed to IQ. On a GPU, the "sin" function
// tends to break down with large time values.
vec3 hash(in vec3 p){
    

	p = vec3( dot(p,vec3(127.1, 311.7, 74.7)),
			  dot(p,vec3(269.5, 183.3, 246.1)),
			  dot(p,vec3(113.5, 271.9, 124.6))); 
	
	p = fract(sin(p)*43758.5453123)*2. - 1.;
    
    mat2  m = r2(iTime*2.);//in general use 3d rotation
	p.xy = m * p.xy;//rotate gradient vector
    //p.yz = m * p.yz;//rotate gradient vector
    //p.zx = m * p.zx;//rotate gradient vector
	return p;
}
*/

// Dave's hash function. More reliable with large values, but will still eventually break down.
//
// Hash without Sine
// Creative Commons Attribution-ShareAlike 4.0 International Public License
// Created by David Hoskins.
// vec3 to vec3.
vec3 hash(vec3 p){

	p = fract(p * vec3(.1031, .1030, .0973));
    p += dot(p, p.yxz + 19.19);
    p = fract((p.xxy + p.yxx)*p.zyx)*2. - 1.;
    return p;
    
    /*
    // Note the "mod" call. Slower, but ensures accuracy with large time values.
    mat2  m = r2(mod(iTime, 6.2831853));	
	p.xy = m * p.xy;//rotate gradient vector
    p.yz = m * p.yz;//rotate gradient vector
    //p.zx = m * p.zx;//rotate gradient vector
	return p;
    */

}

/*
// Cheap vec3 to vec3 hash. I wrote this one. It's much faster than others, but I don't trust
// it over large values.
vec3 hash(vec3 p){ 
   
    //float n = sin(dot(p, vec3(7, 157, 113)));    
    //p = fract(vec3(2097152, 262144, 32768)*n)*2. - 1.; 
    
    //mat2  m = r2(iTime);//in general use 3d rotation
	//p.xy = m * p.xy;//rotate gradient vector
    ////p.yz = m * p.yz;//rotate gradient vector
    ////p.zx = m * p.zx;//rotate gradient vector
	//return p;
    
    //float n = sin(dot(p, vec3(7, 157, 113)));    
    //return fract(vec3(2097152, 262144, 32768)*n)*2. - 1.; 

    
    float n = sin(dot(p, vec3(7, 157, 113)));    
    p = fract(vec3(2097152, 262144, 32768)*n); 
    return sin(p*6.2831853 + iTime); 
}
*/

// Gradient noise. Ken Perlin came up with it, or a version of it. Either way, this is
// based on IQ's implementation. It's a pretty simple process: Break space into cubes, 
// attach random 3D vectors to each of the cube's eight verticies, then smoothly 
// interpolate the space between them.
float gradN3D(in vec3 f){
    
    // Used as shorthand to write things like vec3(1, 0, 1) in the short form, e.yxy. 
   const vec2 e = vec2(0, 1);
   
    // Set up the cubic grid.
    // Integer value - unique to each cube, and used as an ID to generate random vectors for the
    // cube vertiies. Note that vertices shared among the cubes have the save random vectors attributed
    // to them.
    vec3 p = floor(f);
    f -= p; // Fractional position within the cube.
    

    // Smoothing - for smooth interpolation. Use the last line see the difference.
    //vec3 w = f*f*f*(f*(f*6.-15.)+10.); // Quintic smoothing. Slower and more squarish, but derivatives are smooth too.
    vec3 w = f*f*(3. - 2.*f); // Cubic smoothing. 
    //vec3 w = f*f*f; w = ( 7. + (w - 7. ) * f ) * w; // Super smooth, but less practical.
    //vec3 w = .5 - .5*cos(f*3.14159); // Cosinusoidal smoothing.
    //vec3 w = f; // No smoothing. Gives a blocky appearance.
    
    // Smoothly interpolating between the eight verticies of the cube. Due to the shared verticies between
    // cubes, the result is blending of random values throughout the 3D space. By the way, the "dot" operation
    // makes most sense visually, but isn't the only metric possible.
    float c = mix(mix(mix(dot(hash(p + e.xxx), f - e.xxx), dot(hash(p + e.yxx), f - e.yxx), w.x),
                      mix(dot(hash(p + e.xyx), f - e.xyx), dot(hash(p + e.yyx), f - e.yyx), w.x), w.y),
                  mix(mix(dot(hash(p + e.xxy), f - e.xxy), dot(hash(p + e.yxy), f - e.yxy), w.x),
                      mix(dot(hash(p + e.xyy), f - e.xyy), dot(hash(p + e.yyy), f - e.yyy), w.x), w.y), w.z);
    
    // Taking the final result, and putting it into the zero to one range.
    return c*.5 + .5; // Range: [0, 1].
}


/* 
float drawObject(in vec3 p){
    
    // Anything that wraps the domain will work. The following looks pretty intereting.
    //p = cos(p*6.2831853)*.25 + .25; 
    //p = abs(cos(p*3.14159)*.5);
    
    p = fract(p) - .5;    
    return dot(p, p);
    
    //p = abs(fract(p)-.5);
    //return dot(p, vec3(.5));
    
    
    //p = fract(p) - .5;    
    //return max(max(dot(p.xy, p.xy), dot(p.yz, p.yz)), dot(p.xz, p.xz))*1.5;
    
    //p = abs(fract(p)-.5);
    //return max(max(p.x, p.y), p.z);
    
    //p = cos(p*3.14159)*0.5; 
    //p = abs(cos(p*3.14159)*0.5);
    //p = abs(fract(p)-.5);
    //return max(max(p.x - p.y, p.y - p.z), p.z - p.x);
    //return min(min(p.x - p.y, p.y - p.z), p.z - p.x);
    
}


float cellTile(in vec3 p){
    
     
    vec3 d = vec3(.75); // Set the maximum.
    
    // Draw four overlapping shapes (circles, in this case) using the darken blend 
    // at various positions on the tile.
    d.z = drawObject(p - vec3(.81, .62, .53));
    d.y = max(d.x, min(d.y, d.z)); d.x = min(d.x, d.z);
    p.xy = vec2(p.y-p.x, p.y + p.x)*.7071;
    d.z = drawObject(p - vec3(.39, .2, .11));
    d.y = max(d.x, min(d.y, d.z)); d.x = min(d.x, d.z);
    
    
    p.yz = vec2(p.z-p.y, p.z + p.y)*.7071;
     
   
    d.z = drawObject(p - vec3(.62, .24, .06));
    d.y = max(d.x, min(d.y, d.z)); d.x = min(d.x, d.z);
    p.xz = vec2(p.z-p.x, p.z + p.x)*.7071; 
    d.z = drawObject(p - vec3(.2, .82, .64));
    d.y = max(d.x, min(d.y, d.z)); d.x = min(d.x, d.z);

    //d = sqrt(d);
    
    //return 1. - (d.x*2.66);
    return ((d.y - d.x)*2.66);
    //return (1.-sqrt(d.x)*1.33);
    
} 
*/

// The path is a 2D sinusoid that varies over time, depending upon the frequencies, and amplitudes.
vec2 path(in float z){ 

    //return vec2(0);
    //float s = sin(z/24.)*cos(z/12.);
    //return vec2(s*12., 0.);
    
    return vec2(sin(z*.15)*2.4, cos(z*.25)*1.7); 
}

// The triangle function that Shadertoy user Nimitz has used in various triangle noise demonstrations.
// See Xyptonjtroz - Very cool. Anyway, it's not really being used to its full potential here.
vec3 tri(in vec3 x){return abs(x - floor(x) - .5);} // Triangle function.
// PF - phase variance. Varies between zero and 1. Zero is redundant, as it returns the triangle function.
vec3 trap(in vec3 x, float pf){ return (tri(x - pf*.125) + tri(x + pf*.125))*.5; } // Trapezoid function.


// The function used to perturb the walls of the cavern: There are infinite possibities, but this one is 
// just a cheap...ish routine - based on the triangle function - to give a subtle jaggedness. Not very fancy, 
// but it does a surprizingly good job at laying the foundations for a sharpish rock face. Obviously, more 
// layers would be more convincing. However, this is a GPU-draining distance function, so the finer details 
// are bump mapped.
float surfFunc(in vec3 p){
    
    // Far more interesting formations, and fast, but not fast enough for this example.
    //return cellTile(p/5.)*.75 + cellTile(p/2.5)*.25; 
    
	//return dot(tri(p*.384 + tri(p.yzx*.192)), vec3(.666));
    return dot(trap(p*.384 + trap(p.yzx*.192, .75), .75), vec3(.666));
}

// Perturbing the water. Just a very basic sinusoidal combination. Definitely not water physics. :)
float surfFunc2(in vec3 p){
    
    p += vec3(0, 0, -iTime*4.); // Flow it in the Z-direction - down the tunnel.
    
	return dot(sin(p + sin(p.yzx*2. + iTime*1.)), vec3(.1666)) + .5;

}
 

// Standard tunnel distance function with some perturbation thrown into the mix. A water plane has been 
// worked in also. A tunnel is just a tube with a smoothly shifting center as you traverse lengthwise. 
// The walls of the tube are perturbed by a pretty cheap 3D surface function.
float map(vec3 p){
    
    float sf = surfFunc(p); // Some triangular based noise to perturb the walls. Gives a low-poly effect.

    p.xy -= path(p.z); // Wrap the tunnel around the path.
    
 
    // Round tunnel: Euclidean distance: length(tun.xy)
    float n = 1. - length(p.xy*vec2(0.5, 0.7071)) + (0.5 - sf);
    
    // Square tunnel: Chebyshev(?) distance: max(abs(tun.x), abs(tun.y))
    //vec2 tun = abs(p.xy)*vec2(0.5, 0.7071);
    //float n = 1.- max(tun.x, tun.y) + (0.5 - sf);
    
    // Rounded square tunnel.
    //vec2 tun = abs(p.xy)*vec2(0.5, 0.7071);
    //float n = 1. - pow(dot(pow(tun, vec2(4)), vec2(1)), 1./4.) + (0.5 - sf);
    
    // Hexagonal tunnel.
    //vec2 tun = abs(p.xy)*vec2(0.5, 0.75);
    //float n = 1. - max(tun.x*.866025 + tun.y*.5, tun.y) + (0.5 - sf); //1.133975
    
    
    sf = surfFunc2(p); // Some watery perturbation. Very minimal.
    p.y += (.5-sf)*.5 + .85; // Add it to the water surface plane.
    
    // Object ID.
    objID = step(n, p.y);

    return min(n, p.y); // Return the object isovalue (distance).
    
 
}

// The refraction distance field. It's exactly the same as above, but doesn't include
// the water plane. It's here to save cycles.
float mapRef(vec3 p){
    
    float sf = surfFunc(p); // Some triangular based noise to perturb the walls.

    p.xy -= path(p.z); // Wrap the tunnel around the path.
   
    // Round tunnel: Euclidean distance: length(tun.xy)
    float n = 1. - length(p.xy*vec2(0.5, 0.7071)) + (0.5 - sf);
    
    // Square tunnel: Chebyshev(?) distance: max(abs(tun.x), abs(tun.y))
    //vec2 tun = abs(p.xy)*vec2(0.5, 0.7071);
    //float n = 1.- max(tun.x, tun.y) + (0.5 - sf);
    
    // Rounded square tunnel.
    //vec2 tun = abs(p.xy)*vec2(0.5, 0.7071);
    //float n = 1. - pow(dot(pow(tun, vec2(4)), vec2(1)), 1./4.) + (0.5 - sf);
    
    // Hexagonal tunnel.
    //vec2 tun = abs(p.xy)*vec2(0.5, 0.75);
    //float n = 1. - max(tun.x*.866025 + tun.y*.5, tun.y) + (0.5 - sf); //1.133975
    
    // Object ID.
    objID = 1.;

    return n; // Return to object isovalue (distance).

 
}


// The bump function.
float bumpFunc(vec3 p){

    // Just one layer of moving gradient noise to give the impression that the surface is rippled.
    // By the way, the cheaper cubic interpolation (see the function) shows grid lines when bump 
    // mapped. There's a quintic option, but the ripples are so small, that no one will notice.
    return gradN3D(p*8. + vec3(0, iTime, 0.));
}

// Standard function-based bump mapping function.
vec3 bumpMap(in vec3 p, in vec3 n, float bumpfactor){
    
    const vec2 e = vec2(0.002, 0);
    float ref = bumpFunc(p);                 
    vec3 grad = (vec3(bumpFunc(p - e.xyy), bumpFunc(p - e.yxy), bumpFunc(p - e.yyx)) - ref)/e.x;                     
          
    grad -= n*dot(n, grad);          
                      
    return normalize( n + grad*bumpfactor );
	
}


// Standard raymarching routine.
float trace(vec3 ro, vec3 rd){
   
    float t = 0., d;
    
    for (int i=0; i<96; i++){

        d = map(ro + rd*t);
        
        if(abs(d)<.001*(t*.125 + 1.) || t>FAR) break;//.001*(t*.125 + 1.)
        
        t += d*.86; // Using slightly more accuracy in the first pass.
    }
    
    return min(t, FAR);
}

// Second pass, which is the first, and only, reflected bounce. 
// Virtually the same as above, but with fewer iterations and less 
// accuracy.
//
// The reason for a second, virtually identical equation is that 
// raymarching is usually a pretty expensive exercise, so since the 
// reflected ray doesn't require as much detail, you can relax things 
// a bit - in the hope of speeding things up a little.
float traceRef(vec3 ro, vec3 rd){
    
    float t = 0., d;
    
    for (int i=0; i<32; i++){

        d = map(ro + rd*t);//*rDir;
        
        if(abs(d)<0.001*(t*.125 + 1.) || t>FAR) break;
        
        t += d;
    }
    
    return min(t, FAR);
}

// Another pass, which is the first, and only, refracted bounce. 
// Virtually the same as above, but uses a slimmed down distance function - due
// to the fact that the water plane doesn't need to be included.
float traceRefr(vec3 ro, vec3 rd){
    
    float t = 0., d;
    
    for (int i=0; i<32; i++){

        d = mapRef(ro + rd*t);
        
        if((d<0. && abs(d)<0.002*(t*.25 + 1.)) || t>FAR) break;
        
        t += d;
    }
    
    return min(t, FAR);
}


// Cheap shadows are the bain of my raymarching existence, since trying to alleviate artifacts is an excercise in
// futility. In fact, I'd almost say, shadowing - in a setting like this - with limited  iterations is impossible... 
// However, I'd be very grateful if someone could prove me wrong. :)
float softShadow(vec3 ro, vec3 lp, float k, float t){

    // More would be nicer. More is always nicer, but not really affordable... Not on my slow test machine, anyway.
    const int maxIterationsShad = 24; 
    
    vec3 rd = lp-ro; // Unnormalized direction ray.

    float shade = 1.;
    float dist = .0015*(t*.125 + 1.);  // Coincides with the hit condition in the "trace" function.  
    float end = max(length(rd), 0.0001);
    //float stepDist = end/float(maxIterationsShad);
    rd /= end;

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. Obviously, the lowest 
    // number to give a decent shadow is the best one to choose. 
    for (int i=0; i<maxIterationsShad; i++){

        float h = map(ro + rd*dist);
        //shade = min(shade, k*h/dist);
        shade = min(shade, smoothstep(0.0, 1.0, k*h/dist)); // Subtle difference. Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += min(h, .2), dist += clamp(h, .01, stepDist), etc.
        dist += clamp(h, .01, .2); 
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (h<0. || dist > end) break; 
    }

    // I've added a constant to the final shade value, which lightens the shadow a bit. It's a preference thing. 
    // Really dark shadows look too brutal to me. Sometimes, I'll add AO also just for kicks. :)
    return min(max(shade, 0.) + .2, 1.); 
}

/*
// Standard normal function. It's not as fast as the tetrahedral calculation, but more symmetrical. Due to 
// the intricacies of this particular scene, it's kind of needed to reduce jagged effects.
vec3 getNormal(in vec3 p) {
	const vec2 e = vec2(0.0025, 0);
	return normalize(vec3(map(p + e.xyy) - map(p - e.xyy), map(p + e.yxy) - map(p - e.yxy),	map(p + e.yyx) - map(p - e.yyx)));
}
*/

/*
// Tetrahedral normal, to save a couple of "map" calls. Courtesy of IQ.
vec3 getNormal( in vec3 p ){

    // Note the slightly increased sampling distance, to alleviate
    // artifacts due to hit point inaccuracies.
    vec2 e = vec2(0.0025, -0.0025); 
    return normalize(
        e.xyy * map(p + e.xyy) + 
        e.yyx * map(p + e.yyx) + 
        e.yxy * map(p + e.yxy) + 
        e.xxx * map(p + e.xxx));
}
*/

// Normal calculation, with some edging and curvature bundled in.
vec3 getNormal(vec3 p, inout float edge, inout float crv) { 
	
    // Roughly two pixel edge spread, regardless of resolution.
    vec2 e = vec2(6./iResolution.y, 0);

	float d1 = map(p + e.xyy), d2 = map(p - e.xyy);
	float d3 = map(p + e.yxy), d4 = map(p - e.yxy);
	float d5 = map(p + e.yyx), d6 = map(p - e.yyx);
	float d = map(p)*2.;

    edge = abs(d1 + d2 - d) + abs(d3 + d4 - d) + abs(d5 + d6 - d);
    //edge = abs(d1 + d2 + d3 + d4 + d5 + d6 - d*3.);
    edge = smoothstep(0., 1., sqrt(edge/e.x*2.));
/*    
    // Wider sample spread for the curvature.
    e = vec2(12./450., 0);
	d1 = map(p + e.xyy), d2 = map(p - e.xyy);
	d3 = map(p + e.yxy), d4 = map(p - e.yxy);
	d5 = map(p + e.yyx), d6 = map(p - e.yyx);
    crv = clamp((d1 + d2 + d3 + d4 + d5 + d6 - d*3.)*32. + .5, 0., 1.);
*/
    
    e = vec2(.0015, 0); //iResolution.y - Depending how you want different resolutions to look.
	d1 = map(p + e.xyy), d2 = map(p - e.xyy);
	d3 = map(p + e.yxy), d4 = map(p - e.yxy);
	d5 = map(p + e.yyx), d6 = map(p - e.yyx);
	
    return normalize(vec3(d1 - d2, d3 - d4, d5 - d6));
}


// Normal calculation, with some edging and curvature bundled in.
vec3 getNormalRefr(vec3 p, inout float edge, inout float crv) { 
	
    // Roughly two pixel edge spread, regardless of resolution.
    vec2 e = vec2(6./iResolution.y, 0);

	float d1 = mapRef(p + e.xyy), d2 = mapRef(p - e.xyy);
	float d3 = mapRef(p + e.yxy), d4 = mapRef(p - e.yxy);
	float d5 = mapRef(p + e.yyx), d6 = mapRef(p - e.yyx);
	float d = mapRef(p)*2.;

    edge = abs(d1 + d2 - d) + abs(d3 + d4 - d) + abs(d5 + d6 - d);
    //edge = abs(d1 + d2 + d3 + d4 + d5 + d6 - d*3.);
    edge = smoothstep(0., 1., sqrt(edge/e.x*2.));
/*    
    // Wider sample spread for the curvature.
    e = vec2(12./450., 0);
	d1 = mapRef(p + e.xyy), d2 = mapRef(p - e.xyy);
	d3 = mapRef(p + e.yxy), d4 = mapRef(p - e.yxy);
	d5 = mapRef(p + e.yyx), d6 = mapRef(p - e.yyx);
    crv = clamp((d1 + d2 + d3 + d4 + d5 + d6 - d*3.)*32. + .5, 0., 1.);
*/
    
    e = vec2(.003, 0); //iResolution.y - Depending how you want different resolutions to look.
	d1 = mapRef(p + e.xyy), d2 = mapRef(p - e.xyy);
	d3 = mapRef(p + e.yxy), d4 = mapRef(p - e.yxy);
	d5 = mapRef(p + e.yyx), d6 = mapRef(p - e.yyx);
	
    return normalize(vec3(d1 - d2, d3 - d4, d5 - d6));
}

// Coloring\texturing the scene objects, according to the object IDs.
vec3 getObjectColor(vec3 p, vec3 n){
    
    // Object texture color, with some contract thrown in.
    vec3 tx = tex3D(iChannel0, p/3., n );
    tx = smoothstep(.1, .5, tx);
    
    // Coloring the tunnel walls.
    if(svObjID>.5) {
        
        tx *= vec3(1, .55, .35); // Brownish.

        // Optional: Extra crevice darkening from biological buildup. Adds
        // depth - addition to the shadows and AO. 
        tx *= smoothstep(.1, .6, surfFunc(p))*.6 + .4;
        
        // Alternative algae in the crevices.
        //float c = smoothstep(.1, .6, surfFunc(p));
        //tx *= vec3(c*c, c, c*c*c)*.6 + .4;
    }
    else tx *= vec3(.6, .8,  1); // Tinting the water blue, to give bluish reflections.

    
    return tx; // pow(tx, vec3(1.33))*1.66;
    
}

// Using the hit point, unit direction ray, etc, to color the scene. Diffuse, specular, falloff, etc. 
// It's all pretty standard stuff.
vec3 doColor(in vec3 sp, in vec3 rd, in vec3 sn, in vec3 lp, float edge, float crv, float t){
    
    // Initiate the scene (for this pass) to zero.
    vec3 sceneCol = vec3(0);
    
    if(t<FAR){ // If we've hit a scene object, light it up.
    
        vec3 ld = lp - sp; // Light direction vector.
        float lDist = max(length(ld), 0.001); // Light to surface distance.
        ld /= lDist; // Normalizing the light vector.

        // Attenuating the light, based on distance.
        float atten = 1.5/(1. + lDist*0.125 + lDist*lDist*0.025);

        // Standard diffuse term.
        float diff = max(dot(sn, ld), 0.);
        diff = pow(diff, 4.)*.66 + pow(diff, 8.)*.34;
        // Standard specualr term.
        float spec = pow(max( dot( reflect(-ld, sn), -rd ), 0.0 ), 32.0);
        //float fres = clamp(1. + dot(rd, sn), 0., 1.);
        //float Schlick = pow( 1. - max(dot(rd, normalize(rd + ld)), 0.), 5.0);
        //float fre2 = mix(.5, 1., Schlick);  //F0 = .5.

        // Coloring the object. You could set it to a single color, to
        // make things simpler, if you wanted.
        vec3 objCol = getObjectColor(sp, sn);

        // Combining the above terms to produce the final scene color.
        sceneCol = (objCol*(diff + 0.7 + vec3(1, .6, .2)*spec*2.));
        
        // Edges and curvature.
        //sceneCol *= clamp(crv, 0., 1.);
        //sceneCol += edge*.15;
        sceneCol *= 1. - edge*.9;
        

        // Attenuation only. To save cycles, the shadows and ambient occlusion
        // from the first pass only are used.
        sceneCol *= atten;
    
    }
    
  
    // Return the color. Done once for each pass.
    return sceneCol;
    
}

// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float calculateAO(in vec3 pos, in vec3 nor)
{
	float sca = 2.0, occ = 0.0;
    for( int i=0; i<5; i++ ){
    
        float hr = 0.01 + float(i)*0.5/4.0;        
        float dd = map(nor * hr + pos);
        occ += (hr - dd)*sca;
        sca *= 0.7;
    }
    return clamp( 1.0 - occ, 0.0, 1.0 );    
}



void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    // Screen coordinates.
	vec2 uv = (fragCoord.xy - iResolution.xy*.5) / iResolution.y;
    
    #ifdef THREE_D
    float sg = sign(fragCoord.x - .5*iResolution.x);
    uv.x -= sg*.25*iResolution.x/iResolution.y;
    #endif
    
	
	// Camera Setup.
	vec3 ro = vec3(0, 0, iTime*3.); // Camera position, doubling as the ray origin.
	vec3 lk = ro + vec3(0, 0, .25);  // "Look At" position.

   
    // Light position. Set in the vicinity the ray origin.
    vec3 lp = ro + vec3(0, .25, 3.);
    

    
   
	// Using the Z-value to perturb the XY-plane.
	// Sending the camera, "look at," and light vector down the tunnel. The "path" function is 
	// synchronized with the distance function.
    ro.xy += path(ro.z);
	lk.xy += path(lk.z);
	lp.xy += path(lp.z);
    
    #ifdef THREE_D
    ro.x -= sg*.15; lk.x -= sg*.15; lp.x -= sg*.15;
    #endif
    
    /*
    // Attempting to influence the camera with the wave motion. Needs a faster camera speed.
	// Anyway, it didn't make the cut, but it's a work in progress. :)
    float sfRo = surfFunc2(ro);
    float sfLk = surfFunc2(lk);
    ro.y += sfRo*.16;
    lk.y += sfLk*.12;
    */
    
    

    // Using the above to produce the unit ray-direction vector.
    float FOV = 3.14159/3.; // FOV - Field of view.
    vec3 forward = normalize(lk-ro);
    vec3 right = normalize(vec3(forward.z, 0., -forward.x )); 
    vec3 up = cross(forward, right);

    // rd - Ray direction.
    vec3 rd = normalize(forward + (uv.x*right + uv.y*up)*FOV);

    // Edge and curvature variables. Passed to the normal functions... The refraction
    // pass has seperate normal function.
    float edge = 0., crv = 1.;

    
    
    // FIRST PASS.
    
    float t = trace(ro, rd);
    svObjID = objID;
    float oSvObjID = svObjID;

    

    
    // Advancing the ray origin, "ro," to the new hit point.
    vec3 sp = ro + rd*t;
    
    // Retrieving the normal at the hit point, plus the edge and curvature values.
    vec3 sn = getNormal(sp, edge, crv);
    

    // Bump the water surface with some basic gradient noise.
    if(oSvObjID<0.5) sn = bumpMap(sp, sn, .02);
    
    // Fresnel. Handy for all kinds of aesthetic purposes, but here it'll be used 
    // as a transmission ratio for the reflection and refraction.
    float fr = clamp(1. + dot(rd, sn), 0., 1.);
    
    
    // Retrieving the color at the initial hit point.
    vec3 sceneColor = doColor(sp, rd, sn, lp, edge, crv, t);
    
    // Shading. Shadows, ambient occlusion, etc. We're only performing this on the 
    // first pass. Not accurate, but faster, and in most cases, not that noticeable.
    // In fact, the shadows almost didn't make the cut, but it didn't quite feel 
    // right without them.
    float sh = softShadow(sp + sn*.0011, lp, 16., t); // Set to "1.," if you can do without them.
    float ao = calculateAO(sp, sn);
    sh = (sh + ao*.3)*ao;
    
    // Fog - based off of distance from the camera. This will be applied at the end.
    float fog = smoothstep(0., .95, t/FAR);
    
    
    
   
    // SECOND PASS
    
    // Reflected and refracted rays.
    vec3 refl = reflect(rd, sn); // Standard reflection.
    vec3 refr = refract(rd, sn, 1./1.33); // Water refraction. Note the inverted index.
    
    // We're branching off from the same spot in two directions, so we'll use this so as
    // not to interfere with the original surface point vector, "sp." It was a style
    // choice on my part, but there are other ways.
    vec3 refSp; 
    
    // REFLECTED PASS
    
    // Standard reflected ray, which is just a reflection of the unit
    // direction ray off of the intersected surface. You use the normal
    // at the surface point to do that. Hopefully, it's common sense.


    // The ray is edged off the surface, as required, but note that it has to be enough
    // to avoid conflict with the break condition in the "reflected" trace algorithm. To
    // make things difficult, I've chosen a relaxed break condition to speed up the first
    // pass... but reflections (and shadows) require surface accuracy, so it's a choice 
    // between lag and accuracy, or speed and artifacts. I can't win. :) Having said that,
    // this example seems to be pretty free of artifacts.
    t = traceRef(sp + sn*0.0015, refl);
    svObjID = objID;
    
    // Advancing the ray from the new origin, "sp," to the new reflected hit point.
    refSp = sp + refl*t;
    
    // Retrieving the normal at the reflected hit point.
    sn = getNormal(refSp, edge, crv);//*rDir;
 
    
    vec3 reflColor = doColor(refSp, refl, sn, lp, edge, crv, t);
    
    #ifdef NO_RERACTION
    // Fake deeper water version. Just reflected water with no refraction. Obviously cheaper.
    if(oSvObjID<0.5) sceneColor = sceneColor*.1 +  reflColor*(fr*fr); 
    else sceneColor += reflColor*.5; // Add a portion of the reflection to the tunnel walls.
    #else    
    // REFRACTED PASS
    
    // If we hit the water surface, refract, retrieve the refracted color, then combine
    // it with the reflected color retrieved above.
    if(oSvObjID<0.5){  

        // Standard reflracted ray, which is just a refraction of the unit
        // direction ray from the intersected surface. You use the normal
        // at the surface point to do this also.

        t = traceRefr(sp - sn*.0025, refr);
        svObjID = objID;

        // Advancing the ray from the new origin, "sp," to the new refracted hit point.
        refSp = sp + refr*t;

        // Retrieving the normal at the reflected hit point.
        sn = getNormalRefr(refSp, edge, crv);

        vec3 refrColor = doColor(refSp, refr, sn, lp, edge, crv, t);
        
        // Add a small portion of the diffuse water color to the reflected and refracted colors.
        // The Fresnel value is used to provide a rough reflection to refraction ratio. It's based
        // on very rough science, but it gives a nice enough effect.
        sceneColor = sceneColor*.2 + mix(refrColor, reflColor, pow(fr, 5.)*.8 + .2)*vec3(.6, .8, 1);
        
    }
    else { // If the tunnel walls were hit, just add the reflected color from above.
        
        sceneColor += reflColor*.5; // Add a portion of the reflection to the tunnel walls.
        //sceneColor = mix(sceneColor, reflColor, fr*fr*fr*.75 + .25); // Another way.
        //sceneColor = sceneColor*.5 + mix(sceneColor, reflColor, .75); // etc.
    }
    #endif
   
   
    
    
    // APPLYING SHADOWS
    //
    // Multiply the shadow from the first pass by the final scene color. Ideally, you'd check to
    // see if the reflected point was in shadow, and incorporate that too, but we're cheating to
    // save cycles and skipping it. It's not really noticeable anyway.
    sceneColor *= sh;
    
    
    // APPLYING FOG
    // Blend in a bit of light fog for atmospheric effect. I really wanted to put a colorful, 
    // gradient blend here, but my mind wasn't buying it, so dull, blueish grey it is. :)
    vec3 fogCol = vec3(.7, .75, 1)*(rd.y*.25 + .75)*1.5;
    sceneColor = mix(sceneColor, fogCol, fog); // exp(-.002*t*t), etc. fog.zxy 
    
    
    // POSTPROCESSING
    // Interesting red to blueish mix.
    //sceneColor = mix(sceneColor, pow(min(vec3(1.5, 1, 1)*sceneColor, 1.), vec3(1, 2.5, 12.)), uv.y);
    sceneColor = pow(max(sceneColor, 0.), vec3(1.33))*1.66; // Adding a bit of contrast.
    
    
    // Subtle vignette.
    uv = fragCoord/iResolution.xy;
    sceneColor *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , .125)*.5 + .5;
    // Colored varation.
    //sceneColor = mix(pow(min(vec3(1.5, 1, 1)*sceneColor, 1.), vec3(1, 2.5, 12.)).zyx, sceneColor, 
                    // pow( 16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y) , .125)*.5 + .5);
    


    // Clamping the scene color, then presenting to the screen.
	fragColor = vec4(sqrt(clamp(sceneColor, 0.0, 1.0)), 1.0);
}