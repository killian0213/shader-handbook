// Image (image) — Hexagon Blocks by Shane
// https://www.shadertoy.com/view/XcfBRn

/*

	Hexagon Blocks
	--------------
    
    I wrote this a long time ago. I'm not sure what the most common hexagon grid 
    pattern would be, but isometric boxes would have to be a contender, possibly 
    because they're very easy to make, and the results are reasonably satisfying.
    
    They are constructed by producing a hexagon grid, then partitioning each hexagon
    cell into three quads to represent cube faces. If you know how to render
    polygons, then it should be pretty easy. Textured and shadowed examples are 
    less common, but that's pretty easy to do also, and is explained below.
    
    Anyway, this example is definitely not that interesting, but hopefully, it'll 
    be useful to someone out there.  

	
    
    
    Other hexagonal pattern examples:

    // With more effort, you can add stairs, doors, and all kinds of things.
    hexastairs: ladder like + doors -- FabriceNeyret2 
	https://www.shadertoy.com/view/wsyBDm
    
    // Another simple, but effective, hexagon grid-based pattern.
    Repeating Celtic Pattern (360ch) -- FabriceNeyret2
    https://www.shadertoy.com/view/wsyXWR

    // JT has a heap of grid-based patterns that I like looking through.
    // Here are just a couple:
    //
    hexagonally grouped weaved lines  -- jt 
    https://www.shadertoy.com/view/DdccDr
    //
    three directions city grid parts -- jt
    https://www.shadertoy.com/view/DdccR8
    
    

*/

// Diagonal face pattern, or not.
//#define DIAGONAL

// Randomly invert some of the boxes. It's a pretty standard move and
// makes the pattern look a little more interesting.
//
// Commenting it out will produce the cleaner, but more basic pattern.
#define RANDOM_INVERT

// Show the hexagon grid that the pattern is based on...
// Probably a little redundant in this case, but it's there.
//#define SHOW_GRID

// Flat top hexagons, instead of pointed top.
//#define FLAT_TOP

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21(vec2 f){
    uvec2 p = floatBitsToUint(f);
    p = 1664525U*(p>>1U^p.yx);
    return float(1103515245U*(p.x^(p.y>>3U)))/float(0xffffffffU);
}

// Signed distance to a line passing through A and B.
float distLineS(vec2 p, vec2 a, vec2 b){

   b -= a; 
   return dot(p - a, vec2(-b.y, b.x)/length(b));
}

// Flat top hexagon, or pointed top.
#ifdef FLAT_TOP
const vec2 s = vec2(1.732, 1);
#else
const vec2 s = vec2(1, 1.732);
#endif

// Hexagon vertex IDs. They're useful for neighboring edge comparisons, etc.
// Multiplying them by "s" gives the actual vertex postion.
#ifdef FLAT_TOP
// Vertices: Clockwise from the left.
                     
// Multiplied by 12 to give integer entries only.
const vec2[6] vID = vec2[6](vec2(-4, 0), vec2(-2, 6), vec2(2, 6), 
                      vec2(4, 0), vec2(2, -6), vec2(-2, -6)); 

const vec2[6] eID = vec2[6](vec2(-3, 3), vec2(0, 6), vec2(3), 
                      vec2(3, -3), vec2(0, -6), vec2(-3));

#else
// Vertices: Clockwise from the bottom left. -- Basically, the ones 
// above rotated anticlockwise. :)

// Multiplied by 12 to give integer entries only.
const vec2[6] vID = vec2[6](vec2(-6, -2), vec2(-6, 2), vec2(0, 4), 
                      vec2(6, 2), vec2(6, -2), vec2(0, -4));

const vec2[6] eID = vec2[6](vec2(-6, 0), vec2(-3, 3), vec2(3, 3), vec2(6, 0), 
                      vec2(3, -3), vec2(-3, -3));

#endif

// Hexagonal bound: Not technically a distance function, but it's
// good enough for this example.
float getHex(vec2 p){
    
    // Flat top and pointed top hexagons.
    #ifdef FLAT_TOP
    return max(dot(abs(p.xy), s/2.), abs(p.y*s.y));
    #else   
    return max(dot(abs(p.xy), s/2.), abs(p.x*s.x));
    #endif
}

