// Image (image) — Jigsaw by Shane
// https://www.shadertoy.com/view/XdGBDW

/*

	Jigsaw
	------
 
	I saw a few jigsaw images on the net and thought to myself that I'd set aside a few minutes
	to code one up. I wasn't aware of it until a few hours later, but it turns out that jigsaw
	patterns aren't as straight forward as you'd think... or I'm not particulary good at coding 
	jigsaw patterns. Either way, an embarrassing amount of time later, and here it is. :D

	Creating a 2D square jigsaw pattern requires a bit of finesse. Putting a wavy pattern together
    is more frustrating, but it can be done -- Constructing dissimilar interlocked asymmetrical 
    objects requires some thought. However, I started to realize that I might be in for more work 
    than I anticipated when I attempted to raymarch the pattern at a decent frame rate. :)

	I really try not to complicate things, but sometimes, it can't be avoided. Anyone familiar
	with rendering objects of varying heights across a repeat grid will know that rendering them 
    adjacent to one another isn't generally possible due to cell overlap artifacts. The only way 
	around it is to render every second grid cell across two dimensions (ensuring no object overlap), 
	then render three other grid combinations to fill in the spaces -- The return value being the 
	minimum distance of the four individual grid objects. Essentially, this means everything needs 
	to be rendered four times over, so even a mildy complicated object -- like a jigsaw piece -- 
	won't be feasible in real time... unless you can find a way to store calculations in a buffer.

	So, that's what I've done here. Luckily, the jigsaw pieces are extruded, so the 2D distance 
	field calculations can be precalculated and stored in a 2D texture, then read back. Even better, 
	all four calculations can be stored in each of the texture channels, which means just one call 
	in the distance field function. After that, there's still some extruded object construction
    and minimums to determine, but it involves significantly less calculation. In fact, my laptop
	can run this in fullscreen quite easily.
	
	I decided to jitter the shadows, ever so slightly. It definitely improves banding issues on 
	long shadow casts, but adds a slight amount of unecessary jitter to shadows that are in close
	proximity to the object. Overall, however, I felt it improved things significantly.

	In regard to the lighting and coloring, the scene is supposed to have a cardboard kind of 
	consistency... Not sure if it does entirely, but it turned out roughly the way I wanted.


    Interlocking Asymmetrical Examples:

	// Awesome example: This involves repetition of a single object and is achieved in realtime 
	// by reading the precalculated contour points from an array. Ultra also has a smooth
	// version of this.
	Shaded Horses - Ultraviolet
	https://www.shadertoy.com/view/lsXfDf

	// As above, it involves a single object, but is calculated on the fly.
	escherized tiling 2 (WIP) - FabriceNeyret2
	https://www.shadertoy.com/view/lsdBR7

*/


#define FAR 10.

// Gives a sheeny appearance. Intereting, but I prefer the flat look.
//#define FAKE_ENVIROMENT_REFLECTIONS

// Debug color overide. If you look in the "Common" tab, there's also a "FLAT_PATTERN" 
// define that will level the height out, effectively putting the pieces on a flat plane.
//#define GREY

// There's a slight perspective tilt on the camera, but this has a bit more -- to keep Dr2
// happy and give it less of a scrolling texture look. :)
//#define CAMERA_TWO



/*
// Tri-Planar blending function. Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: https://developer.nvidia.com/gpugems/GPUGems3/gpugems3_ch01.html
vec3 tex3D(sampler2D t, in vec3 p, in vec3 n ){
    
    n = max(abs(n), 0.001); //max(abs(n) - .2, 0.001); // etc.
    n /= dot(n, vec3(1));
	vec3 tx = texture(t, p.yz).xyz;
    vec3 ty = texture(t, p.zx).xyz;
    vec3 tz = texture(t, p.xy).xyz;
    
    // Textures are stored in sRGB (I think), so you have to convert them to linear space 
    // (squaring is a rough approximation) prior to working with them... or something like that. :)
    // Once the final color value is gamma corrected, you should see correct looking colors.
    return (tx*tx*n.x + ty*ty*n.y + tz*tz*n.z);
    
}
*/

 
// Global 2D surface value. It's poor programming practice putting it here. I'll 
// tidy this up later.
//float surf2D;


// Raymarching a textured XY-plane, with a bit of distortion thrown in.
float map(vec3 p){
    
    // Sampling the 2D jigsaw pattern value from the texture, then passing it
    // into a relatively cheap 3D extrusion function to give the final distance
    // value.
    vec4 jigDist = texture(iChannel0, p.xy/4. + .5);
    vec2 jig = jigsaw(p - vec3(moveXY(iTime), 0), jigDist);
    
    //surf2D = jig.y; // Just the 2D value. Used for some cheap edging.
 
    return jig.x*.866; // 3D extruded distance field value.
    
    
}


