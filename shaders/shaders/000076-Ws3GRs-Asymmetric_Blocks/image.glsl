// Image (image) — Asymmetric Blocks by Shane
// https://www.shadertoy.com/view/Ws3GRs

/*

	Asymmetric Blocks
	-----------------

    Here's a cheap trick that I came up with to give the impression of random
    asymmetric rectangular tiling. The final implementation was a bit fiddly to 
    code, but I thought it fell into place nicely. However, it took me ages to 
	dream up something that'd work. Producing random packed rectangles in realtime, 
	even in pseudo form, isn't something you see much of, or at all, which surprises 
	me, since it's a common thing to see in the world of architecture, and so forth.

	There's a really cool way to use five edge Wang tiles, but it requires various 
	tileset restrictions, which I don't think would be easy to replicate in one pass
    on Shadertoy... or so I'd imagine. There are some pretty smart people on here,
    so you never know. :) Either way, in the meantime, here's a less sophisticated 
    method that seems to work well enough. Well, it fools my eyes anyway. :)

	As usual, I've dressed the pattern up a little, but the method itself is quite
	small and simple, so for anyone interested, the workings can be found in the
    "pattern" function.

	By the way, I wrote the algorithm in such a way that each brick returns a local
	position and position-based ID which means it can be used to render picture
	mosaics, and more importantly, can be adapted for raymarching purposes. In fact, 
	I have an example ready to go, which I'll put up when I've tidied it up a little.
    

    Similar Examples:

    To my knowledge, there aren't any, but here's an unlisted box divide version. 
    Unlike all other versions, it maintains aspect correctness and returns tile IDs 
    based on position.
	
    Box Divide ID - Shane.
	https://www.shadertoy.com/view/WlsSRs

*/

// Simple overlays.
//#define NAIVE_HATCH // I made this up a while back, and find it useful.
//#define PAPER_GRAIN

// Uncomment this to give it a cleaner look.
//#define UNTEXTURED

// Shadows almost always look better, but there are times when they might
// overcook things a little. I think they enhance this example, but it's
// all a matter of personal requirements. Turning them off gives it a 
// fresher, more naive, rendering style, which can sometimes be preferable.
#define SHADOWS

// Highlights -- Usually performed by taking a nearby sample, then adding a
// variation on the difference.
#define HIGHLIGHTS

// Palettes: Not many, but I might add more.
//#define GRAYSCALE

// Wobbling the coordinates, just a touch, in order to give the blocks a subtle 
// hand cut appearance. Turning this off will result in cleaner straight lines.
#define PERTURB_COORDINATES
    
// Display the square cell grid boundaries. It's there for debug purposes,
// but has a certain aesthetic appeal.
//#define SHOW_GRID


// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21(vec2 f){
    uvec2 p = floatBitsToUint(f);
    p = 1664525U*(p>>1U^p.yx);
    return float(1103515245U*(p.x^(p.y>>3U)))/float(0xffffffffU);
}


// Hacked together from IQ, Nimitz and Fabrice's hash functions.
vec2 hash22(in vec2 f){
     
    uvec2 p = floatBitsToUint(f);
    uint  n = 1103515245U*((p.x)^(p.y>>3U));
    // Converting a uint to a uvec3:
    // These numbers came from here:
    // Quality hashes collection WebGL2 - Nimitz.
    // https://www.shadertoy.com/view/Xt3cDn
    uvec2 rz = uvec2(n, n*48271U);
    return vec2((rz.xy >> 1) & uvec2(0x7fffffffU))/float(0x7fffffff)*2. - 1.;
    
    // Animated.
    //f = vec2((rz.xy >> 1) & uvec2(0x7fffffffU))/float(0x7fffffff);
    //return sin(f*6.2831853 + iTime); 
     
}


