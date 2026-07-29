// Image (image) — Radial Tiling Truchet by Shane
// https://www.shadertoy.com/view/NlcBRs

/*

    Radial Tiling Truchet
    ---------------------
    
    Using an elongated hexagon base pattern to radially tile a plane and
    produce a Truchet pattern. The other day, Fabrice Neyret reproduced a 
    really cool spiral Truchet pattern that he'd come across on Twitter -- 
    I've provided the link to his version and the original below. Like many
    of his examples, it involved subject matter that wasn't widely known and 
    visually interesting enough to investigate further.
    
    Like everyone else, I've seen spriral patterns that consist of single 
    polygons, or simple mixes of regular polygons, etc, but have never really 
    looked into how they are created. Given the lack of content on the web, 
    it doesn't appear that many other people know much about the process 
    either. 
    
    As usual, the solution wasn't difficult, but it took a while to figure 
    out. As it turns out, the trick is to use elongated hexagons grouped
    together in wedged sections that neatly stitch together in a radial
    fashion. For a simple visual, go to the defines below and set POLYGON
    to "0", TRUCHET to "0" then uncomment the CONSTRUCTION_WEDGES define.
    Alternatively, have a look at some of the imagery in the links below.
    
    Fron a code perspective, this, and patterns like it, consist of nothing 
    more than seperate hexagon grids placed together in a radial fashion using 
    polar coordinates. Things that you may not be used to is putting together 
    a grid full of elongated hexagons, but that just involves adding a few 
    things to the regular hexagon grid code. After that, you have to restrict 
    the pattern to a fan shape, but that is literally two extra lines. Once 
    you have access to the local elongated hexagon coordinates and central ID, 
    you can do whatever you want.
     
    Since this is a simple demonstration, I've chosen the most basic radial
    elongated hexagon pattern arrangement, but there are a heap of others,
    and you can look at some of them in the links provided below. I've 
    found that a lot of the other common polygon patterns (quads, pentagons, 
    etc) can be created via the base hexagon pattern.
    
    This was thrown together quickly as more of a visual guide than anything 
    else. I wanted to show how different arrangements are related, which 
    required a heap of spaghetti logic, so the code isn't fantastic. However, 
    it works fine, and the base code is much more streamlined, so hopefully, 
    it will give anyone who wishes to make radial or spriral polygon patterns, 
    spiral Truchet patterns, etc, a start -- There's a few defines that 
    should help. I intend to do something more interesting with this at a 
    later date.
 
 
    
    References:
    
    // I love examples like this. I didn't bother looking at the code, 
    // but the visual itself was enough to give me a start.
    Damasdi tiling - FabriceNeyret2
    https://www.shadertoy.com/view/stcBRj
    //
    // Based on the following:
    Symmetry - Math and art by Gábor Damásdi
    https://szimmetria-airtemmizs.tumblr.com/post/144161547163/
    an-other-pattern-that-uses-only-a-single
    
    Elongated triangular tiling - Wikipedia
    https://en.wikipedia.org/wiki/Elongated_triangular_tiling
    
    Order-Six Radial Tessellations of the Plane, Using Elongated and 
    Equilateral Hexagons, Rendered with Twelve Different Coloring-Schemes
    https://RobertLovesPi.net    
    
    
*/

// Polygon type - Hexagon base: 0, Quadrilateral: 1, Triangle-Square:2.
#define POLYGON 1

// Truchet type: No Truchet: 0, White Truchet: 1, Black: 2
#define TRUCHET 2

// Display the multiple tile wedges that radially tile the plane.
//#define CONSTRUCTION_WEDGES

// Dual pattern -- This is the dual to the regular triangle and square
// pattern (POLYGON 2). With the exception of the center, it's mostly
// pentagons. Best viewed without the Truchet pattern.
//#define DUAL

// Polygon vertices.
//#define VERTICES

// Polygon edge midpoints.
//#define MIDPOINTS

// Displaying the hexagon base pattern overlay. It's redundant when using the
// base hexagon, but can be helpful in visualizing how the quadrilateral or 
// triangle-square pattern is constructed. Best viewed without the Truchet
// pattern or dual overlay.
//#define BASE_OVERLAY

