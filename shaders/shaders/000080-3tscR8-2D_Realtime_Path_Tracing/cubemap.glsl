// Cube A (cubemap) — 2D Realtime Path Tracing by Shane
// https://www.shadertoy.com/view/3tscR8

float dfGridObjects(vec2 p, vec2 ip, float sc){
    
    ip = mod(ip, repSc);
  
    float rnd = hash21(ip);
    vec2 rnd2 = hash22(ip);
    
    if(ip.x < .001) {
        sc *= .7; 
        
    }
    
    float sz = (.07 + rnd*.15)*sc*1.55;
    float d  = length(p - (rnd2 - .5)*.5*sc*1.) - sz;
    // Rotated Manhattan... Needs work, so circles it is. :)
    //p *= rot2(rnd*3.14159/4.);
    //float d = sBoxS(p - (rnd2 - .5)*.5*sc*1.2, vec2(sz*1.3), .8*sc);
    
    
    gIP = rnd2;
    
    return d;
}


// The Truchet pattern -- This one is animated, plus it has inner and outer 
// rails travelling in opposite directions, which I don't recall seeing here,
// but someone may have done it already.
float dfTruchet(vec2 p, vec2 ip, float sc){
    
   
   
    ip = mod(ip, repSc);
    
    // Unique random cell number.
    float rnd = hash21(ip);
    
    // Horizontally flip random cell tiles.
    if (rnd < .5) p = p.yx*vec2(1, -1);//p.y = -p.y; // p.x = -p.x, 
    
    
    // TRUCHET TILE.
    //
    // Two arcs, centered on diagonally opposite grid cell corners.
    
    // Circles, in opposite corners.
    float d1 = length(p - .5*sc) - .5*sc;
    float d2 = length(p + .5*sc) - .5*sc;
    
    
    // Individual polar coordinates.
    vec2 uv1 = vec2(d1, atan(p.y - .5*sc, p.x - .5*sc));
    vec2 uv2 = vec2(d2, atan(p.y + .5*sc, p.x + .5*sc));

   
     
    // Switch directions on alternate checkered cells. That's the standard
    // way it's done.
    if (mod(ip.x + ip.y, 2.)<.5) {
        uv1 *= -1.;
        uv2 *= -1.;
    }
    
    if (rnd < .5){
        uv1 *= -1.;
        uv2 *= -1.;
    }   
   
    // UV coordinates for each arc.
    float gTm = 0.;// Global time: iTime, etc.
    uv1 = vec2(uv1.x, fract(uv1.y*4./6.2831 + gTm));   
    uv2 = vec2(uv2.x, fract(uv2.y*4./6.2831 + gTm));   

 
    // Arc thickness.
    float th = .175/2.*sc;

    
    // Number of polar partitions. Any more than 2, and it starts to look
    // too busy.
    const float aSc = 1.;
    
    // Arc length. Range: [0, 1]. 
    float arcL = .6;
    
    // Scaling to get to the right range... Circle circumferance, etc. Annoying, fiddly stuff. :)
    arcL *= sc/3.1459/aSc;
    
    // The angular time component, which is set to twice that of the camera time to
    // allow the light to pass through the open gaps unhindered.
    float tm = iTime/3.;
     

    // Using the texture coordinates to render some repeat squares. You do this in the same
    // way that you'd render any repeat squares. The added complication is the inside and 
    // outside tracks moving in opposing directions, but it's not that difficult.
    
    // This relates to the arc tangent (uv.y) normalization process, since we divided by
    // this to convert so need to compensate. See above.
    sc *= (4./6.2831);
    
    // Inner and outer arcs subtended to the top-left grid cell corner.
    float tracksA = (mod(uv1.y + tm, 1./aSc) - 1./aSc/2.);
    float tracksB = (mod(uv1.y - tm, 1./aSc) - 1./aSc/2.);

    float tracks1 = sBoxS(vec2((uv1.x - (th + .002)), tracksA*sc), vec2((th - .002), arcL), .05*sc);
    float tracks2 = sBoxS(vec2((uv1.x + (th - .002)), tracksB*sc), vec2((th - .002), arcL), .05*sc);

    // Inner and outer arcs subtended to the bottom right grid cell corner.
    tracksA = (mod(uv2.y + tm, 1./aSc) - 1./aSc/2.);
    tracksB = (mod(uv2.y - tm, 1./aSc) - 1./aSc/2.);
    
    float tracks3 = sBoxS(vec2((uv2.x - (th + .002)), tracksA*sc), vec2((th - .002), arcL), .05*sc);
    float tracks4 = sBoxS(vec2((uv2.x + (th - .002)), tracksB*sc), vec2((th - .002), arcL), .05*sc);

    // Minimum inner and outer tracks.
    tracks1 = min(tracks1, tracks3);
    tracks2 = min(tracks2, tracks4);
    
    // ID for inner and out tracks. You could put more effort in here, but
    // this will do.
    gIP = tracks1<tracks2? vec2(0) : vec2(1);
    
    
    // Return the minimum distance.
    return min(tracks1, tracks2); 
    //d = max(d, sBox(p, vec2(.5*sc + .001))); // Used for neighbor checks.

    
}