// Based on IQ's gradient noise formula.
float n2D3G( in vec2 p ){
   
    vec2 i = floor(p); p -= i;
    
    vec4 v;
    v.x = dot(hash22(i), p);
    v.y = dot(hash22(i + vec2(1, 0)), p - vec2(1, 0));
    v.z = dot(hash22(i + vec2(0, 1)), p - vec2(0, 1));
    v.w = dot(hash22(i + 1.), p - 1.);

#if 1
    // Quintic interpolation.
    p = p*p*p*(p*(p*6. - 15.) + 10.);
#else
    // Cubic interpolation.
    p = p*p*(3. - 2.*p);
#endif

    return mix(mix(v.x, v.y, p.x), mix(v.z, v.w, p.x), p.y);
    //return v.x + p.x*(v.y - v.x) + p.y*(v.z - v.x) + p.x*p.y*(v.x - v.y - v.z + v.w);
}

// A hatch-like algorithm, or a stipple... or some kind of textured pattern.
float doHatch(vec2 p, float res){
    
    
    // The pattern is physically based, so needs to factor in screen resolution.
    p *= res/16.;

    // Random looking diagonal hatch lines.
    float hatch = clamp(sin((p.x - p.y)*3.14159*200.)*2. + .5, 0., 1.); // Diagonal lines.

    // Slight randomization of the diagonal lines, but the trick is to do it with
    // tiny squares instead of pixels.
    float hRnd = hash21(floor(p*6.) + .73);
    if(hRnd>.66) hatch = hRnd;  


    return hatch;

    
}

// IQ's box function with a smoothing factor added.
float sBoxS(in vec2 p, in vec2 b, in float rf){
  
    vec2 d = abs(p) - b + rf;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - rf;
}

/*
// IQ's standard box function.
float sBox(in vec2 p, in vec2 b){
   
  vec2 d = abs(p) - b;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.));
}
*/

// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21B(vec2 f){
    uvec2 p = floatBitsToUint(f);
    p = 1664525U*(p>>1U^p.yx);
    return (float(1103515245U*(p.x^(p.y>>3U)))/float(0xffffffffU) - .5)*.75;
}

