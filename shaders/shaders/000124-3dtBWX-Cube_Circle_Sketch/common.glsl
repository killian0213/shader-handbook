// Common (common) — Cube Circle Sketch by Shane
// https://www.shadertoy.com/view/3dtBWX


//  Vertices and edge midpoints: Clockwise from the bottom left. -- Basically, the ones 
// above rotated anticlockwise. :)
vec2[6] vID = vec2[6](vec2(-.5, -2./6.)/vec2(.5, 1), vec2(-.5, 2./6.)/vec2(.5, 1), vec2(0, 2./3.)/vec2(.5, 1), 
                      vec2(.5, 2./6.)/vec2(.5, 1), vec2(.5, -2./6.)/vec2(.5, 1), vec2(0, -2./3.)/vec2(.5, 1));
//vec2[6] eID = vec2[6](vec2(-.5, 0)/vec2(.5, 1), vec2(-.25, .5)/vec2(.5, 1), vec2(.25, .5)/vec2(.5, 1), 
                      //vec2(.5, 0)/vec2(.5, 1), 
                      //vec2(.25, -.5)/vec2(.5, 1), vec2(-.25, -.5)/vec2(.5, 1));


// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// IQ's vec2 to float hash.
float hash21(vec2 p){  
    return fract(sin(mod(dot(p, vec2(27.619, 57.583)), 6.2831589))*43758.5453); 
}


// Unsigned distance to the segment joining "a" and "b".
float distLine(vec2 a, vec2 b){
     
	b = a - b;
	float h = clamp(dot(a, b)/dot(b, b), 0., 1.);
    return length(a - b*h);
}

// IQ's box formula -- Modified slightly.
float sBoxS(in vec2 p, in vec2 b, in float rf){
  
  vec2 d = abs(p) - b + rf;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - rf;
    
}

// IQ's box formula.
float sBox(in vec2 p, in vec2 b){
  
  vec2 d = abs(p) - b;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.));
}

// This renders a horizontal or vertical box-line from point "a" to point "b," with a line 
// width of "w." It's different to the the usual line formula because it doesn't render the 
// rounded caps on the end -- Sometimes, you don't want those. It utilizes IQ's box formula 
// and was put together in a hurry, so I'd imagine there are more efficient ways to do the 
// same, but it gets the job done. I put together a more generalized angular line formula as 
// well.
float lBoxHV(vec2 p, vec2 a, vec2 b, float w){
    
   vec2 l = abs(b - a); // Box-line length.
   p -= vec2(mix(a.x, b.x, .5), mix(a.y, b.y, .5)); // Positioning the box center.
   
   // Applying the above to IQ's box distance formula.
   vec2 d = abs(p) - (l + w)/2.; 
   return min(max(d.x, d.y), 0.) + length(max(d, 0.));
}

// This will draw a box (no caps) of width "ew" from point "a "to "b". I hacked
// it together pretty quickly. It seems to work, but I'm pretty sure it could be
// improved on. In fact, if anyone would like to do that, I'd be grateful. :)
float lBox(vec2 p, vec2 a, vec2 b, float ew){
    
    float ang = atan(b.y - a.y, b.x - a.x);
    p = rot2(ang)*(p - mix(a, b, .5));
    
   vec2 l = vec2(length(b - a), ew);
   return sBox(p, (l + ew)/2.) ;
}

// IQ's distance to a regular pentagon, without trigonometric functions. 
// Other distances here:
// https://iquilezles.org/articles/distfunctions2d
//
#define NV2 4
//
float sdPoly4(in vec2 p, in vec2[NV2] v){

    const int num = v.length();
    float d = dot(p - v[0],p - v[0]);
    float s = 1.0;
    for( int i = 0, j = num - 1; i < num; j = i, i++){
    
        // distance
        vec2 e = v[j] - v[i];
        vec2 w =    p - v[i];
        vec2 b = w - e*clamp(dot(w, e)/dot(e, e), 0., 1. );
        d = min( d, dot(b,b) );

        // winding number from http://geomalgorithms.com/a03-_inclusion.html
        bvec3 cond = bvec3( p.y>=v[i].y, p.y<v[j].y, e.x*w.y>e.y*w.x );
        if( all(cond) || all(not(cond)) ) s*=-1.0;  
    }
    
    return s*sqrt(d);
}

