// Buffer A (buffer) — Exotic Particles by Shane
// https://www.shadertoy.com/view/3t3Bzj



// Start off with a function, warp it, and accumulate color along the way.
// This one is just a more mutated version of a simple sine warp function,
// of which there are plenty of examples on Shadertoy.
vec3 warp(vec2 u, float ph1, float ph2){

    // Initializing the warped UV coordinates. This gives it a bit 
    // of a worm hole quality. There are infinitly other mutations.
    vec2 v = u - log(1./max(length(u), .001))*vec2(-1, 1);
    
    // Scene color.
    vec3 col = vec3(0.);
    
    // Number of iterations.
    const int n = 5;
    
    for (int i = 0; i<n; i++){
    
        // Warp function.
        v = cos(v.y - vec2(0, 1.57))*exp(sin(v.x + ph1) + cos(v.y + ph2));
        v -= u;
        
        // Color via IQ's cosine palatte and shading.
        vec3 d = (.5 + .45*cos(vec3(i)/float(n)*3. + vec3(0, 1, 2)*1.5))/max(length(v), .001);
        // Accumulation.
        col += d*d/32.;
        
        // Adding noise for that fake path traced look. 
        // Also, to hide speckling in amongst noise. :)
        //col += fract(sin(u.xyy*.7 + u.yxx + dot(u + fract(iTime), 
        //             vec2(113.97, 27.13)))*45758.5453)*.01 - .005;
    }
    
    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){

    // Aspect correct UV coordinates.
    vec2 u = (fragCoord - iResolution.xy*.5)/iResolution.y*2.;

   
    // Angular offsets.
    float ph1 = iTime*.6;
    float ph2 = sin(iTime)*.25;
    
    // Adding two warp functions phase shifted by a certain amount was
    // Jolle's interesting addition. Just the one would work, but isn't
    // as interesting.
    vec3 col = warp(u, ph1, ph2) + warp(u, ph1, ph2 + 1.57);
    
    // Toning things down slightly.
    col = mix(col, col.zyx, .1);
    
    // Noise, for that fake path traced feel. :)
    //col.xyz += fract(sin(u.xyy*.7 + u.yxx + dot(u + fract(iTime), 
    //                 vec2(113.97, 27.13)))*45758.5453)*.1 - .05;    
    
    // Mix the previous frames in.
    vec4 preCol = texelFetch(iChannel0, ivec2(fragCoord), 0);
    float blend = (iFrame < 2) ? 1. : .25; 
    col = mix(preCol.xyz, col, blend);
    
    
    // Clamp and add to Buffer A.
    fragColor = vec4(clamp(col, 0., 1.), 1);
}