// The asymmetric block pattern.
//
// By the way, you could take a simple line-drawing and partitioning approach to greatly
// minimize the instruction count, and if 2D bump mapping effects, etc, are all you're
// after, it might be worth doing. However, if you wish to raymarch this, or do other
// interesting things, the four rectangles, and corresponding IDs, are a necessary evil.
vec3 pattern(vec2 p, float sc){

    vec2 ip = floor(p*sc) + .5; // Grid ID.
    p -= ip/sc; // Local coordinates.
    
    vec3 e = vec3(-1, 0, 1); // Helper vector.
    
    float h11 = hash21B(ip); // Original cell.
    
    float h10 = hash21B(ip + e.xy); // Left.
    float h01 = hash21B(ip + e.yz); // Top.
    float h12 = hash21B(ip + e.zy); // Right.
    float h21 = hash21B(ip + e.yx); // Bottom.
    
    float h00 = hash21B(ip + e.xz); // Top left.
    float h02 = hash21B(ip + e.zz); // Top right.
    float h22 = hash21B(ip + e.zx); // Bottom right.
    float h20 = hash21B(ip + e.xx); // Bottom left.
      
     
    vec2[4] ctr;
    vec2[4] l;
    
    
    // The code looks fiddly, but it's based on a simple idea.
    // A while ago, I noticed that if you ran vertical and 
    // horizontal lines on alternate checkered tiles, you could
    // render perpendicular lines on either side at random
    // positions and everything would line up to form rectangles.
    // The following is just an implementation of that.
    
    // If you uncomment the SHOW_GRID define you'll see that 
    // each cell consists of either a vertical line flanked on
    // either side by horizontal lines at random Y-positions, or 
    // a horizontal line flanked on either side by vertical
    // lines at random X-positions.
    
    // Implementing the aforementioned is simple enough. However, 
    // lines are great, but cell boundaries -- in order to
    // render things like blocks would be the thing we'd be more 
    // interested in rendering, so that requires a little more
    // work.   	
    
    
    
    if(mod((ip.x + ip.y), 2.)<.5){ // Horizontal cell.

        // Partition the cell with a randomly positioned horizontal 
        // line and two joining randomly positioned vertical lines
        // then determine the cell dimensions and cell center of
        // all four resultant rectangular blocks.
        
        // Four block dimensions (X: Width, Y: Height).
        l[0] = vec2(h01 - h10, h00 - h11) + 1.;
        l[1] = vec2(-h01 + h12, h02 - h11) + 1.;
        l[2] = vec2(-h21 + h12, -h22 + h11) + 1.;
        l[3] = vec2(h21 - h10, -h20 + h11) + 1.;
        
        // Four block centers.
        ctr[0] = vec2(h01, h11) + l[0]*vec2(-.5, .5);
        ctr[1] = vec2(h01, h11) + l[1]*vec2(.5, .5);
        ctr[2] = vec2(h21, h11) + l[2]*vec2(.5, -.5);
        ctr[3] = vec2(h21, h11) + l[3]*vec2(-.5, -.5); 

    }
    else { // Vertical cell.

        // Partition the cell with a randomly positioned vertical 
        // line and two joining randomly positioned horizontal lines
        // then determine the cell dimensions and cell center.
        
        // Four block dimensions (X: Width, Y: Height).
        l[0] = vec2(-h00 + h11, h01 - h10) + 1.;
        l[1] = vec2(h02 - h11, h01 - h12) + 1.;
        l[2] = vec2(h22 - h11, -h21 + h12) + 1.;
        l[3] = vec2(-h20 + h11, -h21 + h10) + 1.;
        
        // Four block centers.
        ctr[0] = vec2(h11, h10) + l[0]*vec2(-.5, .5);
        ctr[1] = vec2(h11, h12) + l[1]*vec2(.5, .5);
        ctr[2] = vec2(h11, h12) + l[2]*vec2(.5, -.5);
        ctr[3] = vec2(h11, h10) + l[3]*vec2(-.5, -.5); 
        

    }
                                                                             

    // Debugging: Show the squares with a set single dimension.
    //l[0] = l[1] = l[2] = l[3] = vec2(.7); // Overlapping: vec2(1.5); 
    
    // Scaling down the block dimensions.
    l[0] /= sc; l[1] /= sc; l[2] /= sc; l[3] /= sc;
    
    
    
    // Determine the minimum block using the standard method.
    float d = 1e5;
    vec2 tileID = vec2(0);
    //vec2 ctri = vec2(0);
    //vec2 li = vec2(0);
     
    for(int i = 0; i<4; i++){
    	 
    	float bx = sBoxS(p - ctr[i]/sc, l[i]/2. - .05/sc, .1/sc);
        
        if(bx<d) {
            d = bx;
            tileID = ip + ctr[i];
            //ctri = ctr[i];
            //li = l[i];
        }
        
    }
    
    
    // Return the distance value of the closed rectangular block
    // and it's cell center, which doubles as a unique ID. By the
    // way, you could also return the the tile center and dimensions,
    // if you wished to render other things.
    return vec3(d, tileID);

}



// The square grid.
float gridField(vec2 p){
    
    p = abs(fract(p) - .5);
    float grid = abs(max(p.x, p.y) - .5) - .008;
    
    return grid;
}