// Iterating through grid neighbors at a particular scale. Fiddly coding, but necessary.
vec3 dfNeighbors(vec2 q){

    
    // Scale, ID, and distance field storage.
    float sc = 1./repSc;
    float d = 1e5;
    vec2 id = vec2(0);
    
    
    // It's funny. There are things that I deep down know won't work, but I'll try them
    // anyway, because I know how annoying doing it properly will be. This is a rendering
    // of a grid of offset circles. If you wish to offset them so there's cell overlap, you 
    // need to consider neighbors, which is fine.
    //
    // However, if you wish to bounce light around, things can be affected by objects that 
    // are several cells away. In this case, about 8 on either side. This means checking
    // a crazy number of cells -- The kind of numbers that would fry your GPU. Thankfully,
    // we can do this once at runtime, and store the overall distance field in a texture, or
    // one of the cube map faces, which is what we're doing here.
    
    int iters = min(0, iFrame) + 8;
    for(int j = -iters; j<=iters; j++){
        for(int i = -iters; i<=iters; i++){

 
            vec2 ip = floor(q/sc + vec2(i, j)*sc);
            
        	vec2 p = q - (ip + .5)*sc;
            
            float dij = dfGridObjects(p, ip, sc);
          
            if(dij<d) {
                d = dij;
                id = gIP;//ip;
            }
 
        }
    }
    

    
    return vec3(d, id);
    
}


// Loading a scaled distance field. In this case, it's the Truchet pattern. Technically,
// it might be more correct to check the neighboring cells, but we're trying to save cycles.
vec3 dfScale(vec2 p){

    
    // Scale, ID, and distance field storage.
    float sc = 2./repSc;
 
    // Cell ID and scale.
    vec2 ip = floor(p/sc);
    p -= (ip + .5)*sc;

    // The Truchet distance field.
    float d = dfTruchet(p, ip, sc);
    
    // Return the distance and object ID.
    return vec3(d, gIP);
    
}

void mainCubemap(out vec4 fragColor, in vec2 fragCoord, in vec3 rayOri, in vec3 rayDir){
    
    
    // UV coordinates.
    //
    // For whatever reason (which I'd love expained), the Y coordinates flip each
    // frame if I don't negate the coordinates here -- I'm assuming this is internal, 
    // a VFlip thing, or there's something I'm missing. If there are experts out there, 
    // any feedback would be welcome. :)
    vec2 uv = fract(fragCoord/iResolution.y*vec2(1, -1));
  
    // Pixel storage.
    vec3 col;
   
    // Initial conditions -- Performed just the once upon initialization.
    //if(abs(tx(iChannel0, uv).w - iResolution.y)>.001){
    //
    // IQ gave me the following tip, which saved me a heap of trouble and an extra channel. 
    // I'm not sure how he figured this out, but he pretty much knows everything. :D
    //
    // If the texture hasn't loaded, or if we're on the first frame, initialize whatever 
    // you wish to initialize. In this case, I'm precalculating an expensive distance
    // field and storing it in one of the cube map faces.
    #ifndef TRUCHET_PATTERN
    if(textureSize(iChannel0, 0).x<2 || iFrame<1){
        
        // INITIAL CONDITIONS.
       
        // Construct a distance field whilst seting the wrapping value, then store it.
        repSc = 16.;
        col = dfNeighbors(uv); // Distance field in X, and object IDs in YZ.
        //col.yz += .5;
        
    }
    else col = tx(iChannel0, uv).xyz;
    #else 
    
    // Construct a distance field whilst seting the wrapping value, then store it.
    repSc = 16.;
    col = dfScale(uv); // Distance field in X, and object IDs in YZ.
     
    #endif

    // Store in the cube map.
    fragColor = vec4(col, 1.);
    
}

