// Image (image) — Cube Circle Sketch by Shane
// https://www.shadertoy.com/view/3dtBWX

/*
	
	Cube Circle Sketch
	------------------

	I see a lot of really classy geometric styled pencil drawings on 
    the internet by various mathematical artists -- The effort that 
    goes into some of them is really impressive. Reproducing them in 
    code form is kind of cheating, but it's a little hard to resist. :)

	This particular arrangement is pretty common and something I've 
    seen many times in various forms, but most tend to be based off of 
    the works of mathematical artist Regolo Bizzi -- His Escheresque
    geometric designs are everywhere, but if you've never chanced upon 
    one of them, I've provided a link below. A lot of love and effort 
    would have gone into the original sketch, but the effort that went
    into the code version was far less impressive: Render 12 hexagons 
    on the border of a circle, orient them a bit (by PI/6), then shade 
    the faces. 
    
    There's some extra code to give it that tech drawing feel, fake 
    lighting and a mediocre sketch algorithm included, but that's it.

	Anyway, I was more interested in producing a halfway passable look
	in order to render more interesting patterns. Suggestions for 
	simple improvements are always welcome. :)



    // Links.

    // You can find some of Regolo Bizzi's work at the following:
    http://impossible-world.blogspot.com/2014/10/new-images-by-regolo-bizzi.html
    https://www.behance.net/regolo

*/


// Cube subdivision lines. Interesting, but a bit much, I think. :)
//#define SUBDIV_LINES 

// Greyscale sketch -- Sans color.
//#define GREYSCALE

// Blinking lights: It was an attempt to animate the sketch in a believable
// way... This isn't it. :D
//#define BLINKING_LIGHTS


