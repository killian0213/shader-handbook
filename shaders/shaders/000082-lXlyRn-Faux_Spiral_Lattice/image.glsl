// Image (image) — Faux Spiral Lattice by Shane
// https://www.shadertoy.com/view/lXlyRn

/*

	Faux Spiral Lattice
	-------------------
    
    Lattice structures rendered in the impossible isometric style are pretty 
    common, and reasonably simple to make. This particular one has a Mobius 
    spiral applied to it, which makes it look a little more interesting.
    
    None of this is difficult: The lattice consists of cubes and joining beams.
    The cubes are created by rendering quads at the triangle vertices and the
    beams are created by rendering quads at the triangle mid-points. There's a
    bit of fiddly triangle math involved, but nothing too difficult.
    
    The details are below, but the code was rushed, and written off the top of 
    my head without a lot of forethought. The code works fine, and if you
    strip away the excess, you'll find that the code footprint is reasonably
    small. However, for anyone who wants to make one of these, I'd suggest 
    ignoring the code here. Start by creating a triangle grid, then rendering 
    the quads by whatever means you're comfortable with.


	
    Other Examples:
    
    // A similar, but slightly more complicated isometric lattice.
    Isometric Lattice - Shane
    https://www.shadertoy.com/view/tdKfW1

	
    // This is a beautiful static rendering.
    Confusing cubes - sinec
    https://www.shadertoy.com/view/NsKXRd
    

*/

// Mobius spiral transform.
#define MOBIUS

// Face color - Greyscale: 0, Green: 1, Yellow: 2.
#define FACE_COLOR 2

// Link color - Greyscale: 0, Pink: 1, Yellow: 2.
#define LINK_COLOR 1

// Show the triangle grid that the pattern is based on...
// Probably a little redundant in this case, but it's there.
//#define SHOW_GRID


// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }



// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21(vec2 f){
    uvec2 p = floatBitsToUint(f);
    p = 1664525U*(p>>1U^p.yx);
    return float(1103515245U*(p.x^(p.y>>3U)))/float(0xffffffffU);
}


// Standard Mobius transform: f(z) = (az + b)/(cz + d). Slightly obfuscated.
// You could use a 2x2 matrix tranformation as well, if you wanted.
vec2 Mobius(vec2 p, vec2 z1, vec2 z2){

	z1 = p - z1; p -= z2;
	return vec2(dot(z1, p), z1.y*p.x - z1.x*p.y)/dot(p, p);
}

// Standard spiral zoom.
vec2 spiralZoom(vec2 p, vec2 offs, float n, float spiral, float zoom, vec2 phase){
	
	p -= offs;
	float a = atan(p.y, p.x)/6.2831; // Bringing it back to integer range.
	float d = log(length(p));
    // "a*N/3." (for even N only) will work with Mobius (without scaling below) also.
	p = (vec2(a*n + d*spiral, -d*zoom + a) + phase);
    
    // Accounting for the triangle scaling.
    #ifdef MOBIUS
    p *= vec2(1./1.732, 1);
    #endif
    
    return p;
}

// Not a proper quad polygon function, but it's good enough for this example.
float quadP(vec2 p, mat4x2 q){

    float d = -1e5;
    
    for(int i = 0; i<4; i++){
    
        d = max(d, distLineS(p, q[(i + 1)%4], q[i]));
    }
    
    return d;
}


