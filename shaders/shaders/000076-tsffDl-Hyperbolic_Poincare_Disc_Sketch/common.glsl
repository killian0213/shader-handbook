// Common (common) — Hyperbolic Poincare Disc Sketch by Shane
// https://www.shadertoy.com/view/tsffDl

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }

// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21(vec2 f){
    //f = mod(f + 16384., 16384.); // Annoying GPU hash related hack.
    uvec2 p = floatBitsToUint(f + 1024.);
    p = 1664525U*(p>>1U^p.yx);
    return float(1103515245U*(p.x^(p.y>>3U)))/float(0xffffffffU);
}


////////////////
// Compact, self-contained version of IQ's 2D value noise function.
float n2D(vec2 p){
   
    // Setup.
    // Any random integers will work, but this particular
    // combination works well.
    const vec2 s = vec2(47, 113);
    // Unique cell ID and local coordinates.
    vec2 ip = floor(p); p -= ip;
    // Vertex IDs.
    vec4 h = vec4(0., s.x, s.y, s.x + s.y) + dot(ip, s);
   
    // Smoothing.
    p = p*p*(3. - 2.*p);
    //p *= p*p*(p*(p*6. - 15.) + 10.); // Smoother.
   
    // Random values for the square vertices.
    //h = fract(sin(mod(h, 6.2831853))*43758.5453);
    // Randomizing using Dave Hoskins's hash formula.
    h = fract(h*.1031); h *= h + 42.5273; h = fract(h*h*2.);
   
    // Interpolation.
    h.xy = mix(h.xy, h.zw, p.y);
    return mix(h.x, h.y, p.x); // Output: Range: [0, 1].
}

float sBoxS(in vec2 p, in vec2 b, in float rf){
  
  vec2 d = abs(p) - b + rf;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - rf;
    
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
    // of the directions, then mix a similar, but rotated, layer on top. Whilst doing this,
    // compare each layer to it's underlying greyscale value, and take the difference...
    // I probably could have described it better, but hopefully, the code will make it 
    // more clear. :)
    // 
    // Tweaked to suit the brush stroke size.
    vec2 q = p*4.;
    const vec2 sc = vec2(1, 12);
    q += (vec2(n2D(q*4.), n2D(q*4. + 7.3)) - .5)*.03;
    q *= rot2(-3.14159/2.5);
    // Extra toning.
    col /= 1./3. + dot(col, vec3(.299, .587, .114));
    // I always forget this bit. Without it, the grey scale value will be above one, 
    // resulting in the extra bright spots not having any hatching over the top.
    col = min(col, 1.);
    // Underlying grey scale pixel value -- Tweaked for contrast and brightness.
    float gr = (dot(col, vec3(.299, .587, .114)));
    // Stretched fBm noise layer.
    float ns = (n2D(q*sc)*.64 + n2D(q*2.*sc)*.34);
    // Compare it to the underlying grey scale value.
    ns = gr - ns;
    //
    // Repeat the process with a couple of extra rotated layers.
    q *= rot2(3.14159/2.);
    float ns2 = (n2D(q*sc)*.64 + n2D(q*2.*sc)*.34);
    ns2 = gr - ns2;
    q *= rot2(-3.14159/5.);
    float ns3 = (n2D(q*sc)*.64 + n2D(q*2.*sc)*.34);
    ns3 = gr - ns3;
    //
    // Mix the two layers in some way to suit your needs. Flockaroo applied common sense, 
    // and used a smooth threshold, which works better than the dumb things I was trying. :)
    ns = min(min(ns, ns2), ns3) + .5; // Rough pencil sketch layer.
    //ns = smoothstep(0., 1., min(min(ns, ns2), ns3) + .5); // Same, but with contrast.
    // 
    // Return the pencil sketch value.
    return vec3(ns);
    
}
