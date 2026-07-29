// Buffer A (buffer) — Pinwheel Spiral Pattern by Shane
// https://www.shadertoy.com/view/WcSXz1

/*

    Pinwheel Spiral Pattern
    -----------------------
    
    There are two main kinds of pinwheel patterns that I'm aware of, and they're not
    really related. This is the one that comprises a central square surrounded by
    four neighboring squares in a circular pattern that vaguely resembles a pinwheel. 
    The other kind of pinwheel pattern is Conway's Triangle pinwheel, which is a 
    self-replicating subdivision process -- That pattern is also pretty interesting, 
    so I'm going to post one of those too.
    
    There are a lot of interesting patterns based off of the pinwheel arrangement and 
    this is one of them. As you can see, it's just a rendering of square-based geometric 
    spirals inside each cell. You'll see geometric spirals appended to a lot of different 
    tiling arangements. By the way, the spiral pattern doesn't need to involve 45 degree 
    turns, but it looks more symmetrical this way.
    
    I've explained the construction below, for anyone interested, but I think a lot of
    it is common sense.
  
  
    
    // Other examples:
    
    // SnoopethDuckDuck makes some pretty elegant shaders.
    Square Tiling Example - SnoopethDuckDuck
    https://www.shadertoy.com/view/fdSyWd
    
    // A pinwheel pattern using far, far less code than I did. :)
    Simpler Pinwheel Tiling - Golfed - FabriceNeyret2 
    https://www.shadertoy.com/view/Dll3Rn
    
    // Another subdivided pinwheel pattern.
    Log Spiral Pinwheel Infinite Spiral - Shane
    https://www.shadertoy.com/view/XfBBWd
    
*/


// Log spherical transformation.
//#define LOG_SPHERICAL

// Quarter spiral. Commenting this out with produce a looser, more organic looking 
// sprial. The default quarter turns look cleaner, but less interesting.
#define QUARTER_SPIRAL
 
// Show the grid. If you comment out the "LOG_SPHERICAL" and "HOLES"
// defines, the structure should become a little clearer.
//#define SHOW_GRID

// Global scale.
vec2 gSc = vec2(1)/2.;

// PI, since it gets used a lot.
#define PI 3.14159265


// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// Commutative smooth maximum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smax(float a, float b, float k){
    
   float f = max(0., 1. - abs(b - a)/k);
   return max(a, b) + k*.25*f*f;
}




// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21(vec2 f){

    
    uvec2 p = floatBitsToUint(f);
    p = 1664525U*(p>>1U^p.yx);
    return float(1103515245U*(p.x^(p.y>>3U)))/float(0xffffffffU);
}


// IQ's box formula.
float sBox(in vec2 p, in vec2 b, float sf){

  vec2 d = abs(p) - b + sf;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - sf;
}




// Global copy of the local coordinates.
vec2 gP;

int dark;

// The pinwheel distance field: By the way, it's possible to make a pinwheel
// pattern (not including subdivision) with four taps, and fewer calculations 
// (using line stepping methods), but this is more readable. Plus, it's only 
// a 2D example, so the GPU won't really notice anyway.
vec4 distField(vec2 p){
    
    vec2 oP = p;
    // Scale, cell ID and local coordinates.
    vec2 sc = gSc;
    vec2 ip = floor(p/sc) + .5;
    p -= (ip)*sc;
    
     // Grid square vertices.
    mat4x2 vID = mat4x2(vec2(-.5), vec2(-.5, .5), vec2(.5), vec2(.5, -.5));

    // Pinwheel rotation and angle.
    float a = (smoothstep(-.15, .15, sin(iTime/3. + .5)) - .5)*atan(1., 2.)*2.;//;
    // Rotation matrix.
    mat2 mR = rot2(-a);
    
    float sff = 0.;
    
    // Central box.
    vec2 q = mR*p;
    float vBox = sBox(q, sc/2.*abs(sin(a)), .015*sff);
    
    // Initiate the overall distance field, ID, and box ID.
    float d = vBox;
    vec2 id = ip;
    // Central box, and four surrounding boxes, make five.
    // The four surrounding boxes are each subdivided into a
    // further five, so that makes 21.
    int boxID = 4;
    
    
    
    vec2 gSc = sc/2.*abs(sin(a));
    // Global copy of the local coordinates.
    gP = q;
    
    // The four surrounding boxes.
    for(int i = 0; i<4; i++){
        
        q = mR*(p - vID[i]*sc);
        // Rounding needs to be hardcoded, due to "sin(a)"
        // changing from quadrant to quadrant.
        vBox = sBox(q, sc/2.*cos(a), .03*sff); 
    
        if(vBox<d){
            d = vBox;
            id = ip + vID[i];
            // Prior to subdivision, there are 4 surrounding objects, 
            // plus the center.
            boxID = i; 
            
            gP = q;
            gSc = sc/2.*cos(a);
        }
    
    }
        

    float oD = d;
    
    #ifdef LOG_SPHERICAL
    // The ID needs to wrap with the angle number (see the log transformation), 
    // which is 2, in this case. I can't remember why it specifically needs to
    // wrap prior to subdivision, but the random colors won't work if I move 
    // it down... I'll figure it out later. :)
    id.y = mod(id.y, 2.);
    #endif    
    
    
    // Rotate the small box an extra 180 degrees when using a negative 
    // angle, otherwise the four pronged spiral won't look right.
    if(boxID==4 && a<0.) gP *= rot2(PI/2.);
    
    dark = 1;
    
    #ifdef QUARTER_SPIRAL
    const int N = 10;
    #else 
    const int N = 13;
    #endif
    
    // Subdividing each pinwheel square into the triangular spirals. There
    // are probably a heap of better ways to do this, but this works.
    for(int i = 0; i<N; i++){
    
        if(boxID==4 && i>N - 3) break; // Use fewer spiral iterations in the small boxes.
     
        // Rotate a quarter turn, then drop the scale.
        #ifdef QUARTER_SPIRAL
        gP *= rot2(PI/4.);
        gSc *= cos(PI/4.);
        #else 
        // Using a slightly smaller sprial turn each iteration to give
        // less symmetric, but longer, sprirals.
        gP *= rot2(PI/5.);
        gSc *= cos(PI/5.);
        #endif

        // Splitting the box into two X regions Inner and outer... There's a better
        // way to do this, but I was in a hurry.
        float dSplit = smax(d, abs(gP.x) - gSc.x, .1*gSc.x*sff);
        float dSplit2 = smax(d, -(abs(gP.x) - gSc.x), .1*gSc.x*sff);
    
        if(dSplit<dSplit2){
               d = dSplit;
               id.x += .01;
                
        }
        else {
           
           // If we're exiting on opposite side for the X-lines,
           // mark the color light.
           dark = 0;
           d = dSplit2;
           break; // Outside the inner shape orbit, so break.
        }
        
        // Splitting the box into two Y regions Inner and outer
        dSplit = smax(d, abs(gP.y) - gSc.y, .1*gSc.y*sff);
        dSplit2 = smax(d, -(abs(gP.y) - gSc.y), .1*gSc.y*sff);
        if(dSplit<dSplit2){
               d = dSplit;
               id.y += .01;
        }
        else {
           
          
           d = dSplit2;
           break; // Outside the inner shape orbit, so break.
        }

  
    } 

    
    // Return the polygon distance, ID and position-based ID.
    return vec4(d, boxID, id);
}

