// Image (image) — Hexagon Graph Connection Lines by Shane
// https://www.shadertoy.com/view/43dBz4

/*

	Hexagon Graph Connection Lines
	------------------------------
    
    I made this some time ago. I'm not sure what it was initially supposed to 
    be, but it morphed into one of those Voronoi line connection examples that 
    you'll see all over the place. BigWIngs has a really popular multilayer 
    square grid shader called "The Universe Within" that spawned countless 
    examples across the internet.
    
    This one differs from the others in the sense that it's hexagon grid based,
    and is mechanical in nature -- That is to say that the connections are 
    physically formed rather than fading into existence. The idea was to turn
    this into a 3D example... which I haven't got around to yet, but I will.
    
    As mentioned, there are many examples along these lines, but for those not
    familiar with the concept, the process is pretty straight forward: Set up a
    2D grid in a Voronoi fashion, but instead of checking for the closest 
    neighboring cell node, you render a line connection between any cell nodes
    that fall within a certain distance threshold. Morphing lines from node to
    node as they form requires a little extra work, but it's not difficult.

    
    
    Similar examples:
    
    // Connecting nodes on a square grid. A fun example to watch.
	percolation network 3 -- FabriceNeyret2  
	https://www.shadertoy.com/view/7tdGDX
    
    
    // I don't think there'd be too many who haven't seen this, 
    // but here's the link anyway. :)
    The Universe Within - BigWIngs
    https://www.shadertoy.com/view/lscczl
    

*/


// Color scheme - Green and berry: 0, White and red apple: 1.
#define COLOR 0

// Faux perspective. Putting the plane on a slight lean.
//#define PERSPECTIVE


// Show the hexagon grid that the pattern is based on. I wish more people
// would do this. A picture is worth a thousand comments. :)
//#define SHOW_GRID

// Flat top or pointed top hexagons. Hexagon grid orientation doesn't matter 
// greatly, but can be times when you might need the functionality.
#define FLAT_TOP


// PI and 2PI. Always useful.
#define PI 3.14159265
#define TAU 6.2831853

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21(vec2 f){

    //f = mod(f, GRID_SIZE);
    // The first line relates to ensuring that icosahedron vertex identification
    // points snap to the exact same position in order to avoid hash inaccuracies.
    uvec2 p = floatBitsToUint(f + 16384.);
    p = 1664525U*(p>>1U^p.yx);
    return float(1103515245U*(p.x^(p.y>>3U)))/float(0xffffffffU);
}
 

// A slight variation on a function from Nimitz's hash collection, here: 
// Quality hashes collection WebGL2 - https://www.shadertoy.com/view/Xt3cDn
vec2 hash22(vec2 f){

    // Fabrice Neyret's vec2 to unsigned uvec2 conversion. I hear that it's not
    // that great with smaller numbers, so I'm fudging an increase.
    uvec2 p = floatBitsToUint(f + 1024.);
    
    // Modified from: iq's "Integer Hash - III" (https://www.shadertoy.com/view/4tXyWN)
    // Faster than "full" xxHash and good quality.
    p = 1103515245U*((p>>1U)^(p.yx));
    uint h32 = 1103515245U*((p.x)^(p.y>>3U));
    uint n = h32^(h32>>16);
    
    uvec2 rz = uvec2(n, n*48271U);
    #ifdef STATIC
    // Standard uvec2 to vec2 conversion with wrapping and normalizing.
    return vec2((rz>>1)&uvec2(0x7fffffffU))/float(0x7fffffff);
    #else
    f = vec2((rz>>1)&uvec2(0x7fffffffU))/float(0x7fffffff);
    return sin(f*TAU + iTime)*.5 + .5;
    #endif
}



// Unsigned distance to the segment joining "a" and "b".
// This is basically IQ's well known formula.
float distLine(vec2 p, vec2 a, vec2 b){

    p -= a; b -= a;
    float h = clamp(dot(p, b)/dot(b, b), 0., 1.);
    return length(p - b*h);
}

/*
// Signed distance to a line passing through A and B.
float distLineS(vec2 p, vec2 a, vec2 b){

   b -= a; 
   return dot(p - a, vec2(-b.y, b.x)/length(b));
}
*/

const vec2 scale = vec2(1)/8.;

// Flat top hexagon, or pointed top.
#ifdef FLAT_TOP
const vec2 s = vec2(1.732, 1)*scale;
#else
const vec2 s = vec2(1, 1.732)*scale;
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
    return max(dot(abs(p.xy), vec2(1.732, 1)/2.), abs(p.y));
    #else   
    return max(dot(abs(p.yx), vec2(1.732, 1)/2.), abs(p.x));
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