void mainImage(out vec4 fragColor, in vec2 fragCoord){
    

    // Aspect correct screen coordinates.
    float iRes = min(iResolution.y, 750.);
	vec2 uv = (fragCoord - iResolution.xy*.5)/iRes;
    
    // Scaling and translation.
    
    // You could rotate also, if you felt like it: rot2(a)*uv...
    // Depending on perspective; Moving the oject toward the bottom left, 
    // or the camera to the north east (top right) direction. 
    vec2 p = uv - vec2(-1, -.25)*iTime/12.;
    
    // Keeping a copy of the background vector.
    vec2 oP = p;

    // The smoothing factor -- based on scale.
    float sf = 1.5/iResolution.y;
  
    #ifdef PERTURB_COORDINATES
    // Wobbling the coordinates, just a touch, in order to give a subtle hand drawn appearance.
    p += vec2(n2D3G(p*8.5), n2D3G(p*8.5 + 7.3))*.008;
    #endif
    
    // The grid block scaling -- as opposed to the global scaling, which is set to 
    // one for this example.
    const float sc = 12.;
    
    
    
    // Take two pattern samples.
    vec3 d = pattern(p, sc);
    vec2 e = vec2(.005*8./sc, -.007*8./sc);
    vec3 d2 = pattern(p - e, sc);
    
 
    // Highlighting the objects.
    float ba = mix(min(-d.x*4., .1), smoothstep(0., sf*2., -d.x), .1);
    float bb = mix(min(-d2.x*4., .1), smoothstep(0., sf*2., -d2.x), .1);
    float b = max(-bb - -ba, 0.)/length(e);


    // Coloring each individual tile using the ID. It's scaled down by the scaling
    // factor to bring the texture into view.
    vec3 tx = texture(iChannel0, d.yz/sc).xyz; tx *= tx;
    tx = smoothstep(-.1, .7, tx);
    
    // Mixing in a regular non-mosaic texture in with it.
    vec3 tx2 = texture(iChannel1, oP).xyz; tx2 *= tx2;
    tx2 = smoothstep(-.1, .6, tx2);
    tx2 = mix(tx2, vec3(1)*dot(tx2, vec3(.299, .587, .114)), .25);
    
    
    // Just a dark background. You only see this between the tiles. If I were 
    // putting in effort, I'd probably have to arrange for some mortar to put 
    // between the blocks.
    vec3 col = vec3(.725, .7, .675)*tx2*tx2/3.;
    
    #ifdef UNTEXTURED
    col = vec3(.1);
    #endif

    
    // Apply the line shadows and the fist layer object shadows.
    #ifdef SHADOWS
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, d2.x - .003))*.9);
    #endif
    
    
    
    #ifdef UNTEXTURED
    // Using the ID for a shade.
    vec2 rnd = hash22(d.yz);
    vec3 lCol = vec3(1, .5 + rnd.y*.5, rnd.x*.4 + .4)*.75 + .15;
    // Fabrice's candy colored palette.
    //vec3 lCol = .6 + .3*cos(6.3*rnd.x + vec3(0, 23, 21));
    #else
    // Setting the block color to the texture at the specific ID position.
    vec3 lCol = (tx2*2.)*tx*1.; 
    #endif
    
    
    
    
    #ifdef HIGHLIGHTS
    lCol *= (1. + b*.125);
    #endif


    // The Pattern.
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*3., d.x - .002))*.9);
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, d.x - .002)));
    col = mix(col, lCol, (1. - smoothstep(0., sf, d.x + .002)));  

    
    #ifdef SHOW_GRID
    // The grid.
    float grid = gridField(p*sc);
  
    vec3 svC = col;
    // Display the grid boundaries. Usually used for debug purposes.
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*1.5*sc, grid - .05))*.9);
    col = mix(col, mix(svC.zyx*1.5, vec3(1, 1, 4), .5), (1. - smoothstep(0., sf*sc, grid)));
    #endif
    
    
    // POST PROCESSING
    #ifdef GRAYSCALE
    col = vec3(1)*dot(col, vec3(.289, .597, .114));
    #endif

    
    #ifdef NAIVE_HATCH
    float hatch = doHatch(oP, iRes);
    col *= hatch*.5 + .7;
    #endif
    
    #ifdef PAPER_GRAIN
    // Cheap paper grain.
    oP = floor(oP*1024.);
    vec3 rn3 = vec3(hash21(oP), hash21(oP + 2.37), hash21(oP + 4.83));
    col *= .9 + .1*rn3.xyz  + .1*rn3.xxx;
    #endif

    
    // Subtle vignette.
    uv = fragCoord/iResolution.xy;
    col *= min(pow(16.*(1. - uv.x)*(1. - uv.y)*uv.x*uv.y, 1./8.)*1.1, 1.);
    
    // Output to screen
    fragColor = vec4(sqrt(max(col, 0.)), 1);
}