// The square grid.
float gridField(vec2 p){
    
    // Scale, cell ID and local coordinates.
    vec2 sc = gSc;
    vec2 ip = floor(p/sc);
    p -= (ip + .5)*sc;
    
    // Boundary.
    p = abs(p);
    float grid = abs(max(p.x - sc.x*.5, p.y - sc.y*.5)) - sc.x*.005;
    
    return grid;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){


    // Aspect correct screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
    
    // Coordinate copy.
    vec2 oUV = uv;
    
    
    // Log spherical transformation. There is some ID wrapping that needs to 
    // be considered, but it's pretty standard.
    float r = 1.;
    #ifdef LOG_SPHERICAL
    r = length(uv);
    uv = vec2(log2(1./r)/2. + iTime/3., fract(atan(uv.y, uv.x)/6.2831853)*4. + iTime/6.);
    #endif
    
    
    // Scaling, smoothing factor and translation.
    float cSc = 1.; // Things won't wrap at under one.
    float sf = cSc/iResolution.y;
    #ifdef LOG_SPHERICAL
    vec2 p = uv*cSc;
    #else
    float a = (smoothstep(-.15, .15, sin(iTime/3. + .5)) - .5)*atan(1., 2.)*2.;//;
    vec2 p = rot2(a - PI/4.*1.)*uv*cSc;
    #endif
    
    r /= cSc;

    
    #ifdef LOG_SPHERICAL
    float ew = .003; // Edge width.
    #else
    float ew = .004; // Edge width.

    // Animation, if not performing a polar transformation.
    p -= vec2(1, .5)*iTime/12.;
    #endif
    
        

    // Transformed coordinate copy.
    vec2 oP = p;

    // Distance field sample.
     vec4 d4 = distField(p);
    
    // Multiplying the distancs by the radial length for more amenable
    // field values.
    d4.x *= r; 
  
    // Random polygon cell colors.
    float rnd = hash21(d4.zw + .021);
    vec3 oCol = .5 + .45*cos(6.2831*rnd/8. + vec3(0, 1, 2)*1.35);
    
    // Coloring the dark polygons.
    if(dark==1) oCol = oCol.zyx/2.;
     
    
    // Central squares debug.
    //if(d4.y==4.) oCol =  oCol.yxz;
     
    // Greyscale coloring.
    //oCol = vec3(.6, .8, 1)*dot(oCol, vec3(.299, .587, .114));
    
    // Time based color changes.
    //oCol = mix(oCol.yxz*.8, oCol, smoothstep(-.15, .15, sin(iTime/3. + .5))*.8 + .2);

    // Apply some texture.
    vec3 tx = texture(iChannel0, d4.zw*gSc + gP*2.).xyz; tx *= tx;
    oCol *= tx*3. + .4;
    
    // Initializing the overall color.
    vec3 col = oCol*.1;

    // Pattern edges and face color.
    col = mix(col, oCol, (1. - smoothstep(0., sf, d4.x + ew)));
    
      
    #ifdef SHOW_GRID
    // Render the grid.
    float grid = gridField(p);
    col = mix(col, vec3(0), 
                   1. - smoothstep(0., sf*2.*iResolution.y/450., grid*r - ew/2.));
    col = mix(col, vec3(1), 1. - smoothstep(0., sf, grid*r));
    #endif
    
   
    
    // Submitting the color and distance value to the buffer.
    //float dist = max(d4.x/gSc.x, -eCut*2.);
    float dist = d4.x;///gSc.x;
    dist -= (dot(tx, vec3(.299, .587, .114)) - .5)*.005;
    
    fragColor = vec4((max(col, 0.)), dist);
    
}