vec4 p4;
vec4 getDist(vec2 p){

    // Hexagonal grid coordinates.
    p4 = getGrid(p);
    
    // Helper value to convert vertex IDs to scaled vertex positions.
    // The "12" is a factor I put in to ensure that vertex IDs stick
    // to integer values to avoid hash function inconsistencies.
    vec2 sDiv12 = s/12.;
    
    float d = 1e5;
    
    // Maximum offset distance to keep the node within the hexagon cell.
    float mR = .5*scale.x;
    
    // Central node, and distance.
    vec2 cntrP = ((hash22((p4.zw)) - .5)*mR);
    d = length(p4.xy - cntrP);
     
    
    // Neighboring offset  nodal points.
    vec2[6] vP;
    
    // Iterate through all six sides of the hexagon cell andconstruct the 
    // offset neighboring nodal points for each cell. Determine the closest 
    // point, while, we're at it. 
    for(int i = min(0, iFrame); i<6; i++){
    
        // Neighboring offset nodal point.
        vP[i] = eID[i]*2.*sDiv12 + (hash22((p4.zw + eID[i]*2.)) - .5)*mR;
        
        // Neighboring node distance.
        float dI = length(p4.xy - vP[i]);
        
        // Update the minimum nodal distance, if necessary.
        d = min(d, dI);       
 
    }
    
    
    // Nodal vertex value, which is the same as the hexagon Voronoi value,
    // but we're keeping the values seperate.
    float vert = d;
   
   
    // The animated interpolated nodes and line distances.
    float midVert = 1e5;
    float ln = 1e5;

    // Node distance threshold.
    float th = scale.x*7./6.;
    float thF = th/6.; // Smoothstep animation threshold.
   
 
 
    // Mid nodal point and line calculations.
    for(int i = 0; i<6; i++){
          
        int ip1 = (i + 1)%6;
        int im1 = (i + 5)%6;
        
        vec2 mLn;
        
        //////////////////
        vec2 mid;

        // Middle.
        // Top lines head in the opposite direction to the bottom ones.
        // This ensures that the connecting particles only move in 
        // one direction.
        if(i<3){
            
            // Center to vertex interpolation calculation.
            mid = mix(cntrP, vP[i], smoothstep(0., thF, th - distance(cntrP, vP[i])));
            midVert = min(midVert, length(p4.xy - mid));      
            
            // Center to interpolated vertex line.
            ln = min(ln, distLine(p4.xy, cntrP, mid));

        }
        else{
            
            // Vertex to center interpolation (opposite side of the hexagon).
            mid = mix(vP[i], cntrP, smoothstep(0., thF, th - distance(cntrP, vP[i])));
            midVert = min(midVert, length(p4.xy - mid));      
            
            // Center to interpolated vertex line  (opposite side of the hexagon).
            ln = min(ln, distLine(p4.xy, vP[i], mid));

        }

        // Left overflow -- Sometimes, the lines or particles might cross into the 
        // neighboring cell. 
        if(im1<3){

            // Left vertex to middle vertex.
            mid = mix(vP[ip1], vP[i], smoothstep(0., thF, th - distance(vP[i], vP[ip1])));
            midVert = min(midVert, length(p4.xy - mid));

            // Left vertex to middle vertex line.
            ln = min(ln, distLine(p4.xy, vP[ip1], mid));

        }

         // Right overflow -- Sometimes, the lines or particles might cross into the 
        // neighboring cell. 
        if(ip1<3){

            // Right vertex to middle vertex.
            mid = mix(vP[im1], vP[i], smoothstep(0., thF, th - distance(vP[im1], vP[i])));
            midVert = min(midVert, length(p4.xy - mid)); 

            // Right vertex to middle vertex line.
            ln = min(ln, distLine(p4.xy, vP[im1], mid));
       }
       
 

    }
    

    ///////// 
    // Apply some size to the main offset vertices (nodes), the
    // animated interpolated nodes and the line itself.
    vert -= .025;
    midVert -= .02;
    ln -= .003;
    
    
    // Return the above values, plus a hexagon Voronoi value for good measure.
    return vec4(ln, vert, midVert, d);

}



