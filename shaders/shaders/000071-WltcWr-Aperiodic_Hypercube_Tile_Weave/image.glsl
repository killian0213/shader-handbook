// Image (image) — Aperiodic Hypercube Tile Weave by Shane
// https://www.shadertoy.com/view/WltcWr

/*

    Aperiodic Hypercube Tile Weave
    ------------------------------
    
    In short, this is an orthonormal projection of a five-demensional 
    hypercube lattice (pentagrid) onto a particularly aligned 2D plane. The
    result is a versatile aperiodic tiling of rhomboids -- which have been
    split along the short opposite diagonals to produce a triangular tiling. 
    If you look more closely at the resultant default pattern, you should be 
    able to make out some hidden icosahedral shapes.

    More times than I can count, someone has dropped some exceptionally
    nice code onto Shadertoy demonstrating a concept that is difficult
    to find code for. The other day Zhao Liang posted a rough pixel shader 
    translation of Greg Egan's aperiodic hypercube tiling example written 
    in Javascript, which in turn was based on de Bruijn's algebraic approach 
    to aperiodic tiling -- The link to Zhao Liang's work is below.
    
    Virtually all of the difficult work was put together by Zhao Liang and
    Grey Egan. All I've done is rearrange things a little and utilize it.
    By the way, others on Shadertoy have produced similar code, like 
    Knighty's really nice "Cut n'project" example (link below), but I like 
    the way Zhao's code was presented, so went with that.
    
    The theory behind the method is such a clever piece of applied 
    mathematics that it's difficult to do it justice with a simple example. 
    The explanation as to why this particular method works and the history 
    behind the initial discovery is fascinating and really clever, but kind 
    of lengthy, so I've provided a list of examples and references below that 
    should explain it better than I can.
    
    I seem to say this a lot, but this isn't my area, so any corrections or
    suggestions for improvement are always welcome.



    Other Examples:
    
    // Zhao Liang's Shadertoy example. I've always wanted to produce one
    // of these patterns using this method, so was pretty happy to see it.
    Impossible aperiodic tiling - neozhaoliang
    https://www.shadertoy.com/view/wsKBW1  
    
    // Also involves 5D projection. Very nice, and explained well. 
    Cut n'project - knighty
    https://www.shadertoy.com/view/XdtBzH
    //
    // A related tiling. I'd like to do a standalone version along 
    // these lines too at some stage.
    Ammann-Beenker - knighty
    https://www.shadertoy.com/view/MddfzH
    
    
    References:
    
    deBruijn -- Mathematical Details - Greg Egan
    https://www.gregegan.net/APPLETS/12/deBruijnNotes.html
    
    Penrose Tilings -- Tied up in Ribbons
    http://www.ams.org/publicoutreach/feature-column/fcarc-ribbons
    
    Penrose Tiling - Andrejs Treibergs
    http://www.math.utah.edu/~treiberg/PenroseSlides.pdf
    
   
*/



// Random weave, or not. With a PN value of 5 or more, the patterns are
// still interesting.
#define RANDOM

// Display the weave.
#define WEAVE

// Display the points.
#define POINTS

// Replace the split triangle with the original rhomboids
// to show the more traditional Penrose style tiling. Commenting
// out the weave, above will make it clearer.
//#define RHOMBOIDS

///////

// Number of grid directions, which relate to the hypercube dimension. 
// I stuck with the original 5, as it looks nicest. However, I modified
// things slightly so that it will work with other numbers -- about 
// 3 to 9. More than that and the pattern gets too tight. PN of 3 will 
// give you back a basic isometric grid -- subdivided into triangles.
#define PN 5

// As Zhao Liang pointed out, halving the grid numbers is the correct way to 
// handle even grid numbers, as it will result in an Ammann-Beenker tiling.
// However, not doing so will still produce an interesting tiling pattern. 
// For instance, choosing "PN = 4" and commenting out the following will produce 
// a basic Truchet pattern.
#define AMMANN_BEENKER


 

// Note: I've left Zhao Liang's functions and comments largely untouched, but have
// rewritten them to make it a litle more compact. However, that wouldn't necessarily
// translate to speed or readability, so if you're interested in this kind of thing, 
// I'd strongly suggest referring to the original code, and perhaps looking at 
// Greg Egan's original Javascript.