// Hexagonal grid coordinates. This returns the local coordinates and the cell's center.
// The process is explained in more detail here:
//
// Minimal Hexagon Grid - Shane
// https://www.shadertoy.com/view/Xljczw
//
vec4 getGrid(vec2 p){
    
    vec4 ip = floor(vec4(p/s, p/s - .5));
    vec4 q = p.xyxy - vec4(ip.xy + .5, ip.zw + 1.)*s.xyxy;
    // The ID is multiplied by 12 to account for the inflated neighbor IDs above.
    return dot(q.xy, q.xy)<dot(q.zw, q.zw)? vec4(q.xy, ip.xy*12.) : vec4(q.zw, ip.zw*12. + 6.);
    //return getHex(q.xy)<getHex(q.zw)? vec4(q.xy, ip.xy) : vec4(q.zw, ip.zw + .5);

}


// Face pattern. Nothing exciting. Just a pseudo maze pattern.
float cubeTex(vec2 p, vec2 gIP){

    #ifdef DIAGONAL
    float sc = 6.;
    #else
    float sc = 8.*.7071;
    p *= rot2(3.14159/4.);
    #endif
    
    p *= sc;    
    
    // Square cell partiioning.
    vec2 ip = floor(p);
    p -= ip + .5;
    
    // Random rotation.
    float rnd = hash21(ip + gIP*.123 +.01);
    if(rnd<.5) p.y = -p.y;
    
    // Diagonal lines.
    vec2 ap = abs(p - .5);
    float d = abs((ap.x + ap.y)*.7071 - .7071);
    ap = abs(p);
    d = min(d, abs((ap.x + ap.y)*.7071 - .7071));
    d -= .1666;
    
    // Scale back and return.
    return -d/sc;
}