void mainImage(out vec4 fragColor, in vec2 fragCoord){

    // Aspect correct screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
    
    // Scaling and translation.
    const float gSc = 1.;
    
    // Smoothing factor.
    float sf = gSc/iResolution.y;
    
    // Rotation speed -- Rotation seemed like a good idea at the time, but
    // I decided against it. :)
    float rT = 0.;//sin(-iTime/6.*3.)/12.;

    // Scaling and rotation.
    vec2 p = rot2(rT)*uv*gSc;
    
    // Distance field holders for the cubes, lines and the previous
    // cube (used for CSG related to overlap).
    float d = 1e5, ln = 1e5, prevD = 1e5; 
    
    // Edge width. 
    const float ew = .0025;
    
   
    // The cubes are rendered along the sides of a dodecahedron. These are just some standard
    // measurements to help place the cubes in the correct positions.
    //
    const float cR = .3; // Larger circle radius.
    const float cAp = cR*cos(6.2831/24.); // Apothem.
    const float sL = cR*acos(6.2831/24.)/2.; // Side length, which will relate to the hexagon scale.
    
    
        // The offset vertex information.
    // Hexagon vertices with scaling to enable rendering back in normal space. 
    vec2 hSc = sL*vec2(.5, .8660254);
    vec2[6] svV = vec2[6](vID[0]*hSc, vID[1]*hSc, vID[2]*hSc, vID[3]*hSc, vID[4]*hSc, vID[5]*hSc);

   
    // Coordinate perturbation. There's small rigid one to enhance the hand-drawn look, and
    // a larger animated one to wave the paper around a bit.
    vec2 offs = vec2(fbm(p*16.), fbm(p*16. + .35));
    vec2 offs2 = vec2(fbm(p*1. + iTime/4.), fbm(p*1. + .5 + iTime/4.));
    const float oFct = .007;
    const float oFct2 = .05;
    p -= (offs - .5)*oFct;
    p -= (offs2 - .5)*oFct2;
    
 
    
    
    float lnL = -cR - sL*.75; // Line length.
    float a0 = 6.2831/24.; // Initial reference angle.
    float dA = 6.2831/12.; // One twelth revolution.
    float inR =  cR - sL/2.*.8660254; // Inner radius. 
    
    
    // Some distance field holders.
    float gHex = 1e5, gD = 1e5, qLn = 1e5, dSh = 1e5;
    // Z buffer, for shadows.
    float zBuf = 0.;
    
    
    
    // Fake lighting.
    vec3 lp = vec3(-.75, 3, -1.5);
    vec3 ld = normalize(lp - vec3(uv, 0)); 
    ld.xy = rot2(rT)*ld.xy;
    
    
    // Initialize the background.
    vec3 col = vec3(.95, .975, 1);
    
    
    vec2 q; 
    
    // Apply some graph lines.
    float dim = 9.; // For the lines to match up: dim = 9./(cR*3.);
    q = p;//uv*gSc - (offs - .5)*oFct  - (offs2 - .5)*oFct2;//uv*gSc - (offs - .5)*oFct;//p;//
    q = abs(mod(q, 1./dim) - .5/dim);
    float ln3 = abs(max(q.x, q.y) - .5/dim);
    col = mix(col, vec3(.35, .65, 1), (1. - smoothstep(0., sf*2., ln3))*.8);
    dim *= 2.;
    q = p;//uv*gSc - (offs - .5)*oFct  - (offs2 - .5)*oFct2;//uv*gSc - (offs - .5)*oFct;//p;//
    q = abs(mod(q, 1./dim) - .5/dim);
    ln3 = max(abs(max(q.x, q.y) - .5/dim), -ln3);
    col = mix(col, vec3(.35, .65, 1), (1. - smoothstep(0., sf*2., ln3))*.65);
    
    // Applying light and a bit of noise to the background.
    col *= clamp(dot(normalize(vec3(p, -1.5)), ld), 0., 1.)*.2 + .8;
    col *= fbm(p*8.)*.1 + .9;
    
    
    // Produce and render the 12 cubes. This is pretty standard stuff -- Position
    // the cubes and render three rhomboids for the cube faces.
    
    // Cube face normals.
    vec3[3] n = vec3[3](vec3(1, 0, 0), vec3(0, 1, 0), vec3(0, 0, -1));
       

    // Iterate through all 12 cubes -- Some will note that you could apply polar
    // coordinates and cut this right down to two iterations, which would definitely
    // be faster. However, the example isn't too taxing on the system, and the
    // brute force method simplifies the code a bit... Having said that, I might
    // cave in an update this later. :)
    //
    for(int i = 0; i<12; i++){
        
        q = p;
        
        // Grey lines point to point lines.
        vec2 a, b, nA;
        a =  rot2(a0 + dA*float(i))*vec2(0, inR);
        b =  rot2(a0 + dA*float(i + 3))*vec2(0, inR);
        nA = normalize(b - a)*sL*1.6;
        ln = min(ln, lBox(q, a - nA, b + nA, 0.));
        
        
        // Hexagons.
        vec2 hCtr = rot2(6.2831/12.*float(11 - i))*vec2(0, cR); // Hexagon center.
        q -= hCtr; // Move to the border.
        q = rot2(-6.2831/12.*float(11 - i))*q; // Rotate in situ.
        //q = rot2(iTime/3.)*q; // Rotate individual hexagons.
        float dH = sdHexagon(q, sL/2.); // Hexagon distance field.
        d = dH;
        
        // Hexagon or cube shadows.
        vec2 qSh = p + ld.xy*.03;
        qSh -= hCtr;
        qSh = rot2(-6.2831/12.*float(11 - i))*qSh;
        dSh = sdHexagon(qSh, sL/2.);
        
        // All hexagons.
        gHex = min(gHex, d);
        
        // Grey hexagon circle outlines.
        ln = min(ln, abs(length(q) - sL/2./.8660254));
        
        // Cutting out the previous hexagon to avoid overlap. A Z-buffer would
        // also work, and might be cleaner, but it's done now. :)
        d = max(d, -(prevD - ew/3.));
        
        prevD = d; 
        
        // Shadow and shadow buffer -- Needs fixing, but it'll do for now.
        col = mix(col, mix(vec3(0), col, zBuf), (1. - smoothstep(0., sf*5., dSh - ew/2.))*.35);
        zBuf = mix(zBuf, 1., (1. - smoothstep(0., sf*5., dSh - ew/2.))); 
  
        // Combination of all objects... It was used to rotate things in combination with
        // the sketch algorithm, but I decided against it.
        gD = min(gD, min(min(ln, d), dSh));
        
        // Rendering the hexagon base -- Not entirely necessary, but it enhance the edges.
        col = mix(col, vec3(0), (1. - smoothstep(0., sf*6., d - ew/2.))*.35); // Fake AO.
        col = mix(col, vec3(0), (1. - smoothstep(0., sf, d - ew/2.))*.8);
        //col = mix(col, vec3(1), (1. - smoothstep(0., sf, d + ew - ew/2.)));
          
          
             
        // Iterate through the three cube faces.
        for(int j = 0; j<6; j+=2){
        
            // Constructing the edge midpoints and normals at those
            // points for both the string and corresponding shadows.
            vec2[4] v = vec2[4](svV[(j + 1)%6].yx, svV[(j + 2)%6].yx, svV[(j + 3)%6].yx, vec2(0));

            // Quad center and local quad ID.
            vec2 qCtr = (v[0] + v[1] + v[2] + v[3])/4.;
            vec2 qID = hCtr + qCtr;
            
            // Face quad.
            float quad = max(sdPoly4(q, v), d);
            
            // Accumulated quad field.
            gD = min(gD, quad);
            
            // Spectrum or rainbow colors.
            vec3 rnbCol = .6 + .4*cos(6.2831*float(i)/12. + vec3(0, 1, 2)*1.5 + 3.14159/6.);
            
            #ifdef BLINKING_LIGHTS
            float rndI = hash21(hCtr); rndI = cos(rndI*6.2831 + iTime/1.25 + .5);
            rndI = smoothstep(.9, .95, sin(rndI*6.2831 + iTime*3.)*.5 + .5);
            
            vec3 rCol = vec3(.55) + float(i%3)/12.;//vec3(hash21(hCtr + .6)*.35 + .5);
            rCol = mix(rCol, dot(rCol, vec3(.299, .587, .114))*vec3(4, 1, .5), rndI);
            rCol = mix(rCol, rCol.xzy, sin(hash21(hCtr + .44)*6.2831 + iTime)*.35 + .35);
            
            // Alternative.
            //vec3 rCol = rnbCol;
            //rCol = mix(rCol, rnbCol*1.5, rndI);
            #else
            vec3 rCol = rnbCol;
            #endif
            
  
            // Face normal.
            vec3 sn = n[j/2];
            // Rotate the face normals about the XY axis -- Since this isn't 3D, we
            // need to fake it.
            sn.xy = rot2(6.2831/12.*float(11 - i))*sn.xy;
             
            // Using the quad distance field for a bit of shading. In this case, it
            // gives the cubes a subtle faux ambient occulsion feel.
            float sh = clamp(.35 - quad/.03, 0., 1.)*.3 + .7;
            // Standard diffuse lighting.
            float dif = max(dot(ld, sn), 0.);
            // Lit face color.
            rCol = rCol*(dif + .5)*sh;
            
            // Render the face quad.
            col = mix(col, rCol*.5, (1. - smoothstep(0., sf, quad)));
            col = mix(col, vec3(rCol), (1. - smoothstep(0., sf, quad + ew)));
            
            #ifdef SUBDIV_LINES
            // Quad lines -- Not used.
            
            qLn = lBox(q, mix(v[0], v[1], .5), mix(v[2], v[3], .5), .0);
            qLn = min(qLn, lBox(q, mix(v[1], v[2], .5), mix(v[3], v[0], .5), .0));
            /*         
            qLn = lBox(q, mix(v[0], v[1], .333), mix(v[2], v[3], .666), .0);
            qLn = min(qLn, lBox(q, mix(v[1], v[2], .333), mix(v[3], v[0], .666), .0));
            qLn = min(qLn, lBox(q, mix(v[0], v[1], .666), mix(v[2], v[3], .333), .0));
            qLn = min(qLn, lBox(q, mix(v[1], v[2], .666), mix(v[3], v[0], .333), .0));
            */
            qLn = max(qLn, (prevD - ew/3.));
            
            vec3 svCol = col;
            col = mix(col, col*1.35, (1. - smoothstep(0., sf*3., qLn - .003)));
            col = mix(col, svCol*.65, (1. - smoothstep(0., sf*2., qLn - .001)));
            #endif
        }
        
         
    }
    

    // Faking the ruled guide lines. We'll make them more pronounced outside the colored
    // cubes and faint over the top.
    float lAlpha = mix(.25, .125, 1. - smoothstep(0., sf*2., gHex));
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*2., ln - .001*fbm(p*32. + .5)))*lAlpha);
    // IQ's suggestion to let a trace amount of the graph paper pattern show through.
    // The graph paper was a later addition, so I'd forgotten to include it.
    col = mix(col, vec3(.35, .65, 1)/4., (1. - smoothstep(0., sf*2., max(gHex, ln3)))*.25);
    
    
 
    // Subtle pencil overlay... It's cheap and definitely not production worthy,
    // but it works well enough for the purpose of the example. The idea is based
    // off of one of Flockaroo's examples.
    q = p*8.;//mix(p*10., uv*gSc*10. - (offs - .5)*oFct  - (offs2 - .5)*oFct2, smoothstep(0., sf, gD));
    vec3 colP = pencil(col, q*iResolution.y/450.);
    #ifdef GREYSCALE
    // Just the pencil sketch. The last factor ranges from zero to one and 
    // determines the sketchiness of the rendering... Pun intended. :D
    col = mix(dot(col, vec3(.299, .587, .114))*vec3(1), colP, .6);
    #else
    col = mix(col, 1. - exp(-(col*2.)*(colP + .25)), .85); 
    #endif
    //col = mix(col, colP, .5);
    //col = mix(min(col, colP), max(col, colP), .5); 
   
  
     // Cheap paper grain... Also barely worth the effort. :)
    vec2 pp = q;//floor(q*1024.);
    vec3 rn3 = vec3(hash21(pp), hash21(pp + 2.37), hash21(pp + 4.83));
    vec3 pg = .8 + (rn3.xyz*.35 + rn3.xxx*.65)*.4;
    col *= min(pg, 1.); 
    
    
    // Rough gamma correction and output to screen.
    fragColor = vec4(sqrt(max(col, 0.)), 1);
}