// Standard raymarching function.
float trace(in vec3 ro, in vec3 rd){

    float t = 0., d;
    
    for(int i = 0; i<80; i++){
    
        d = map(ro + rd*t);
        if(abs(d)<.001 || t>FAR) break; // Alternative: 0.001*max(t*.25, 1.)
        t += d;
    }

    return min(t, FAR);
    
}

// Cheap shadows are the bain of my raymarching existence, since trying to alleviate artifacts is an excercise in
// futility. In fact, I'd almost say, shadowing - in a setting like this - with limited  iterations is impossible... 
// However, I'd be very grateful if someone could prove me wrong. :)
float softShadow(vec3 ro, vec3 lp, float k, float t){

    // More would be nicer. More is always nicer, but not really affordable.
    const int maxIterationsShad = 24; 
    
    vec3 rd = lp - ro; // Unnormalized direction ray.

    float shade = 1.;
    float dist = .001;  // Coincides with the hit condition in the "trace" function.  
    float end = max(length(rd), .0001);
    //float stepDist = end/float(maxIterationsShad);
    rd /= end;
    
    dist += hash31(ro + rd)*.007;

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. Obviously, the lowest 
    // number to give a decent shadow is the best one to choose. 
    for (int i=0; i<maxIterationsShad; i++){

        float h = map(ro + rd*dist); //  map(ro + rd*dist + hash31(ro + rd)*dist*.03);
        //shade = min(shade, k*h/dist);
        shade = min(shade, smoothstep(0.0, 1.0, k*h/dist)); // Subtle difference. Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += min(h, .2), dist += clamp(h, .01, stepDist), etc.
        dist += clamp(h, .01, .25); 
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (h<0. || dist > end) break; 
    }

    // I've added a constant to the final shade value, which lightens the shadow a bit. It's a preference thing. 
    // Really dark shadows look too brutal to me. Sometimes, I'll add AO also just for kicks. :)
    return min(max(shade, 0.) + .05, 1.); 
}


// An AO routine, tweaked to suit this particular example, and based on IQ's original.
float calcAO(in vec3 p, in vec3 n){

	float sca = 5., occ = 0.;
    for( int i = 0; i<5; i++ ){
    
        float hr = float(i + 1)*.1/5.; 
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
    }
    
    return clamp(1. - occ, 0., 1.);
}


// Standard normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 normal(in vec3 p) {
	const vec2 e = vec2(.001, 0);
	return normalize(vec3(map(p + e.xyy) - map(p - e.xyy), map(p + e.yxy) - map(p - e.yxy),	map(p + e.yyx) - map(p - e.yyx)));
}

/*
// Standard 2x2 hash algorithm.
vec2 hash22G(vec2 p, float repScale) {

    p = mod(p, repScale);
    // Faster, but probaly doesn't disperse things as nicely as other methods.
    float n = sin(dot(p, vec2(27, 57)));
    return fract(vec2(2097152, 262144)*n)*2. - 1.;

}

// Gradient noise: Ken Perlin came up with it, or a version of it. Either way, this is
// based on IQ's implementation. It's a pretty simple process: Break space into squares, 
// attach random 2D vectors to each of the square's four vertices, then smoothly 
// interpolate the space between them.
float gradN2D(in vec2 f, float repScale){
  
   f *= repScale;
    
    // Used as shorthand to write things like vec3(1, 0, 1) in the short form, e.yxy. 
   const vec2 e = vec2(0, 1);
   
    // Set up the cubic grid.
    // Integer value - unique to each cube, and used as an ID to generate random vectors for the
    // cube vertiies. Note that vertices shared among the cubes have the save random vectors attributed
    // to them.
    vec2 p = floor(f);
    f -= p; // Fractional position within the cube.
    

    // Smoothing - for smooth interpolation. Use the last line see the difference.
    //vec2 w = f*f*f*(f*(f*6.-15.)+10.); // Quintic smoothing. Slower and more squarish, but derivatives are smooth too.
    vec2 w = f*f*(3. - 2.*f); // Cubic smoothing. 
    //vec2 w = f*f*f; w = ( 7. + (w - 7. ) * f ) * w; // Super smooth, but less practical.
    //vec2 w = .5 - .5*cos(f*3.14159); // Cosinusoidal smoothing.
    //vec2 w = f; // No smoothing. Gives a blocky appearance.
    
    // Smoothly interpolating between the four verticies of the square. Due to the shared vertices between
    // grid squares, the result is blending of random values throughout the 2D space. By the way, the "dot" 
    // operation makes most sense visually, but isn't the only metric possible.
    float c = mix(mix(dot(hash22G(p + e.xx, repScale), f - e.xx), dot(hash22G(p + e.yx, repScale), f - e.yx), w.x),
                  mix(dot(hash22G(p + e.xy, repScale), f - e.xy), dot(hash22G(p + e.yy, repScale), f - e.yy), w.x), w.y);
    
    // Taking the final result, and converting it to the zero to one range.
    return c*.5 + .5; // Range: [0, 1].
}

// Gradient noise fBm.
float fBm(in vec2 p, float repScale){
    
    return gradN2D(p, repScale)*.57 + gradN2D(p, repScale*2.)*.28 + gradN2D(p, repScale*4.)*.15;
    
}

*/