void mainImage(out vec4 fragColor, in vec2 fragCoord){

    
    // Aspect correct screen coordinates.
    float res = min(iResolution.y, 800.);
    vec2 uv = (fragCoord - iResolution.xy*.5)/res;
    
    
    // Global scale factor.
    #ifdef MOBIUS
    // Extra fish-eye distortion. It makes the faux double tunnel effect
    // appear a little more bulbous, or something to that effect.
    uv *= .75 + dot(uv, uv)*.5;
    const float sc = 1.25;
    #else
    const float sc = 1.35;    
    #endif
    // Smoothing factor.
    float sf = sc/res;
    
    // Scene rotation, scaling and translation.
    #ifdef MOBIUS
    mat2 sRot = rot2(-3.14159/4.);
    #else
    mat2 sRot = rot2(-3.14159/6.); //mat2(1, 0, 0, 1);
    #endif
    
    
    vec2 camDir = sRot*normalize(vec2(1.732, 1)); // Camera movement direction.
    vec2 ld = sRot*normalize(vec2(1, -1)); // Light direction.
    vec2 p = sRot*uv*sc;
    
    #ifndef MOBIUS
    // Camera animation when not using the Mobius transform.
    p -= camDir*iTime*scale/3.;
    #endif
    
    
    // Radial coordinate factor. Used for shading.
    float r = 1.;
    // Mobius spiral transformation.
    #ifdef MOBIUS
    // Mobius.
    // Hacky depth shading.
    r = length(p - vec2(.5, 0));
    p = Mobius(p, vec2(-1, -.5), vec2(.5, 0));

    // Spiral zoon.
    r = min(r, length(p - vec2(-.5))); 
    p = spiralZoom(p, vec2(-.5), 5., 3.14159*.2, .5, vec2(-1, 1)*iTime*.25);
    #endif

    
    // Returns the local coordinates (centered on zero), cellID, the 
    // triangle vertex ID and relative coordinates.
    //
    mat3x2 vID, v; // Vertex IDs and relative vertex position.
    vec4 p4 = getTriVerts(p, vID, v);
    // Local cell coordinates
    p = p4.xy;
    // Unique triangle ID (cell position based).
    vec2 ctrID = p4.zw; 
    


    // Equilateral triangle cell side length.
    float sL = length(v[0] - v[1]);
    
    
    float ln = 1e5;
    
    // Edge width.
    #ifdef MOBIUS
    float ew = .0045;
    #else
    float ew = .006;
    #endif
    
    // Precalculating the edge points and edge IDs. You could do this inside
    // the triangle grid function, but here will be fine.
    mat3x2 e, eID;
    for(int i = 0; i<3; i++){
        int ip1 = (i + 1)%3;
        eID[i] = mix(vID[i], vID[ip1], .5);
        e[i] = mix(v[i], v[ip1], .5);
    }


    // Three quads.
    vec3 quad = vec3(1e3);
    
    float poly = -1e5;
    
    // Triangles: A single call to a triangle distance function would
    // be more efficient, but this will do for now.
    for(int i = 0; i<3; i++){
    
        float ed = distLineS(p, v[i], v[(i + 1)%3]);
        poly = max(poly, -ed);   
    
    }
    
    // Line thickness.
    float th = sL/6.*.8660254;
    float fL = sL/2.;

    // Quads for the connecting lines.
    for(int j = 0; j<3; j++){
    
        int i = j;

        float dir = 1.;
        if(gTri<0.){ 
        
           i = 2 - j;        
           dir *= -1.;
        
        }
        
        int ip1 = (i + 1)%3;
        int ip2 = (i + 2)%3;

        vec2 eN0 = -normalize(e[i])*th;
        vec2 eN1 = -normalize(e[ip1])*th;
        float innerLn0 = distLineS(p, v[i] + eN0, v[ip1] + eN0);
        float innerLn1 = distLineS(p, v[ip1] + eN1, v[ip2] + eN1);
        
        quad[i] = max(poly, max(dir*innerLn0, -dir*innerLn1));
   
    }
 
    
      
    // Random colors.
    vec3 sCol = .5 + .45*cos(6.2831*hash21(p4.zw)/1. + vec3(0, 1, 2)*2. - .85);
    
    // Directional shading.
    vec3 sh = vec3(.6, .3, .9);
    
    // Three colors for three directions.
    mat3x3 fCol = mat3x3(vec3(1, .4, .2), vec3(.4, .2, .1), vec3(1, 1, .3));
    ////mat3x3 fCol = mat3x3(vec3(.5), vec3(.2), vec3(1));
    
    // Background color.
    vec3 col = vec3(.025); // fCol[1]/8.;
 
    // Swizzling the shades and colors for alternate triangles.
    if(gTri<0.){
       sh = sh.zxy;
       //fCol = mat3x3(fCol[2],  fCol[0], fCol[1]);
       fCol = mat3x3(vec3(1, 1, .3), vec3(1, .4, .2), vec3(.4, .2, .1));
    
    
    }
    
    // Face quads.
    vec3 face; // Sides.
    vec3 faceEnd; // Face end.
   
    // Main quad and quad shadow vertices.
    mat4x2 pp, ppS;
    
    // Shadow.
    float shadow = 1e5;
    
    // Constructing the face quads.
    for(int i = 0; i<3; i++){
       
         int ip1 = (i + 1)%3;
         int ip2 = (i + 2)%3;
         
         // "gTri<0." is upside down.
         vec2 t0 = normalize(v[ip1] - v[i])*fL;
         vec2 t1 = normalize(v[ip2] - v[ip1])*fL;
         vec2 t2 = normalize(v[i] - v[ip2])*fL;
         // Clockwise from the left.
         pp[0] = v[i];
         pp[1] = v[i] + t0;/// - t2;////////
         pp[2] = v[i] + t0 + t1;
         pp[3] = v[i] + t1;
         
          
         
         // Rotating and reversing points on adjoining (upside down) triangles.
         if(gTri>0.){
          
            pp[3] = v[i];
            pp[2] = v[i] - t2;
            pp[1] = v[i] - t2 - t1;
            pp[0] = v[i] - t1;
            
            ppS = mat4x2(pp[0], mix(pp[0], pp[1], .5), pp[2], pp[3]);
             
            if(i==2) shadow = quadP(p, ppS);
      
         }
         else {
         
            ppS = mat4x2(pp[0], pp[1], mix(pp[1], pp[2], .5), pp[3]);
            if(i==0) shadow = quadP(p, ppS);
         
         }
         
          
         face[i] = quadP(p, pp);
         
         float divLn = distLineS(p, v[i], v[ip2]);
         float smCDist = (fL - th)/2.*.75;
         float eD = (smCDist);
         quad[i] = max(quad[i], (divLn + eD));
         quad[i] = max(quad[i], -(divLn + (sL - fL)*.8660254));
   
         
    
    }
    ///////////
    
    
   
    // Rendering the faces, dark edges, etc.
    float tempR = r; 
    float sR = sqrt(tempR);
    float rimW = scale/10.; // Inner quad width.

    
    for(int i = 0; i<3; i++){
    
    
         int j = i;
         if(gTri<0.) j = (i + 1)%3;

         // Coloring.
         vec3 oCol = fCol[(i + 2)%3];
         
         #if FACE_COLOR == 0
         oCol = vec3(1)*dot(oCol, vec3(.299, .587, .114));
         #elif FACE_COLOR == 1
         oCol = fCol[i].yxz;
         #endif
         
         // Faces, then the face ends, and finally, the quad lines.
         col = mix(col, oCol*.05, 1. - smoothstep(0., sf, face[i]*r));
         vec3 eCol = mix(oCol*1.3, vec3(1), .1);
         col = mix(col, eCol, 1. - smoothstep(0., sf, (face[i] + ew/sR)*r));
         
     
         col = mix(col, oCol*.05, 1. - smoothstep(0., sf, (face[i] + rimW)*r));
         col = mix(col, oCol, 
               1. - smoothstep(0., sf, (face[i] + (rimW + ew*1./sR))*r));
    
    }
    
    
    // Distance for inner dark quads.
    rimW = scale/13.;
    
    // The shadow length is resolution dependent.
    float shF = iResolution.y/450.;

    // Rendering the lattice beams.
    for(int i = 0; i<3; i++){

         int j = i;
         if(gTri<0.) j = (i + 2)%3;

         // Colors.
         vec3 oCol = fCol[i];
         //
         #if LINK_COLOR == 0
         oCol = vec3(1)*dot(oCol, vec3(.299, .587, .114));
         #elif LINK_COLOR == 1
         oCol = fCol[i].xzy;
         #endif

         // Applying the lattice beam quads to the background.
         // Faux ambient occlusion.
         col = mix(col, vec3(0), (1. - smoothstep(0., sf*shF*12., 
                   max(quad[i], face[j] + .03)))*.5);
         col = mix(col, oCol*.05, 1. - smoothstep(0., sf, quad[i]*r));
         vec3 eCol = mix(oCol*1.3, vec3(1), .1);
         col = mix(col, eCol, (1. - smoothstep(0., sf, (quad[i] + ew/sR)*r)));

         col = mix(col, oCol*.05, 1. - smoothstep(0., sf, (quad[i] + rimW)*r));
         col = mix(col, oCol, 
               1. - smoothstep(0., sf, (quad[i] + (rimW + ew*1./sR))*r));

    }

    // Applying the faux shadows.
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*shF*4., shadow))*.5);


    // Post processing colors. Not that important.
    uv = fragCoord/iResolution.xy - .5;
    vec3 oCol = vec3(1.2, .8, .6);
    #if FACE_COLOR == 0
    oCol = vec3(1)*dot(oCol, vec3(.299, .587, .114));
    #elif FACE_COLOR == 1
    oCol = oCol.yxz/(1. + oCol.yxz)*2.;
    #endif

    #ifdef MOBIUS
    col *= oCol*smoothstep(.025, .5, tempR);
    //col = mix(col.zyx, col.yzx, smoothstep(0., 1., r));
    #if 0
    col = mix(col, col.zyx, 1. - smoothstep(.3, .7, r));
    col = mix(col, col.yxz, smoothstep(.3, 1., -uv.y + uv.x/2. + .4)); 
    #else
    col = mix(col, col.zyx, smoothstep(.3, .8, -uv.y + uv.x/2. + .5)); 
    #endif
    #else
    col *= oCol;
    col = mix(col, col.zyx, smoothstep(.1, .9, -uv.y + uv.x/2. + .5));  
    #endif


    #ifdef SHOW_GRID
    // Rendering the grid.
    vec3 svCol = col;
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, (abs(poly*r) - ew*1.5)));
    col = mix(col, svCol*4. + .8, 1. - smoothstep(0., sf, (abs(poly*r) - ew/3.*sqrt(r))));
    #endif
    
    // Vignette.
    //uv = fragCoord/iResolution.xy;
    //col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , 1./16.);

    // Rough gamma correction.
    fragColor = vec4(sqrt(max(col, 0.)), 1);;
}