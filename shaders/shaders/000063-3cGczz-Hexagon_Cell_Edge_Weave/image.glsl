// Image (image) — Hexagon Cell Edge Weave by Shane
// https://www.shadertoy.com/view/3cGczz

/*

    Hexagon Cell Edge Weave
    -----------------------
    
    Using basic Wang tile techniques to create a cell-edge maze-like weave. I 
    cobbled this together from old code after looking a Fabrice Neyret's super 
    compact "intestine-maze 2" example. The pattern here might look different, 
    but employs a very similar concept.
    
    It makes use of an old trick that you may, or may not, have seen around. 
    Basically, you create a tessellated grid, then randomly assign zero and 
    one values to each cell. If the current cell and its neighboring edge cell 
    have different values, render that particular edge. The resultant pattern
    will resemble a random black and white polygon grid after running a 
    discretized edge algorithm over it.
    
    This particular example uses some extra trickery by moving the pattern to
    the center of the cell, then checking the difference between end point
    vertices for each edge, then rendering a line from the center to the edge
    mid-point. By doing it this way, it's possible to render overlapping lines 
    to form a weave pattern. The code here is more involved than Fabrice's 
    example, but offers some explanation along the way. However, if it's too 
    much, I put together a much simpler unlisted square grid example (linked 
    below) for anyone who'd like to see a simpler weaved version.
    
    There are a few defines laid out in the "Commom" tab for anyone interested.
    At some stage, I'll put together a 3D example.
    
    
    
    // Based on:
    
    // Employ roughly the same method, but with a square grid...
    // and way, way, less code. :)
    intestine-maze 2 (103 chars) -- FabricNeyret2
    https://www.shadertoy.com/view/wctcDj
    
    // A reasonably easy to follow square weave example...
    // Well, much easier to follow than this one. :)
    Random Cell Edge Weave -- Shane
    https://www.shadertoy.com/view/Wf3cWs
    
    // Minimal Wang tile example.
    Simple Wang Tile Example -- Shane
    https://www.shadertoy.com/view/ttXSzX
    
*/

 
// The six lines eminating from the cell center.
float[6] ln6;  

// Hash without Sine -- Dave Hoskins
// https://www.shadertoy.com/view/4djSRW
// 1 out, 2 in...
float hash21(vec2 p) {
    p = fract(p*vec2(123.34, 456.21));
    p += dot(p, p + 45.372);
    return fract(p.x*p.y);
}

// Tailoring the hash function to give longer pipe sections.
float rand(vec2 ip){

    // Forcing longer pipe runs.
    //ip = floor(ip/1.5);

    //return mod(dot(ip, vec2(13, 7)), 2.)<.5? hash21(ip)*.75 : hash21(ip);
    return hash21(ip);    
}
 

float hex; // Hexagon cell distance. 

// Space for up to three line distances.
vec3 d;
// Vertices.
float vert;


