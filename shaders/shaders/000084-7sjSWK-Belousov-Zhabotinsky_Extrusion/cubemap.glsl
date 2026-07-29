// Cube A (cubemap) — Belousov-Zhabotinsky Extrusion by Shane
// https://www.shadertoy.com/view/7sjSWK

// Global scale.
float gSc = 512.;

// IQ's vec2 to float with wrapping.
float hash21(vec2 p) {

    p = mod(p, gSc);
    return fract(sin(dot(p, vec2(42.5137, 13.7963)))*43758.5453); 
}
 
// Cube texture read.
vec4 tx(vec2 p){ 
    
    return texture(iChannel0, vec3(fract(p) - .5, .5));
}

/*
// Blur function. Pretty standard.
vec4 bTx(in vec2 p, const int N){
    
    // Result.
	vec4 c = vec4(0);
    float sum = 0.;

    // NxN blur.
    for(int i = 0; i<N*N; i++) {
        vec2 offs = vec2(i/N, i%N) - floor(float(N) - .5)/2.;
        float l = max(length(vec2(N)/2.) - length(offs), 0.); l *= l;
        //float l = exp(-(dot(offs, offs)/float(N*N))/2.)/float(N)*.39894;
        //float l = 1./(1. + dot(offs, offs)*.5);
        c += tx(p - (offs)/iResolution.y)*l;
        sum += l;
    }
    
    return c/sum; 
    
}
*/

// Circle blur function -- Not as common, but you see it around. Sometimes,
// taking a sweep at a certain radius can give you a blurrier result
// without the cost. It's especially efficient when taking the difference
// between different size filters.
vec4 bTxCir(in vec2 p, float r){
    

    // Result.
	vec4 c = vec4(0);
    float sum = 0.;
    
    const int N = 12;

    // NxN blur.
    for(int i = 0; i<N; i++) {
        float ang = float(i)*6.2831/float(N);
        vec2 offs = vec2(cos(ang), sin(ang))*r;
        float l = 1.;//max(length(vec2(N)/2.) - length(offs), 0.); l *= l;
        //float l = exp(-(dot(offs, offs)/float(N*N))/2.)/float(N)*.39894;
        //float l = 1./(1. + dot(offs, offs)*.5);
        c += tx(p - (offs)/iResolution.y)*l;
        sum += l;
    }
    
    return c/sum; 
    
}

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }



void mainCubemap(out vec4 fragColor, in vec2 fragCoord, in vec3 rayOri, in vec3 rayDir){
    
    
    //float a = mod(float(iFrame), 8.)*3.14159/4.;// + rot2(a)*vec2(0, .5)
    // UV coordinates.
    //
    // For whatever reason (which I'd love expained), the Y coordinates flip each
    // frame if I don't negate the coordinates here -- I'm assuming this is internal, 
    // a VFlip thing, or there's something I'm missing. If there are experts out there, 
    // any feedback would be welcome. :)
    vec2 uv = fract(fragCoord/iResolution.y*vec2(1, -1));
    
    gSc = 1.;
 
    // Pixel storage.
    vec4 col;
   
    // Initial conditions -- Performed upon initiation.
    if(abs(tx(uv).w - iResolution.y)>.001){
    
        // Initial conditions: Fill each channel in each cell with some random values.
        col = vec4(hash21(uv), hash21(uv + .17), hash21(uv + .23), 1.);
        col.w = iResolution.y;
    }
    else {
    
        // A very rough Belousov–Zhabotinsky reaction approximation -- Feel free to look
        // up the process in detail, but it's similar to many reaction diffusion like
        // examples: Start off with an initial solution in the form of noise in one or 
        // some of the channels, use filters to blur it over time to similute dispersion,
        // then mix the result with the previous frame. In this case, we can simulate 
        // non-equilibrium by sprinkling in extra noise for volatility... As mentioned,
        // there are others on the net and on Shadertoy who can give you more detail, but
        // that's the general gist of it.
        
        // Thinking a little outside the box, it's possible to use a much cheaper 
        // radial boundary blur with a larger radius to mickick a larger block blur. 
        // It doesn't work in all situations, but it works well enough here.
        vec4 val = bTxCir(uv, 5.); // 12 Taps.
        val = mix(val, tx(uv), 1./25.); // Adding the center pixel.
        //vec4 val = bTx(uv, 7); // Box blur: 49 taps -- Requires rescaling.
        
        //#if 0
        // Alternate, simpler equation.
        //col = clamp(tx(uv) + .08*(val.zxyw - val.yzxw), 0., 1.);
        //#else
        float reactionRate = val.x*val.y*val.z; // Self explanitory.
        //float reactionRate = smoothstep(0., 1., val.x*val.y*val.z); 

        // Producing the new value: For an explanation, you can look up the chemical
        // reaction it pertains to and the mathematical translation which is pretty
        // interesting. From a visual perspective, however, it's just a cute calculus 
        // based equation that produces a cool pattern over time.
        vec4 res = val - reactionRate + val*(val.yzxw - val.zxyw);
        //vec4 params = vec4(1, 1, 1, 0);//
        //vec4 res = val - reactionRate + val*(params*val.yzxw - params.zxyw*val.zxyw);
        
        
 

        // Adding some volatile noise to the system. 
        vec3 t = vec3(1.01, 1.07, 1.03)*fract(iTime);
        vec4 ns = vec4(hash21(uv + .6 + t.x), hash21(uv + .2 + t.y), hash21(uv + .7 + t.z), 0);
        
        // Mixing the new value and noise with the old value. 
        col = mix(tx(uv), res*(.9 + ns*.3), .2*iTimeDelta*60.);
        //#endif
        
 
        // Using the fourth channel to store resolution.
        col.w = iResolution.y;
    
    }
    
    // Recording the new value and clamping it to a certain range.
    fragColor = vec4(clamp(col.xyz, -1., 1.), iResolution.y);
}