void mainImage(out vec4 fragColor, in vec2 fragCoord){

    
    // Aspect correct screen coordinates.
    float res = min(iResolution.y, 800.);
    vec2 uv = (fragCoord.xy - iResolution.xy*.5)/res;
     
     
    // Global scale factor.
    const float sc = 1.;
    // Smoothing factor.
    float sf = sc/res;
    
    // Scene rotation, scaling and translation.
    mat2 sRot = mat2(1, 0, 0, 1);//rot2(-3.14159/8.); // Scene rotation.
    vec2 camDir = sRot*normalize(s); // Camera movement direction.
    vec2 ld = sRot*normalize(vec2(1, -2)); // Light direction.
    vec2 p = sRot*uv*sc;// + camDir*iTime/8.;
   
    
    
    #ifdef PERSPECTIVE
    // Screen bulge.
    //p *= .96 + dot(p, p)*.08;
    // A bit of perspective.
    p = vec2(2.*p.x, 5)/(2.2 - (p.y));  
    #endif
    
    // Moving the plane.
    p.xy += iTime/24.;
    
    // Shadow variables.
    float lnSh, vertSh, midVertSh, dSh;
    vec4 d4Sh = getDist((p - ld*.04));
    lnSh = d4Sh.x, vertSh = d4Sh.y, midVertSh = d4Sh.z, dSh = d4Sh.w;

    // Main scene variables.
    float ln, vert, midVert, d;
    //vec4(ln, vert, midVert, d);
    vec4 d4 = getDist(p);
    
    ln = d4.x;
    vert = d4.y;
    midVert = d4.z;
    d = d4.w;

    
    float shade = d/scale.x;

    
    // The scene color.
    // Rotating the gradient to coincide with the light direction angle.
    vec2 ruv = rot2(atan(ld.y, ld.x) + 3.14159/2.)*uv;
    //
    // Lit background.
    vec3 bg = mix(vec3(1, .7, .5), vec3(1, .8, .5), smoothstep(.3, .7, ruv.y*.5 + .5));
    //bg = mix(col, col.zyx, .5);
    bg = vec3(.925, .95, 1.1)*dot(bg, vec3(.299, .587, .114));
    
    bg *= 1.25 - vert/scale.x*.5;
    //bg *= 1.45 - vert/scale.x;
    //bg *= 1. + pow(max(1. - ln/scale.x*.4, 0.), 32.)*2.;

     // Very subtle background grid overlay.
    vec4 tmp = getGrid(p*sqrt(9.));
    float grid2 = (abs(getHex(tmp.xy) - scale.y/2.) - .01)/sqrt(9.);
    bg = mix(bg*vec3(.95, .95, 1.05), bg*1.05, 1. - smoothstep(0., sf, grid2)); 
   
    // The vertex color base.
    float rnd = hash21(p4.zw + .13);
    vec3 oCol = .5 + .45*cos(TAU*rnd/8. + vec3(0, 1, 2).yxz*1.05);

   
    // Initializing the scene color to the background.
    vec3 col = bg;

   
    // Vertex and connecting vertex color: Technically, the connecting vertex 
    // should have a color based on its own ID, but I wanted to save a few lines.
    #if COLOR == 1
    vec3 cCol = vec3(1, .2, .25)*oCol.yxz*2.*bg;
    vec3 vCol = oCol*1.5*bg*bg;
    vCol = mix(col.zyx*1., vec3(.8)*dot(vCol, vec3(.299, .587, .114)), .9);
    col = mix(col.zyx*1.3, vec3(1)*dot(col, vec3(.299, .587, .114)), .95);
    #else
    vec3 vCol = oCol*1.5*bg*bg;
    vec3 cCol = oCol.xzy*2.*bg;
    #endif
    
    


    // Shadow spread factor. 
    float shF = iResolution.y/450.;
   
    
    // Render the grid onto the background, if applicable.
    #ifdef SHOW_GRID
    float grid = (abs(getHex(p4.xy) - scale.y/2.) - .00225);
    col = mix(col, col*1.3, 1. - smoothstep(0., sf*shF*3., grid - .00225));
    col = mix(col, col*.05, 1. - smoothstep(0., sf, grid));
    #endif
    
    // Render the shadow layer first.
   float shT = .6;
    float shadow = min(min(lnSh, midVertSh), vertSh);
    col = mix(col, col*shT, (1. - smoothstep(0., sf*shF*4., shadow)));
    
    /*
    // Nodal vertex holes... Too busy.
    ln = max(ln, -(vert + scale.x*.225));
    vert = max(vert, -(vert + scale.x*.225));
    midVert = max(midVert, -(midVert + scale.x*.19));
    */
    
    // Render the lines.
    col = mix(col, col*.8, (1. - smoothstep(0., sf*shF*16., ln)));
    col = mix(col, col*.1, (1. - smoothstep(0., sf, ln)));
    

    // Animated line end vertices.
    col = mix(col, col*.9, (1. - smoothstep(0., sf*shF*16., midVert)));
    col = mix(col, col*.1, (1. - smoothstep(0., sf, midVert)));
    //col = mix(col, bg*2., 1. - smoothstep(0., sf, midVert + scale.x*.07));
    col = mix(col, cCol, 1. - smoothstep(0., sf, midVert + scale.x*.07));

    // Main connecting nodes.
    col = mix(col, col*.9, 1. - smoothstep(0., sf*shF*16., vert));
    col = mix(col, col*.1, 1. - smoothstep(0., sf, vert));
    //col = mix(col, bg*vec3(2, 2, 1), 1. - smoothstep(0., sf, vert + scale.x*.08));
    col = mix(col, vCol, 1. - smoothstep(0., sf, vert + scale.x*.07));

 
    // Vignette.
    //uv = fragCoord/iResolution.xy;
    //col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , 1./32.);

    // Rough gamma correction.
    fragColor = vec4(sqrt(max(col, 0.)), 1);;
}