// Grid directions.
vec2[PN] grid; 
// Five individual grid shift values. 
float[PN] shift; 

// The rhombus information.
struct Rhombus{

    // r, s for the r-th and s-th grids.
    int r, s;
    // kr, ks, for the lines in the two grids.
    float kr, ks;
    
    // Local coordinates and center.
    vec2 p, cent;
 
    // Rhombus vertices.
    vec2[4] vert; 
 
}; 
 

// Find the vertices of the rhombus corresponding to the intersection point P,
// where P is the intersection of the kr-th line and ks-th line in the r/s grids.
void rhombusVerts(int r, int s, float kr, float ks, out vec2[4] vert){
 
    // Produce points with +/- coordinates in intersection dimensions to 
    // complete projection... I was too lazy to double check this, but it
    // seems to project to the plane as advertised, so that's good enough
    // for me. :)
    vec2 pI = grid[r]*(ks - shift[s]) - grid[s]*(kr - shift[r]);
    pI = vec2(-pI.y, pI.x)/grid[s - r].y;
  
     
    // Convert to screen coordinates.
    vec2 sum = grid[r]*kr + grid[s]*ks;
    for(int k=0; k<PN; k++) {
    
       // Intersection point notwithstanding, project the other points to 
       // the "m + 1"-th line in the k-th grid.
       if(k != r && k != s) sum += grid[k]*ceil(dot(pI, grid[k]) + shift[k]); 
    }
     
    // Four vertices.
    vert[0] = sum, vert[1] = sum + grid[r], vert[3] = sum + grid[s];
    vert[2] = vert[1] + grid[s];

}
 
 
// Determine which rhombus the transformed point lies in by iterating over all possible 
// combinations... Part of me wonders whether there is a faster way, but GPUs are fast
// anyway and for "PN = 5," this is at most 40 checks (or thereabouts), which is more
// than doable.
Rhombus rhombusInfo(vec2 p){


    // Initate the rhombus struct.
    Rhombus rb;
    rb.p = vec2(0);
    rb.vert = vec2[4](vec2(0), vec2(0), vec2(0), vec2(0));
    
    float[PN] pindex;

    float theta;
    for(int k=0; k<PN; k++){
    
        // Initiate the grid directions -- We choose the fifth roots of unity.
        // Note the 1e-5 on the end. It's a hack I've added to make it work
        // with other odd PN values. The tiny extra shift is a hack to get it
        // working when PN is three.
        shift[k] = 1./float(PN) + (PN==3? 1e-5 : 0.); // Penrose.
        //shift[k] = hash21(vec2(k) + iDate.w)*.999 + .001; // Random shift option.
        //shift[k] = .5; // Etc.
        
        #ifdef AMMANN_BEENKER
        // Halve the number of grids for even numbers. 
        theta = PI/float(PN)*float(k)*((PN%2 == 1)? 2. : 1.);
        #else
        // The correct way to handle even numbered grids occurs above. However, you 
        // can still achieve a nice tiling pattern with double the grid numbers.
        theta = PI*2./float(PN)*float(k);
        #endif
       
        grid[k] = vec2(cos(theta), sin(theta));
        
        // Project the point to the m-th line in the k-th grid.
        pindex[k] = (dot(p, grid[k]) + shift[k]);
        
   
        // DeBruijn_transform.
        // This is the "continous" transformation that maps a pixel to its position in the tiling
        rb.p += grid[k]*pindex[k]; // Project "p" to the k-th grid;
         
    } 
    
    
    // Iterate over all rhomboids to determine which one we're inside, then return
    // the pertinent information, like vertices, etc.
    for(int r = 0; r<PN - 1; r++){
    
        for(int s = r + 1; s<PN; s++){
        
            // Thanks to Zhao Liang for realizing that even grid numbers
            // require extra rhomboid searches.
            for(int drs = 0; drs<9; drs++){
                
                // Odd numbered grids only require a 2x2 search. This is a
                // hacky way to get around that.
                if(PN%2==1 && drs<4) continue;
                
                float kr = floor(pindex[r]) + float((drs/3) - 1);
                float ks = floor(pindex[s]) + float((drs%3) - 1);
                rhombusVerts(r, s, kr, ks, rb.vert);

                if(sdPoly4(rb.p, rb.vert)<=0.){

                    rb.r = r, rb.s = s, rb.kr = kr, rb.ks = ks;
                    r = s = PN; // Forcing a complete break?
                    drs = 9;
                    break;
                }
                
            }
       }         
    }
 
    // I noticed that the winding order was backward on some rhombuses, so
    // had to fix that.
    if(winding(rb.vert)>0.){
       swap(rb.vert[0], rb.vert[2]);
    }
    
    // Rhombus center.
    rb.cent = (rb.vert[0] + rb.vert[1] + rb.vert[2] + rb.vert[3])/4.;
    
    return rb; // Return the rhombus.

}

 