// Signed distance to a regular hexagon -- using IQ's more exact method.
float sdHexagon(in vec2 p, in float r){
    
  const vec3 k = vec3(-.8660254, .5, .57735); // pi/6: cos, sin, tan.

  // X and Y reflection.
  p = abs(p);
  p -= 2.*min(dot(k.xy, p), 0.)*k.xy;
    
  // Polygon side.
  return length(p - vec2(clamp(p.x, -k.z*r, k.z*r), r))*sign(p.y - r);
    
}

// Determines which side of a line a pixel is on. Zero is the threshold.
float line(vec2 p, vec2 a, vec2 b){
     return ((b.x - a.x)*(p.y - a.y) - (b.y - a.y)*(p.x - a.x));
}

/*
// Cheap and nasty 2D smooth noise function with inbuilt hash function -- based on IQ's 
// original. Very trimmed down. In fact, I probably went a little overboard. I think it 
// might also degrade with large time values.
float n2D(vec2 p) {

	vec2 i = floor(p); p -= i; p *= p*(3. - p*2.);  
    
	return dot(mat2(fract(sin(vec4(0, 1, 113, 114) + dot(i, vec2(1, 113)))*43758.5453))*
               vec2(1. - p.y, p.y), vec2(1. - p.x, p.x) );

}
*/

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
    h = fract(sin(mod(h, 6.2831589))*43758.5453);
   
    // Interpolation.
    h.xy = mix(h.xy, h.zw, p.y);
    return mix(h.x, h.y, p.x); // Output: Range: [0, 1].
}

// FBM -- 4 accumulated noise layers of modulated amplitudes and frequencies.
float fbm(vec2 p){ return n2D(p)*.533 + n2D(p*2.)*.267 + n2D(p*4.)*.133 + n2D(p*8.)*.067; }


vec3 pencil(vec3 col, vec2 p){
    
    // Rough pencil color overlay... The calculations are rough... Very rough, in fact, 
    // since I'm only using a small overlayed portion of it. Flockaroo does a much, much 
    // better pencil sketch algorithm here:
    //
    // When Voxels Wed Pixels - Flockaroo 
    // https://www.shadertoy.com/view/MsKfRw
    //
    // Anyway, the idea is very simple: Render a layer of noise, stretched out along one 
    // of the directions, then mix similar, but rotated, layers on top. Whilst doing this,
    // compare each layer to it's underlying greyscale value, and take the difference...
    // I probably could have described it better, but hopefully, the code will make it 
    // more clear. :)
    // 
    // Tweaked to suit the brush stroke size.
    vec2 q = p*4.;
    const vec2 sc = vec2(1, 12);
    q += (vec2(n2D(q*4.), n2D(q*4. + 7.3)) - .5)*.03;
    q *= rot2(-3.14159/2.5);
    // I always forget this bit. Without it, the grey scale value will be above one, 
    // resulting in the extra bright spots not having any hatching over the top.
    col = min(col, 1.);
    // Underlying grey scale pixel value -- Tweaked for contrast and brightness.
    float gr = (dot(col, vec3(.299, .587, .114)));
    // Stretched fBm noise layer.
    float ns = (n2D(q*sc)*.66 + n2D(q*2.*sc)*.34);
    //
    // Repeat the process with a couple of extra rotated layers.
    q *= rot2(3.14159/2.);
    float ns2 = (n2D(q*sc)*.66 + n2D(q*2.*sc)*.34);
    q *= rot2(-3.14159/5.);
    float ns3 = (n2D(q*sc)*.66 + n2D(q*2.*sc)*.34);
    //
    // Compare it to the underlying grey scale value.
    //
    // Mix the two layers in some way to suit your needs. Flockaroo applied common sense, 
    // and used a smooth threshold, which works better than the dumb things I was trying. :)
    const float contrast = 1.;
    ns = (.5 + (gr - (max(max(ns, ns2), ns3)))*contrast); // Same, but with contrast.
    //ns = smoothstep(0., 1., .5 + (gr - max(max(ns, ns2), ns3))); // Different contrast.
    // 
    // Return the pencil sketch value.
    return vec3(clamp(ns, 0., 1.));
    
}