// Bump map highlights.
//#define BUMP


// Flat top hexagon scaling.
const vec2 s = vec2(2. + 1.7320508, 1); // Normal hexagon plus square.
 
// Hexagonal bound: Not technically a distance function, but it's
// good enough for this example.
float getHex(vec2 p){
 
    // Generalized elongated hexagon function, based on the 
    // partitioning rectangle above.
    //
    // I did this in a hurry. There'd be better ways to go 
    // about it, but it'll do for now.
    float x = (s.x - s.y)/2.;//(1. + 1.7320508)/2.;
    float ln;
    p = abs(p);
    ln =  distLineS(p, vec2(-.5, .5), vec2(.5, .5));
    ln =  max(ln, distLineS(p, vec2(.5, .5), vec2(x, 0)));
    ln =  max(ln, distLineS(p, vec2(x, 0), vec2(.5, -.5)));
    return ln;
    
    /*    
    float x = (1. + 1.7320508)/2.;
    float ln =  distLineS(p, vec2(-.5, -.5), vec2(-x, 0));
    ln =  max(ln, distLineS(p, vec2(-x, 0), vec2(-.5, .5)));
    ln =  max(ln, distLineS(p, vec2(-.5, .5), vec2(.5, .5)));
    ln =  max(ln, distLineS(p, vec2(.5, .5), vec2(x, 0)));
    ln =  max(ln,distLineS(p, vec2(x, 0), vec2(.5, -.5)));
    ln =  max(ln, distLineS(p, vec2(.5, -.5), vec2(-.5, -.5)));
    return ln;
*/
}

// Hexagonal grid coordinates. This returns the local coordinates and the cell's center.
// The process is explained in more detail here:
//
// Minimal Hexagon Grid - Shane
// https://www.shadertoy.com/view/Xljczw
//
vec4 getGrid(vec2 p){
  
    
    vec4 ip = floor(vec4(p/s, p/s - .5)) + .5;
    vec4 q = p.xyxy - vec4(ip.xy, ip.zw + .5)*s.xyxy;
    //return dot(q.xy, q.xy)<dot(q.zw, q.zw)? vec4(q.xy, ip.xy) : vec4(q.zw, ip.zw + offs);
    return getHex(q.xy)<getHex(q.zw)? vec4(q.xy, ip.xy) : vec4(q.zw, ip.zw + .5);
   
} 