void mainImage(out vec4 fragColor, in vec2 fragCoord){


    // Aspect correct screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;

    // Scale.
    float gSc = 3.;
    // Readjusting the scale for different dimensions.
    if(PN==3) gSc += 1.; 
    if(PN>5) gSc = max(3. - float(PN - 5)*.5, 1.5);
    
    // Smoothing factor.
    float sf = gSc*2./iResolution.y;
    
    // Scaling and translation.
    vec2 p = uv*gSc + iTime/4.;
    

    // Obtain the rhombus information. This includes local coordinates
    // and vertices.
    Rhombus rh = rhombusInfo(p);
    
    
   
    // Rhobus vertices and mid edge points.
    vec2[4] v = rh.vert; 
    vec2[4] e;
    e[0] = mix(v[0], v[1], .5), e[1] = mix(v[1], v[2], .5);
    e[2] = mix(v[2], v[3], .5), e[3] = mix(v[3], v[0], .5);
    
    // Mid edge point normals.
    vec2[4] n;
    n[0] = normalize(v[0] - v[1]).yx*vec2(1, -1), n[1] = normalize(v[1] - v[2]).yx*vec2(1, -1);
    n[2] = normalize(v[2] - v[3]).yx*vec2(1, -1), n[3] = normalize(v[3] - v[0]).yx*vec2(1, -1);
 
     
    // Splitting the rhombus across the shortest opposite edge distance into two triangles.
    float shortest = length(v[0] - v[2]);
    int ind2 = length(v[0] - v[2])<length(v[1] - v[3])? 0 : 1;
 
    // Determine which triangle we're in.
    float wt = line(rh.p, v[ind2], v[(ind2 + 2)%4]);
    int triIndex = wt<0.? 0 : 1;
   
    // Triangle information.
    vec2[3] tri0;
    if(triIndex == 0) tri0 = vec2[3](v[ind2], v[(ind2 + 1)%4], v[(ind2 + 2)%4]);
    else tri0 = vec2[3](v[ind2], v[(ind2 + 2)%4], v[(ind2 + 3)%4]);
    // Triange center.
    vec2 triCent = (tri0[0] + tri0[1] + tri0[2])/3.;
    
    // The triangle distance field.
    float tri = sdTriR(rh.p, tri0[0], tri0[1], tri0[2]);
    
    // Triangle ID.
    int index = ((rh.r + rh.s)*2 + triIndex);
    #ifdef RHOMBOIDS
    index = ((rh.r + rh.s)*2);
    #endif
    
    // Using the ID for some color.
    vec3 oCol = .5 + .45*cos(6.2831*(float(index))/float(PN*PN*2)*2. + vec3(0, 1, 2) - .25);
    vec3 oCol2 = .5 + .45*cos(6.2831*dot(triCent, vec2(1))/float(PN*2) + vec3(0, 1, 2) - .25);
    //oCol = vec3(float(index)/50.);
    oCol = mix(oCol, pow(oCol*oCol2, vec3(.65))*2., .25); 
    oCol = mix(oCol, oCol.xzy, float(index)/float(PN*PN)/2.*3./6.);  
    
     // Initializing the scene background color.
    vec3 col = vec3(.1);
    
    // Line width.
    float lw = .02;
    
    #ifdef RHOMBOIDS
    tri = sdPoly4(rh.p, rh.vert) + lw;
    #endif
    
    // Render the colored background triangles.
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*8., tri))*.75);
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, tri));
    col = mix(col, oCol, 1. - smoothstep(0., sf, tri + lw));       
    
    /*
    // Incircles (Uncomment the incircle routine also).
    vec3 sCol = col;
    vec3 inCB = inCentRad(tri0[0], tri0[1], tri0[2]);
    float cir = length(rh.p - inCB.xy) - inCB.z/1.25;// + .015;
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, cir))*.9);
    col = mix(col, mix(sCol*1.5, vec3(1), .0), (1. - smoothstep(0., sf, cir + .03)));
    */
    
    // Indices for shuffling, in order to render the chords in random order.
    const int N2 = 4;
    int shuff[N2] = int[N2](0, 1, 2, 3);  // Initializing the shuffle array.

    #ifdef RANDOM   
    // Shuffling the variable array of points and normals -- Six is the maximum. I think this 
    // is the Fisher–Yates method, but don't quote me on it. It's been a while since I've used 
    // a shuffling algorithm, so if there are inconsistancies, etc, feel free to let me know.
    //
    // For various combinatorial reasons, some non overlapping tiles will probably be 
    // rendered more often, but generally speaking, the following should suffice.
    //
    //int index = N;
    for(int i = N2 - 1; i>0; i--){

        
        // Using the cell ID and shuffle number to generate a unique random number.
        float fi = float(i);
        
        // Random number for each edge position.
        float rs = hash21(rh.cent + fi/float(N2));
        
        // Other array point we're swapping with.
        //int j = int(floor(mod(rs*float(index)*1e6, fi + 1.)));
        // I think this does something similar to the line above, but if not, let us know.
        int j = int(floor(rs*(fi + .9999)));
        swap(shuff[i], shuff[j]);
 
     }
     #endif  
     
     
     
    #ifdef WEAVE
    // Using the rhombus mid edge points to create a weave. 
    
    const float aW = .06; // Chord width.
    float tightness = 3. + (float(PN) - 3.)/4.;
    if(PN%2==0) tightness = 3.25;
    #ifdef AMMANN_BEENKER
    // More hacks to help everything work. "One size fits all" options can
    // get messy. :)
    if(PN>=8) tightness =  3. + (float(PN) - 3.)/4.;
    #endif
    
    // Combining the mide edge points and normals.
    vec4[4] p4 = vec4[4](vec4(e[0], n[0]), vec4(e[1], n[1]), vec4(e[2], n[2]), vec4(e[3], n[3]));

    // Chord tighness.
    float cr = length(p4[shuff[0]].xy - p4[shuff[1]].xy)/tightness;
    // Chord distances.
    float arc = doSeg(rh.p, p4[shuff[0]], p4[shuff[1]], cr) - aW;
    cr = length(p4[shuff[2]].xy - p4[shuff[3]].xy)/tightness;
    float arc2 = doSeg(rh.p, p4[shuff[2]], p4[shuff[3]], cr) - aW;

    // Rndering the chords, or arcs.
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*8., arc))*.5);
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, arc));
    col = mix(col, vec3(1), 1. - smoothstep(0., sf, arc + lw*1.6));
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*8., arc2))*.5);
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, arc2));
    col = mix(col, vec3(1), 1. - smoothstep(0., sf, arc2 + lw*1.6));
    #endif

    #ifdef POINTS
    // Rhombus mid edge points... I think that add visual interest,
    // but I could be wrong. :)
    for(int i = 0; i<4; i++){
    
        float dv = length(rh.p - e[i]) - .1; //
        #ifdef RHOMBOIDS
        dv = length(rh.p - v[i]) - .1;
        #endif
        col = mix(col, vec3(0), (1. - smoothstep(0., sf*8., dv))*.5);
        col = mix(col, vec3(0), 1. - smoothstep(0., sf, dv));
        col = mix(col, vec3(1, .7, .6), 1. - smoothstep(0., sf, dv + lw*1.6));
        col = mix(col, vec3(0), 1. - smoothstep(0., sf, dv + .1 - lw));
    }
    #endif
  
    // Rough gamma correction.
    fragColor = vec4(sqrt(max(col, 0.)), 1);
}