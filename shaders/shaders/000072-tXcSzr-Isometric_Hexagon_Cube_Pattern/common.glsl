// Common (common) — Isometric Hexagon Cube Pattern by Shane
// https://www.shadertoy.com/view/tXcSzr


// I accidently left this in. Flat top hexagons make more sense, but it 
// looks pretty interesting with this commented out, so I've left it in.
#define FLAT_TOP

// PI and 2 PI.
#define PI 3.14159265357989
#define TAU 6.2831853


// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21(vec2 f){

    // The first line relates to ensuring that icosahedron vertex identification
    // points snap to the exact same position in order to avoid hash inaccuracies.
    uvec2 p = floatBitsToUint(f + 16384.);
    p = 1664525U*(p>>1U^p.yx);
    return float(1103515245U*(p.x^(p.y>>3U)))/float(0xffffffffU);
}

 
// Ssigned line distance. Based on IQ's original, but with a sign addition.
float distLineS(vec2 p, vec2 a, vec2 b){ 
   
   b = min(b - a, 1.);
   return dot(p - a, vec2(-b.y, b.x)/length(b));
  
    /*
    // More correct.
    //if(a == b) return -1e5;
    p -= a, b -= a;
    float h = clamp(dot(p, b)/dot(b, b), 0., 1.);
    // JT's GPU determinant-based sign. Not sure if it's faster, or not.
    //float s = determinant(mat2(b, p))<0.? -1. : 1.;
    // Unfortunately, the GPU "sign" function returns zero for certain pixel.
    // which we can't have for this function, so this is the workaround.
    float s = b.x*p.y<b.y*p.x? -1. : 1.;
    return length(p - b*h)*s;
    */
     
}

// Signed distance to a hexagon -- IQ.
//
// List of other 2D distances:
// https://iquilezles.org/articles/distfunctions2d
// and https://www.shadertoy.com/playlist/MXdSRf

float sdHex(vec2 p, float r){ 


 
    #ifdef FLAT_TOP
    // Flat top hexagon.
    const vec3 k = vec3(-.866025404, .5, .577350269);
    p = abs(p);
    p -= 2.*min(dot(k.xy, p),0.)*k.xy;
    p -= vec2(clamp(p.x, -k.z*r, k.z*r), r);
    return length(p)*sign(p.y);
    #else
    
    // Modified to render a pointed top hexagon.
    const vec3 k = vec3(.5, -.866025404, .577350269);
    p = abs(p);
    p -= 2.*min(dot(k.xy, p),0.)*k.xy;
    p -= vec2(r, clamp(p.y, -k.z*r, k.z*r));
    return length(p)*sign(p.x);    
    
    
    #endif
}


////////////////
// Compact, self-contained version of IQ's 2D value noise function.
float n2D(vec2 p){
   
    // Setup.
    // Any random integers will work, but this particular
    // combination works well.
    const vec2 s = vec2(1, 113);
    // Unique cell ID and local coordinates.
    vec2 ip = floor(p); p -= ip;
    // Vertex IDs.
    vec4 h = vec4(0., s.x, s.y, s.x + s.y) + dot(ip, s);
   
    // Smoothing.
    p = p*p*(3. - 2.*p);
    //p *= p*p*(p*(p*6. - 15.) + 10.); // Smoother.
   
    // Random values for the square vertices.
    h = fract(sin(mod(h, TAU))*43758.5453);
   
    // Interpolation.
    h.xy = mix(h.xy, h.zw, p.y);
    return mix(h.x, h.y, p.x); // Output: Range: [0, 1].
}


// FBM -- 2 accumulated noise layers of modulated amplitudes and frequencies.
float fbm2(vec2 p){ return n2D(p)*.66 + n2D(p*2.)*.34; } 

// FBM -- 4 accumulated noise layers of modulated amplitudes and frequencies.
float fbm(vec2 p){ return n2D(p)*.533 + n2D(p*2.)*.267 + n2D(p*4.)*.133 + n2D(p*8.)*.067; }

vec2 gUV;
vec3 pencil(vec2 p, vec3 col){
  
    
    // Rough pencil color overlay... The calculations are rough... Very rough, in fact, 
    // since I'm only using a small overlayed portion of it. Flockaroo does a much, much 
    // better pencil sketch algorithm here:
    //
    // When Voxels Wed Pixels - Flockaroo 
    // https://www.shadertoy.com/view/MsKfRw
    //
    // Anyway, the idea is very simple: Render a layer of noise, stretched out along one 
    // of the directions, then mix a similar, but rotated, layer on top. Whilst doing this,
    // compare each layer to it's underlying greyscale value, and take the difference...
    // I probably could have described it better, but hopefully, the code will make it 
    // more clear. :)
    // 
    // Tweaked to suit the brush stroke size.
    vec2 q = p*24.;
    const vec2 sc = vec2(1, 24);
   
    q += (vec2(n2D(q*8.), n2D(q*8. + 7.3)) - .5)*.05;
    q *= rot2(3.14159/10.);
    // Extra toning.
    //col /= (1.5 + col)/2.5;
    // I always forget this bit. Without it, the grey scale value will be above one, 
    // resulting in the extra bright spots not having any hatching over the top.
    col = min(col, 1.);
    // Und8erlying grey scale pixel value -- Tweaked for contrast and brightness.
    float gr = (dot(col, vec3(.299, .587, .114)));
    // Stretched fBm noise layer.
    gr = pow(gr, .4)*.9;
    
    float amp = 1.;
    float ns = 1e5;
    #define N 8
    for(int i = 0; i<N; i++){
    
        //if(gr>float(N - 1 - i)/float(N)) break;
        float nsI = gr - fbm2(q*sc);//(n2D(q*sc)*.64 + n2D(q*2.*sc)*.34);
        // Compare it to the underlying grey scale value.
        ns = min(ns, nsI*amp + .0*(.5 - float(i)/float(N)));//
        //ns = min(mix(ns, nsI, 1.-float(i)/float(N)), nsI);
        //
        // Repeat the process with a couple of extra rotated layers.
        q *= rot2(TAU/float(N) + .1*fract(float(i)*.77));
        q += 1.13/float(i + 1);
        //q *= 1.1;
        
        //amp /= 1. + 1./float(N);
    }
    //
    // Mix the two layers in some way to suit your needs. Flockaroo applied common sense, 
    // and used a smooth threshold, which works better than the dumb things I was trying. :)
    //ns = min(min(ns, ns2), ns3) + .5; // Rough pencil sketch layer.
    ns = smoothstep(-.25, .25, ns); // Same, but with tapering.
    // 
    // Return the pencil sketch value.
    return vec3(ns);
    
}

// Photoshop style soft light layering. 
float softLight( float s, float d ){

	return (s < .5) ? d - (1. - 2.*s)*d*(1. - d) 
		: (d < .25) ? d + (2.*s - 1.)*d*((16.*d - 12.)*d + 3.) 
					: d + (2.*s - 1.)*(sqrt(d) - d);
}

// Color layering function. It's pretty easy to apply all the Photoshop
// styles, but here, we're only interested in the soft light function.
vec3 colFunc(vec3 s, vec3 d){
    
    // There's probably a GPU "all" related function that could do
    // all of this in a more elegant way, but this will do.
    vec3 c;
	c.x = softLight(s.x, d.x);
	c.y = softLight(s.y, d.y);
	c.z = softLight(s.z, d.z);
	return c;

}