void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    // Aspect corret coordinates.
    vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;

    // Scale and smoothing factor.
    const float sc = 10.;
    float sf = sc/iResolution.y;
    
    
    // Scaling and translation.
    vec2 p = sc*uv;
    
    // Scene field calculations.

    vec2 op = p; // Global position copy.
    
    // Light for each block.
    vec2 ld = normalize(vec2(-2, 1));
    vec2 ld2 = ld;
    
    // Number of partitions for each block.
    const float aN = 6.;
    
    // Creating three blocks of hexagon wedges.
    p *= rot2(-iTime/12.);
     
    
    float a = atan(p.y, p.x);
    float na = floor(a/6.2831853*aN);
    float ia = (na + .5)/aN;
    //
    p *= rot2(-ia*6.2831853);
    ld *= rot2(-ia*6.2831853);
    p.x -= (s.x - s.y)/2.; // Half hexagon width.
     // Hexagonal grid coordinates.
    vec4 p4A = getGrid(p);
    
    // Creating the other three blocks of hexagon wedges. These are 
    // pushed out from the center a little further.
    p = rot2(3.14159/aN)*op;
    ld2 = rot2(3.14159/aN)*ld2;
    p *= rot2(-iTime/12.);
    float a2 = atan(p.y, p.x);
    float na2 = floor(a2/6.2831853*aN);
    float ia2 = (na2 + .5)/aN;
    //
    p *= rot2(-ia2*6.2831853);
    ld2 *= rot2(-ia2*6.2831853);
    p.x -= (s.x - s.y)/2. + 1.; // Half hexagon width plus 1.
     // Hexagonal grid coordinates.
    vec4 p4B = getGrid(p);
    
    // Closest hexagon in each block and its offset block.
    float dA = getHex(p4A.xy);
    float dB = getHex(p4B.xy);
    // Position based IDs.
    vec2 idA = floor(p4A.zw*2.);
    vec2 idB = floor(p4B.zw*2.);
    // Eradicating all hexagons that fall outside each block.
    if(abs(idA.y)>idA.x){ dA = 1e5; }
    if(abs(idB.y)>idB.x){ dB = 1e5; }
    
    
    // Obtaining the closest hexagon distance, its local coordinates,
    // the block number, and ID.
    float d = min(dA, dB);
    vec4 p4 = dA<dB? p4A : p4B;
    float n = dA<dB? na : na2 + 1.;
    vec2 id = floor(p4.zw*2.);
    
    // Nearby sample for highlighting.
    ld = dA<dB? ld : ld2;
    float dHi = getHex(p4.xy - ld*.001);

    vec4 svp4 = p4; // Local hexagon coordinate copy.
   
    // Using the block number and radial postion to calculate a unique
    // position based ID for this particular hexagon.
    float ip = (p4.z*2.) + n;

    // Copy of the original local coordinate.
    vec4 oP4 = p4;
     
   
    
    vec2 ctr = vec2(0); // Hexagon center.
    
    float x = (s.x - s.y)/2.; // Distance to triangle center.
     
    float lnL = (distLineS(p4.xy, vec2(-.5, .5), vec2(-.5, -.5))); // Left partition line.
    float lnR = (distLineS(p4.xy, vec2(.5, .5), vec2(.5, -.5))); // Right partition line.
    float ln = min(abs(lnL), abs(lnR));
    
    mat4x2 v; // Container for holding the square or triangle vertices.
 
    int vNum = 3;
     
    // In the left triangle or the right triangle, adjust the midpoint.
    // Otherwise, we're in the central square, so do nothing.
    if(lnL<0.){
    
        // Left triangle.
        ip -= .25;
        p4.z -= .25;
        //p4.x -= -(.5 + x/2.);
        ctr = vec2(-(x + 1.)/3., 0); // Average of the vertices below.
        
        // There's a dummy variable on the end.
        v = mat4x2(vec2(-.5, -.5), vec2(-x, 0), vec2(-.5, .5), vec2(1e5));
    }
    else if(lnR>0.){
    
        // Right triangle.
        ip += .25;
        p4.z += .25;
        ctr = vec2((x + 1.)/3., 0); // Average of the vertices below.
        
        // There's a dummy variable on the end.
        v = mat4x2(vec2(.5, -.5), vec2(.5, .5), vec2(x, 0), vec2(1e5));
    }
    else {
    
         vNum = 4; // Using all 4 vertices for the square.
         // Square.
         v = mat4x2(vec2(-.5, -.5), vec2(-.5, .5), vec2(.5, .5), vec2(.5, -.5));
    }    
 
    
    // Calculating the vertex distance field, midpoint distance field, dual
    // lines, etc, for the squares and triangles.
    float dualLn = 1e5;
    float vert = 1e5, mid = 1e5;
    mat4x2 midV;
    //mat4x2 tMidV;
    
    float poly = -1e5, polyHi = -1e5;
    for(int i = 0; i<vNum; i++){
    
        vert = min(vert, length(p4.xy - v[i]));

        vec2 vMid = mix(v[i], v[(i + 1)%vNum], .5);

        midV[i] = vMid;
        //tMidV[i] = normalize((v[i] - v[(i + 1)%vNum]).yx*vec2(-1, 1));

        mid = min(mid, length(p4.xy - vMid));
        dualLn = min(dualLn, distLine(p4.xy, ctr, vMid));

        poly = max(poly, distLineS(p4.xy, v[i], v[(i + 1)%vNum]));
        polyHi = max(polyHi, distLineS(p4.xy - ld*.001, v[i], v[(i + 1)%vNum]));
 
    }

    
    // Quickly coding in a Truchet pattern.
    float rnd1 = hash21(p4.zw + .101 + n);
    float rnd2 = hash21(p4.zw + .102 + n);
    float rnd3 = hash21(p4.zw + .103 + n);
    float rnd4 = hash21(p4.zw + .104 + n);

    float sL = 1.;
    float th = .015*sc;
    vec3 tr = vec3(1e5);


    if(vNum==3){ 

        // Triangle Truchet pattern.

        int rndI = int(floor(rnd4*3.))%3;
        float v0 = length(p4.xy - v[rndI]);

        tr.x = mid - th;
        if(rnd1<.5) tr.x = min(tr.x, abs(v0 - .5) - th);
        else if(rnd1<1.8) tr.x = -(vert - (sL/2. - th));

        /* 
        tr.x = abs(length(p4.xy - v[0]) - .5) - th;
        tr.y = abs(length(p4.xy - v[1]) - .5) - th;
        tr.z = abs(length(p4.xy - v[2]) - .5) - th;
        */ 
    }
    else { 

        // Square Truchet pattern.

        //if(rnd3<.5) p4.xy = p4.yx*vec2(1, -1);
        p4.xy *= rot2(floor(rnd3*32.)*3.14159/2.);


        float v0 = length(p4.xy - v[0]);

        // All dots.
        tr.x = mid - th;

        if(rnd2<.333){
            // Dots and one arc.
            tr.x = min(tr.x, abs(v0 - .5) - th);
        }
        else if(rnd2<.5){  
            // Two arcs.
            v0 = min(v0, length(p4.xy - v[2]));
            tr.x = min(tr.x, abs(v0 - .5) - th);
        }
        else if(rnd2<1.1){  
            // Two lines.
            tr.x = abs(p4.x) - th;
            tr.y = abs(p4.y) - th;
        }

    }
     
     
    #if POLYGON == 1

    p4 = oP4;
    ip = (p4.z*2.) + n;
    lnL = (distLineS(p4.xy, vec2(.5, .5),vec2(-.5, -.5))); // Partition line.
    ln = abs(lnL);
    
    vNum = 4;  
    if(lnL<0.){
        // Left quadrilateral.
        ip -= .25;
        p4.z -= .25;
        // Center.
        ctr = vec2(-(x + 1.)/3., 0); // Average of the vertices below.
        // Vertices for this quad.
        v = mat4x2(vec2(-.5, -.5), vec2(-x, 0), vec2(-.5, .5), vec2(.5,.5));
       
    }
    else {
        // Right quadrilateral.
        ip += .25;
        p4.z += .25;
        // Center.
        ctr = vec2((x + 1.)/3., 0); // Average of the vertices below.
        // Vertices for this quad.
        v = mat4x2(vec2(-.5, -.5), vec2(.5, .5), vec2(x, 0), vec2(.5, -.5));
    }

    poly = -1e5, polyHi = -1e5;
    vert = 1e5, mid = 1e5;
    for(int i = 0; i<vNum; i++){
    
        vert = min(vert, length(p4.xy - v[i])); // Vertices.

        vec2 vMid = mix(v[i], v[(i + 1)%vNum], .5); // Midpoints.

        // Dual lines and midpoints.
        if(lnL>0. && i==3){ 
            vMid = vec2(0, -.5); 
            dualLn = min(dualLn, distLine(p4.xy, vec2(0), vMid)); 
        }
        else if(lnL<0. && i==2) { 
            vMid = vec2(0, .5); 
            dualLn = min(dualLn, distLine(p4.xy, vec2(0), vMid)); 
        }

   
        mid = min(mid, length(p4.xy - vMid)); // Midpoint distance.

        // Polygon distance, plus an extra highlight samples.
        poly = max(poly, distLineS(p4.xy, v[i], v[(i + 1)%vNum]));
        polyHi = max(polyHi, distLineS(p4.xy - ld*.001, v[i], v[(i + 1)%vNum]));
 
    }
    #elif POLYGON == 0
    // Original hexagon base.
    p4 = oP4;
    ip = (p4.z*2.) + n;
    vNum = 6;
    poly = d;
    polyHi = dHi;
    mid = 1e5; // vert = 1e5;
    vec2[6] vH = vec2[6](vec2(-.5, -.5), vec2(-x, 0), vec2(-.5, .5), vec2(.5, .5), 
                            vec2(x, 0), vec2(.5, -.5));
    for(int i = 0; i<vNum; i++){
            //vert = min(vert, length(p4.xy - vH[i]));
            vec2 vMid = mix(vH[i], vH[(i + 1)%vNum], .5); // Midpoint.
            mid = min(mid, length(p4.xy - vMid)); // Midpoint distance.
    }
    #endif
     
    // Giving the vertices and midpoints some size.
    vert -= th;
    mid -= .0125*sc;
 

    //Debug: Restricting the pattern size.
    //if(oP4.z>.8){ poly = 1e5; ln = 1e5; tr = vec3(1e5); }


    // Restricting to six colors.
    ip = mod(ip, 6.)/6.;
    

    #ifdef CONSTRUCTION_WEDGES
    // Display the 12 wedge blocks that tile the plane.
    ip = n/24. + mod(id.x, 2.)/2.;
    vec3 hCol = .5 + .45*cos(6.2831*ip/4. + vec3(0, 1, 2)*1.5);
    if(dA>dB) hCol = .5 + .45*cos(6.2831*ip/4. + vec3(0, 1,2)*1.5 + 3.14159);
    #else 
    // Animated spectrum colors.
    vec3 hCol = .5 + .45*cos(6.2831*ip + vec3(0, 1, 2)*1.5 - iTime);
    //vec3 hCol = vec3(1, .1, .3);
    //vec3 hCol = vec3(.9, .95, 1);
    #endif

 
    // Bump highlights.
    #ifdef BUMP
    float dSh = poly;//clamp(poly*4., -1., 0.);
    float dShHi = polyHi;//clamp(polyHi*4., -1., 0.);
    float b = max(dShHi - dSh, 0.)/.001;
    //float b2 = max(dSh - dShHi, 0.)/.001;
   
    hCol *= .75 + b*.5;
    #endif

   // Scene color -- Set to black.
    vec3 col = vec3(0); 

    // Rendering onto the background.

    // Laying down the polygons first.
    col = mix(col, hCol, 1. - smoothstep(0., sf, poly + .004*sc));
    /*
    // Polygons with borders.
    col = mix(col, hCol*.75, 1. - smoothstep(0., sf, poly + .004*sc));
    col = mix(col, hCol*.1, 1. - smoothstep(0., sf, poly + .012*sc));
    col = mix(col, hCol, 1. - smoothstep(0., sf, poly + .0175*sc));
    */

 
    
    
    #if TRUCHET>0
    // Rendering the Truchet pattern. The third Truchet field isn't used
    // at the moment.
    for(int i = 0; i<3; i++){
        vec3 svCol = col;
        
        col = mix(col, vec3(0), (1. - smoothstep(0., sf*8., tr[i]))*.5);
        col = mix(col, vec3(0), 1. - smoothstep(0., sf, tr[i]));
        col = mix(col, svCol*.5 + .75, 1. - smoothstep(0., sf, tr[i] + .006*sc));
        #if TRUCHET==1
        // White.
        col = mix(col, svCol*.25 + .35, 1. - smoothstep(0., sf, abs(tr[i] + .015*sc) - .0015*sc));
        #elif TRUCHET==2
        // Black.
        col = mix(col, svCol*.06, 1. - smoothstep(0., sf, tr[i] + th - .0045*sc));
        #endif
    }
    #endif
    
    
    #ifdef DUAL
    // Display the dual pattern.
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, dualLn - .006*sc));
    col = mix(col, vec3(.9, .95, 1), 1. - smoothstep(0., sf, dualLn - .002*sc));
    // col = mix(col, vec3(1), (1. - smoothstep(0., sf, dualLn - .001*sc))*.5);
    #endif


    #ifdef VERTICES
    // Polygon vertices.
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, vert));
    col = mix(col, vec3(.9, .95, 1), 1. - smoothstep(0., sf, vert + .006*sc));
    #endif
    
    #ifdef MIDPOINTS
    // Polygon midpoints.
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, mid));
    col = mix(col, vec3(.6, .9, 1), 1. - smoothstep(0., sf, mid + .006*sc));
    #endif
    
    #ifdef BASE_OVERLAY
    // Hexagon base pattern overlay.
    col = mix(col, vec3(1), (1. - smoothstep(0., sf, abs(d) - .007))); // Top layer.
    #endif
    
    // Output to screen
    fragColor = vec4(sqrt(max(col, 0.)), 1);
}