// With the spare cycles, I thought I'd splash out and use Dave's more reliable hash function. :)
//
// Dave's hash function. More reliable with large values, but will still eventually break down.
//
// Hash without Sine.
// Creative Commons Attribution-ShareAlike 4.0 International Public License.
// Created by David Hoskins.
// vec3 to vec3.
vec3 hash33G(vec3 p){

	p = fract(p * vec3(.1031, .1030, .0973));
    p += dot(p, p.yxz + 19.19);
    p = fract((p.xxy + p.yxx)*p.zyx)*2. - 1.;
    return p;
 /*   
    // Note the "mod" call. Slower, but ensures accuracy with large time values.
    mat2  m = rot2(mod(iTime, 6.2831853));	
	p.xy = m * p.xy;//rotate gradient vector
    p.yz = m * p.yz;//rotate gradient vector
    //p.zx = m * p.zx;//rotate gradient vector
	return p;
*/
}



/*
// Cheap vec3 to vec3 hash. I wrote this one. It's much faster than others, but I don't trust
// it over large values.
vec3 hash33G(vec3 p){ 
   
    //float n = sin(dot(p, vec3(7, 157, 113)));    
    //p = fract(vec3(2097152, 262144, 32768)*n)*2. - 1.; 
    
    //mat2  m = rot2(iTime);//in general use 3d rotation
	//p.xy = m * p.xy;//rotate gradient vector
    ////p.yz = m * p.yz;//rotate gradient vector
    ////p.zx = m * p.zx;//rotate gradient vector
	//return p;
    
    float n = sin(dot(p, vec3(27, 57, 111)));    
    return fract(vec3(2097152, 262144, 32768)*n)*2. - 1.; 

    
    //float n = sin(dot(p, vec3(7, 157, 113)));    
    //p = fract(vec3(2097152, 262144, 32768)*n); 
    //return sin(p*6.2831853 + iTime); 
}
*/


// Gradient noise, or Perlin noise. Break space into cubes, attach random 3D vectors to each of the eight 
// verticies, then smoothly interpolate between them. It's that simple. With the exception of some simple
// changes and some commentary addition, this is basically IQ's implementation.
// 
float gradN3D(in vec3 p){
   
    // Utilility bector.
    const vec2 e = vec2(0, 1);
    
    // Set up the cubic grid.
    // Integer value - unique to each cube, and used as an ID to generate random vectors for the
    // cube vertiies. Note that vertices shared among the cubes have the save random vectors attributed
    // to them.
    vec3 ip = floor(p); 
    
    p -= ip; // Fractional position within the cube.

    // Smoothing - for smooth interpolation. Comment it out to see the
    //vec3 w = p*p*p*(p*(p*6. - 15.) + 10.); // Quintic smoothing. Slower, but derivaties are smooth too.
    vec3 w = p*p*(3. - 2.*p); // Cubic smoothing. 
    //vec3 w = p*p*p; w = (7. + (w - 7.) * p) * w;	// Super smooth, but less practical.
    //vec3 w = .5 - .5*cos(p*3.14159); // Cosinusoidal smoothing.
    //vec3 w = p; // No smoothing. Gives a blocky appearance. Can look cool under the right conditions.
    
    // Smoothly interpolating between the eight verticies of the cube. Due to the shared verticies between
    // cubes, the result is blending of random values throughout the 3D space.
    float c = mix(mix(mix(dot(hash33G(ip + e.xxx), p - e.xxx), dot(hash33G(ip + e.yxx), p - e.yxx), w.x),
                      mix(dot(hash33G(ip + e.xyx), p - e.xyx), dot(hash33G(ip + e.yyx), p - e.yyx), w.x), w.y),
                  mix(mix(dot(hash33G(ip + e.xxy), p - e.xxy), dot(hash33G(ip + e.yxy), p - e.yxy), w.x),
                      mix(dot(hash33G(ip + e.xyy), p - e.xyy), dot(hash33G(ip + e.yyy), p - e.yyy), w.x), w.y), w.z);
    
    // Taking the final result, and putting it into the zero to one range.
    return c*.5 + .5; // Range: [0, 1].

}