void mainImage(out vec4 fragColor, in vec2 fragCoord){

    
    // Aspect correct screen coordinates.
    vec2 res = iResolution.xy;
    vec2 uv = (fragCoord.xy - res.xy*.5)/res.y;
    
    // Global scale factor.
    const float sc = 4.;
    // Smoothing factor.
    float sf = sc/res.y;
    
    // Scene rotation, scaling and translation.
    mat2 sRot = mat2(1, 0, 0, 1);//rot2(3.14159/12.); // Scene rotation.
    vec2 camDir = sRot*normalize(s); // Camera movement direction.
    vec2 ld = sRot*normalize(vec2(1, -1)); // Light direction.
    vec2 p = sRot*uv*sc + camDir*iTime/3.;
    
   
    // Hexagonal grid coordinates.
    vec4 p4 = getGrid(p);
    
    
    // The vertex and edge IDs are multiplied by 12, so we're factoring that in.
    vec2 sDiv12 = s/12.;

    
    #ifdef RANDOM_INVERT
    // Random flipping number.
    float rndT = hash21(p4.zw + .01)<.5? -1. : 1.;
    
    // Randomly flip the coordinates.
    if(rndT<0.) p4.y = -p4.y;
    #endif

    // Center to edge lines.
    float vLn[6];
    
    
    // Hexagon shape.
    float hexShape = getHex(p4.xy) - .5;
     
    // Iterate through all six sides of the hexagon cell.
    for(int i = 0; i<6; i++){
        
        // Center to edge lines.
        vLn[i] = distLineS(p4.xy, vec2(0), vID[i]*sDiv12);

        // Border lines (start with "hexShape = -1e5;").
        //float bord = distLineS(p4.xy, vID[i]*sDiv12, vID[(i + 1)%6]*sDiv12);
        // Hexagon shape.
        //hexShape = max(hexShape, bord);

    }
     
    // Cube faces.
    vec3 cube;
    
    // Top, left and right cube sides.
    cube.x = max(max(hexShape, vLn[1]), -vLn[3]);
    cube.y = max(max(hexShape, vLn[3]), -vLn[5]);
    cube.z = max(max(hexShape, vLn[5]), -vLn[1]);
    
    
    // The overall color and shade.
    vec3 col = vec3(0);
    vec3 shade = vec3(.9, .5, .4);
    
    // Cube shadows.
    vec3 shad = vec3(1e5);
    // Render quarter-wing shadow portions on two of the faces, then put the 
    // remaining face completely in shadow. It's a simple, but effective, trick.
    shad.x = max(cube.x, distLineS(p4.xy, vID[3]*sDiv12, eID[1]*sDiv12));
    shad.y = max(cube.y, distLineS(p4.xy, eID[4]*sDiv12, vID[3]*sDiv12));
    shad.z = cube.z;
    #ifdef RANDOM_INVERT
    if(rndT<0.){ shad.xy = cube.xy; } // All in shade, if the hexagons are inverted.
    
    // Shift the shades to match the faces of the hexagons with flipped orientation.
    if(rndT<0.) shade = shade.xzy; 
    #endif
 

    // Applying the colors, patterns, etc, to the cube faces.
    //
    // Hmmm... I could've used cleaner color logic here, but it seems to work,
    // so I'll leave it for now. I might tidy it up later.
    for(int i = 0; i<3; i++){
    
        // Matrix containing the vertex-based basis vectors, which in turn is
        // used for oriented texturing.
        mat2 mR = inverse(mat2((vID[(i*2 + 1)%6]*sDiv12), (vID[(i*2 + 3)%6]*sDiv12)));
        // Correctly oriented texture coordinates for this particular face.
        vec2 txC = mR*p4.xy;
        // Using the coordinates to create the face pattern.
        float pat = cubeTex(txC, p4.zw*3. + float(i));
        
        // Random face color -- It's just a shade of green.
        float rnd4 = hash21(p4.zw*3. + float(i)*1. + .3);
        vec3 patCol = .5 + .45*cos(6.2831*rnd4/4. + vec3(0, 1, 2).yxz*1.4);
        //vec3 patCol = vec3(.45, .6, .6); // Plain color.
  
        // Running a bit of a blue gradient through the colors.   
        patCol = mix(patCol, patCol.zyx, clamp(-p4.x*.5 - p4.y + .5, 0., 1.));

        // Running screen-based gradients throughout.
        float uvx = uv.x*res.x/res.y;
        patCol = mix(patCol, patCol.xzy, 1. - smoothstep(0., 1., -uv.x/3. + uv.y + .5));
        patCol = mix(patCol, patCol.yxz, 1. - smoothstep(.2, .5, -uvx/2. + .5));
        patCol *= 2.5;
  
        // Face, edge and trim colors.
        vec3 faceCol = vec3(.9, 1, 1.2);
        vec3 edgeCol = faceCol/10.;
        vec3 trimCol = vec3(1.6, .8, .2)*mix(faceCol, patCol, .3);
    
        // Applying the pattern to the faces.
        faceCol = mix(edgeCol, patCol, 1. - smoothstep(0., sf, pat));
        
        // Applying the face shades.
        edgeCol *= shade[i];
        trimCol *= shade[i];
        faceCol *= shade[i];
   
        // Add the cube quads.
        col = mix(col, edgeCol, (1. - smoothstep(0., sf, cube[i])));
        col = mix(col, trimCol, (1. - smoothstep(0., sf, cube[i] + 1./56.)));
        col = mix(col, edgeCol, (1. - smoothstep(0., sf, cube[i] + 1./56. + 1./28.)));
        col = mix(col, faceCol, (1. - smoothstep(0., sf, cube[i] + 2.5/56. + 1./28.)));
         
        
    }
    

    // Applying shadows.
    for(int i = 0; i<3; i++){
        col = mix(col, col*.25, (1. - smoothstep(0., sf*6.*res.y/450., shad[i] + .015)));
    }
    
    // A bit of false ambient occusion.
    #ifdef RANDOM_INVERT
    if(rndT>0.) col *= max(1. - length(p4.xy)*.95, 0.);
    else col *= max(.25 + length(p4.xy)*.75, 0.);
    #else
    col *= max(1. - length(p4.xy)*.95, 0.);
    #endif
    
    #ifdef SHOW_GRID
    // A little bit redundant, but here are the hexagon border lines.
    col = mix(col, vec3(1), (1. - smoothstep(0., sf, abs(hexShape) - .005)));
    #endif
    
    // Vignette.
    //uv = fragCoord/iResolution.xy;
    //col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , 1./16.);

    // Rough gamma correction.
    fragColor = vec4(pow(max(col, 0.), vec3(1./2.2)), 1);
    
}