vec4 distField(vec2 p){
    
    // Edge and vertex ID values.
    //mat4x2 vID = mat4x2(vec2(-.5, -.5), vec2(-.5, .5), vec2(.5, .5), vec2(.5, -.5));
    //mat4x2 eID = mat4x2(vec2(-.5, 0), vec2(0, .5), vec2(.5, 0), vec2(0, -.5));
    vec2 s12 = s/12.;
    
    vec4 p4 = getGrid(p);
    vec2 ip = p4.zw;
    p = p4.xy;
    
    // Grid ID and local coordinates.
    //vec2 ip = floor(p/sc);
    //p -= (ip + .5)*sc; 
    
    // Grid squares, to place on the background.
    hex = getHex(p);//max(abs(p.x) - sc.x/2., abs(p.y) - sc.y/2.);
    
    
    // Six lines. Set to the maximum distance.
    int[6] ln6 = int[6](0, 0, 0, 0, 0, 0); 
    
    // Line total... This can be derived from the "edgeVal" value, but
    // it's easier.
    int lN = 0; 
    float edgeVal = 0.; // Edge value. Wang tile style. 
     
    // Threshold value (between zero and one).
    float thr = .5;
    
    // The random value assigned to each neighboring vertex.
    float[6] nVal;
    for(int i = 0; i<6; i++){
        #ifdef CLOSED_LOOPS
        nVal[i] = rand(ip + vID[i])<thr? 1. : 0.;
        #else
        nVal[i] = rand(ip + eID[i])<thr? 1. : 0.;
        #endif
    }
    
    // Iterate through each edge.
    for(int i = 0; i<6; i++){
      
        // If the vertex corner values (on or off) are different, 
        // render an edge. This is reminiscent of a discretized 
        // pixel edge algorithm, which pixel differnces beyond a 
        // certain threshold results in an edge.
        #ifdef CLOSED_LOOPS
        if(nVal[i] != nVal[(i + 1)%6]){
        #else
        if(nVal[i] != 0.){
        #endif
           
            // If the line vertex end values are differnt render aline 
            // from the cell center to the mid edge point between them.
            ln6[lN] = i;//distLine(p, vec2(0), eID[i]*s12) - .1*gSc.x;
            lN++; // Edge count.
            edgeVal += exp2(float(i)); // Bit trick to decipher edges.
 
        }
    }
     
    
    #if SHUFFLE_TYPE == 0
    // Randomly shuffling the variable array of points -- Six is the maximum. 
    // I think this is the Fisher–Yates method, but don't quote me on it.
    //
    for(int i = lN - 1; i>0; i--){
        
        // Using the cell ID and index to generate a unique random number.
        float fi = float(i);
        float rs = hash21(ip + .01 + fi/18.); // Random number.
        int j = int(rs*4800.)%(i + 1);
        // I think this does something similar to the line above.
        //int j = int(floor(rs*(fi + .9999)));
        
        int tmp = ln6[i]; ln6[i] = ln6[j]; ln6[j] = tmp;
        
    } 
    #else
    // Non-sophisticated random cyclic shuffle. This will keep the pattern
    // in closed loop form (if needed), whilst offering random connections.
    int[6] ln6B = ln6;
    int iSh = int(hash21(ip + vec2(.113, .157))*float(lN*36));
    for(int i = 0; i<lN; i++){
        ln6[i] = ln6B[(i + iSh)%lN];
    }
    #endif
    
    d = vec3(1e5);
    vert = 1e5;
    
    // Even lines.
    for(int i = 0; i<lN/2; i++){
  
        int i0 = ln6[i*2];
        int i1 = ln6[i*2 + 1];
        vec2 e0 = eID[i0]*s12;
        vec2 e1 = eID[i1]*s12;
        d[i] = doLine(p, e0, e1) - gSc.x/6.;
        vert = min(vert, min(length(p - e0), length(p - e1)));
    }
     
    // Odd single line.
    if(lN%2==1){
        int i0 = ln6[lN - 1];
        vec2 e0 = eID[i0]*s12;
        d[lN/2] = distLine(p, vec2(0), e0) - gSc.x/6.;
        vert = min(vert, length(p - e0));
    }
    
    
    
    // Debug: Pattern collapse.
    //d.x = min(min(d.x, d.y), d.z);
    //d.yz = vec2(1e5);
    
    #ifdef VERTICES
    // Vertex indentation.
    d = max(d, -vert);
    // Vertex size.
    vert -= .0075;
    #endif
    
    #ifdef BACKGROUND_DETAIL
    // Background hexagon pattern decoration.
    hex = max(hex, -(length(p) - gSc.x*.125));
    // Three edge prongs.
    int k = rand(ip)<.5? 1 : 0;
    for(int i = 0; i<3; i++){    
        hex = max(hex, -distLine(p, eID[i*2 + k]*s12*.25, eID[i*2 + k]*s12));
    }
    #endif
    
     
    // Pressed edges. Displays the individual segments.
    //d = max(d, -abs(hex) - .003);
    
    // Central channel.
    //d = abs(d + gSc.x/12. + .001) - (gSc.x/12. + .001);
    
  
    // One of four corner segments.
    //if(edgeVal<15. && mod(edgeVal, 3.)==0.){
 
    
    // Line distances (one or two), and the cell ID.
    return vec4(p, ip);
}
 

void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    // Aspect corret coordinates.
    vec2 iR = iResolution.xy;
    vec2 uv = (fragCoord - iR.xy*.5)/iR.y;
     

    // Scaling, rotation and translation.
    vec2 p = uv + vec2(.25, .5)*gSc*iTime;
   
     // Smoothing factor, shadow factor and edge width.
    float sf = 1./iR.y;
    float shF = iR.y/450.;
    float ew = .005;
    
    // 2D light.
    vec2 ld = normalize(vec2(1, 1));
    
    // Shadow sample.
    vec4 d4Sh = distField(p + ld*.02);
    vec3 d3Sh = d;
    
    // Highlighting sample.
    float px = 1e-5; // Sample spread.   
    vec4 d4Hi = distField(p + ld*px);
    vec3 d3Hi = d;
    float hexHi = hex;
    
    // Scene object.
    vec4 d4 = distField(p);
    vec3 d3 = d;
    
    
    // Random cell color.
    float rnd = hash21(d4.zw + .1);
    vec3 rCol = .5 + .5*cos(6.2831*rnd/12. + vec3(0, 1, 2)*1.5 - .4);
   
    vec3 pCol = mix(rCol*1.5, vec3(1, .8, .2), .3);  // Pipe color.
    
    // Pattern and hexagon directional derivative bump calculations.
    vec3 b3 = max((d3Hi - d3)/px, 0.);
    float diffHx = max((max(hexHi, -.01) - max(hex, -.01))/px, 0.);
    
   
   
    // Scene color -- Set to the background.
    vec3 col = max(rCol.zyx*.2, 0.);
    // Round lighting.
    //rCol *= max(.8 - hex/gSc.x, 0.);
    col = mix(col, rCol.zyx, 1. - smoothstep(0., sf, hex + ew*.8));

    // Hexagon diffuse lighting.
    col *= diffHx*.5 + .75;
  
     
    // Rendering onto the background.
    //
   
    // Faux shadow layer.
    d3Sh.x = min(min(d3Sh.x, d3Sh.y), d3Sh.z);
    col = mix(col, col*.65, 1. - smoothstep(0., sf*shF*4., d3Sh.x)); // AO.
       
    
    // Rendering one, two or three line objects.
    for(int i = 0; i<3; i++){ 
        
        // Line diffuse.
        float diff = b3[i]*.5 + .75;
        
        col = mix(col, col*.5, 1. - smoothstep(0., sf*shF*10., d3.x)); // AO.
        col = mix(col, col*.1, 1. - smoothstep(0., sf, d3.x)); // Edge, or stroke.
        col = mix(col, pCol*diff, 1. - smoothstep(0., sf, d3.x + ew)); // Top layer.
        
        // Next element. 
        d3 = d3.yzx;
    }
    
    #ifdef VERTICES 
    // Vertices.
    col = mix(col, col*.65, 1. - smoothstep(0., sf*shF*5., vert)); 
    col = mix(col, col*.1, 1. - smoothstep(0., sf, vert));  
    col = mix(col, pCol*vec3(.5, .3, .1), 1. - smoothstep(0., sf, vert + ew)); 
    #endif
    
    // Vignette.
    uv = fragCoord/iR.xy;
    col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , 1./16.)*1.1;


    // Output to screen
    fragColor = vec4(sqrt(max(col, 0.)), 1);
}