// Gradient noise fBm.
float fBm3D(in vec3 p){
    
    return gradN3D(p)*.57 + gradN3D(p*2.)*.28 + gradN3D(p*4.)*.15;
}

#ifdef FAKE_ENVIROMENT_REFLECTIONS
// Simple environment mapping. Pass the reflected vector in and create some
// colored noise with it. The normal is redundant here, but it can be used
// to pass into a 3D texture mapping function to produce some interesting
// environmental reflections.
//
// More sophisticated environment mapping:
// UI easy to integrate - XT95    
// https://www.shadertoy.com/view/ldKSDm
vec3 eMap(vec3 rd, vec3 sn){
    
    vec3 sRd = rd; // Save rd, just for some mixing at the end.
    
    // Add a time component, scale, then pass into the noise function.
    rd.xy -= iTime*.25;
    rd *= 3.;
    
    //vec3 tx = tex3D(iChannel0, rd/3., sn);
    //float c = dot(tx*tx, vec3(.299, .587, .114));
    
    float c = fBm3D(rd);
    c = smoothstep(0.5, 1., c); // Darken and add contast for more of a spotlight look.
    
    //vec3 col = vec3(c, c*c, c*c*c*c).zyx; // Simple, warm coloring.
    //vec3 col = vec3(min(c*1.5, 1.), pow(c, 2.5), pow(c, 12.)).zyx; // More color.
    vec3 col = pow(vec3(1.5, 1, 1)*c, vec3(1, 2.5, 12)).zyx; // More color.
    
    // Mix in some more red to tone it down and return.
    return mix(col, col.yzx, sRd*.25 + .25); 
    
}
#endif

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    
    // Unit direction ray.
    vec3 rd = normalize(vec3(fragCoord - iResolution.xy*.5, min(iResolution.y, 800.)*.5));
    // Slight lens warping.
    rd = normalize(vec3(rd.xy, sqrt(rd.z*rd.z - dot(rd.xy, rd.xy)*.03)));
    
    //vec3 ro = vec3(0. + iTime/4., 0. + iTime/8., -1.5);
    // The camera movement is provided via texture scrolling. We're doing it
    // this way, because it'd be very difficult to wrap this particular 
    // pattern. Not impossible, but compilicated. Therefore, texture area
    // has to span beyond the canvas borders for the effect to work.
    vec3 ro = vec3(0, 0, -1.);
    // Light -- set up somewhere near the camera.
    vec3 lp = ro + vec3(-.25, .75, 0);
    
    
    // Tilting the camera ever so slightly.
    #ifdef CAMERA_TWO
    rd.yz *= rot2(-.2);
    rd.xy *= rot2(.1);
    #else
    rd.yz *= rot2(-.03);
    rd.xy *= rot2(.03);
    #endif
    
    
    // Standard raymarching segment. Because of the straight forward setup, very few 
    // iterations are needed.
    float t = trace(ro, rd);
    
    // Saving the unique cell ID and the 2D surface value.
    vec2 svCellID = cellID;
    //float svSurf2D = surf2D;
    
    // Initiate the scene color.
    vec3 col = vec3(0);
    
    // Trivial surface hit. I think all rays would hit this particular surface.
    if(t<FAR){
    
        vec3 sp = ro + rd*t;
        vec3 sn = normal(sp);
        vec3 l = lp - sp;
        float lDist = length(l);
        l /= max(lDist, .0001);

        //lDist /= 3.;
        float atten = 1./(1. + lDist*.05);

        // Ambient occlusion and shadows.
        float ao = calcAO(sp, sn);
        float sh = softShadow(sp + sn*.002, lp, 4., t); // Set to "1.," if you can do without them.
        sh = min(sh + ao*.2, 1.);


        float dif = max(dot(l, sn), 0.); // Diffuse term.
        dif *= dif; // Ramping up the diffuse.
        float spe = pow(max( dot( reflect(-l, sn), -rd ), 0.0 ), 32.); // Specular term.
        float fre = clamp(1.0 + dot(rd, sn), 0.0, 1.0); // Fresnel reflection term.

        // Schlick appoximation. It tones down the specular term.
        float Schlick = pow( 1. - max(dot(rd, normalize(rd + l)), 0.), 5.0);
        float fre2 = mix(.1, 1., Schlick);  //F0 = .2 - Hard clay... or close enough.

        // Texture value. Note that it's moving along XY to match the scrolling "Buf A" texture.
        vec3 tSp = sp;
        tSp.xy -= moveXY(iTime);
        
        // Shadertoy texture, but I went textureless for this one.
        //vec3 objCol = mix(tex3D(iChannel1, sp/1., sn), tex3D(iChannel1, sp*2., sn), .34);
        //vec3 objCol = tex3D(iChannel1, tSp/2., sn);//*texture(iChannel0, fract(sp.xy)).xyz;
        //objCol = smoothstep(-.3, .3, objCol);

        // COLORING THE JIGSAW PIECES.
        //
        vec3 objCol = vec3(1);
        // Some random colors based on the unique jigsaw piece ID. Used for coloring.
        vec3 rnd = vec3(hash(svCellID + 72.5), hash(svCellID + 37.1), hash(svCellID + 93.7));
        //vec3 rnd = hash33G(svCellID.xyx + vec3(72, 37, 93))*.5 + .5;
  
        // Random base colors. Orange tones, I think.
        vec3 cellCol = vec3(rnd.x*.2 + .8, rnd.z*.5 + .5, rnd.z*.3 + .3);
        
        // Mixing in some fire tones... I'll usually try this out if things aren't working. :)
        float c = dot(cellCol, vec3(.299, .587, .114));
        cellCol = cellCol*.5  + pow(min(vec3(1.5, 1, 1)*c, 1.), vec3(1, 3, 16));
        
        // Too much orange, so make some of them green for an autumn feel.
        if(rnd.y<=.5) cellCol = min(cellCol*2., 1.).yxz;

        // Color a portion of the pieces with the autumn palette, but leave some gray. It seemed
        // like a fun thing to do at the time. :)
        if(fract(rnd.x*289.97 + .73)>.15) objCol *= cellCol;
        
        objCol = mix(objCol, objCol.xzy, .15); // Tone the color down. 
        
        #ifdef GREY
        objCol = vec3(.9, 1.05, 1.2);
        #endif
        
        // Blue
        //objCol = objCol.zyx;
        // Pink.
        //objCol = objCol.xzy;
        // Grey tones.
        //objCol = vec3(1)*dot(cellCol, vec3(.299, .587, .114));
 

        // Matches the pylon routine in the "jigsaw" construction routine called
        // in the raymarching function.
        //
        float cellHeight = getCellHeight(svCellID); // Cell (jigsaw piece) height.
        
        // Put edges near the top of the block.
        objCol *= smoothstep(0., .003, abs(sp.z - cellHeight + .5 - .006) - .00075)*.8 + .2; // Dark edges.
     
        // Put a 2D pattern on the top of the block above the dark edge.
        if((abs(sp.z - cellHeight) - .5 + .006)>0.){
             //objCol *= smoothstep(0., .0075, max(-svSurf2D, 0.) - .01)*.8 + .2; // Dark edges.
             //objCol *= (1. - smoothstep(0., .01, -svH2 - .01))*.35 + 1.; // Light edges.
            
            // Wavy gradient contour pattern. You could put anything you want here, or nothing
            // at all if you're super boring. :)
            objCol *= clamp(-sin(fBm3D(vec3(tSp.xy, 0))*6.2831*96.)*5. + 2.9, 0., 1.)*.2 + .8;
            
        }
        
        // I originally put the pattern down the sides, but went with the 2D pattern above.
        //objCol *= clamp(-sin(fBm3D(tSp)*6.2831*96.)*4. + 2.9, 0., 1.)*.2 + .8;
        
        // Some gradient fBm sprinkles to break things up and give a slight papery feel.
        objCol *= fBm3D(tSp*80.)*.4 + .8;


        // Very basic lighting. Diffuse, ambient and specular.
        col = objCol*(dif + .25 + vec3(1, .7, .4)*spe*fre2);

		#ifdef FAKE_ENVIROMENT_REFLECTIONS
        // Add the fake environmapping. Not as good as a reflective pass, but it gives that
        // impresssion for just a fraction of the cost.
        vec3 em = eMap(reflect(rd, sn), sn); // Fake environment mapping.
        col += col*em*2.;
        #endif

        // Apply the light attenuation, ambient occlusion and shadows.
        col *= atten*ao*sh;
         
    }
    
    // Subtle vignette.
    vec2 uv = fragCoord/iResolution.xy;
    col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , .0625) + .1;
    // Colored variation.
    //col = mix(col.zyx/2., col, 
              //pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , .125));

    
    // Rough gamma correction.
    fragColor = vec4(sqrt(clamp(col, 0., 1.)), 1);
}