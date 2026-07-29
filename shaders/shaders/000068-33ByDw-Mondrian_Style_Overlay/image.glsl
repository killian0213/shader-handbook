// Image (image) — Mondrian Style Overlay by Shane
// https://www.shadertoy.com/view/33ByDw

/*

    Mondrian Style Overlay
    ----------------------
    
    This is a simple generative tessellation pattern rendered in the 
    style (De Stijl) that Piet Mondrian was well known for. I'm not sure 
    who first came up with this particular generative method, but the 
    most well known version was posted on Algorithmic Worlds many years 
    ago. This is not the first implementation on Shadertoy either, since 
    XT95 posted a really nice example years ago.
    
    This particular version is just a precursor to a more involved example 
    that I have planned, but I thought it was interesting enough to post
    in 2D form.
    
    In theory, the process is straight forward: Divide space into square 
    cells, then produce four random (shared) edge points. Once you've done 
    that, render lines from each point toward the center of the cell, then 
    calculate the square formed by the intersections, as well as the four 
    additional surrounding polygons. 
    
    There are a few ways to do that: One is a flat colored line-step 
    method, which is almost trivial. The second method involves CSG bounds 
    and is a little harder, but simple enough. The third involves
    producing ordered lists of all polygons involved and is a lot less
    fun to write. :) Unfortunately, since I'd like to produce a 
    raymarched traversal later, I went for the latter... which I wouldn't 
    recommend. :) Either way, I've rouhgly explained the process below.
    
    In case it needs to be said, a lot of this was written out pretty 
    quickly, so it needs more refinement. I'll endeavor to do that in due 
    course. I'll also post a much simpler trimmed down version.
 
 
    
    Other examples:
    
    // Beautifully written, and involves way, way less code.
    Truchet variation - XT95
    https://www.shadertoy.com/view/llfBWB
    
    // Based on the algorithmic process outlined here:
    Truchet and Mondrian - Samuel Monnier
    https://www.algorithmic-worlds.net/blog/blog.php?Post=20110201

    
*/


// Add windows and a pattern background.
#define HOLES

// Apply more detailed edging.
//#define EDGES

// Bump mapping, of sorts.
#define BUMP_MAP

// Distance type: SDF: 0, Bound: 1.
#define DIST_TYPE 0

// Display the square grid upon which the pattern is built.
//#define GRID



// Global scale.
vec2 gSc = vec2(1)/5.;
 

vec2 cntr; // Polygon center.
float cir; // Center circle.

// Polygon region ID.
int polyID;

// Number of polygon vertices.
int pID;

mat4x2 vID = mat4x2(vec2(-.5, -.5), vec2(-.5, .5), vec2(.5, .5), vec2(.5, -.5));
mat4x2 eID = mat4x2(vec2(-.5, 0), vec2(0, .5), vec2(.5, 0), vec2(0, -.5));

// Storage space for the maximum number of polygon vertices. I think
// the maximum is actually 12, but I'm rounding up to powers of two.
vec2 vP[16]; 

// Generating four random edge points on each of the 
// four (shared) cell edges for a spcified cell.
mat4x2 getEdges(vec2 ip){

    const float rF = .95; // Offset factor.
    vec2 eR = vec2(0, .5*rF); // Offset direction.
    
    // Four cell edge points.
    mat4x2 eM; 
    
    // Iterate through the four cell edges.
    for(int i = 0; i<4; i++){
        
        // Edge ID.
        vec2 edID = ip + eID[i];
        //edID = mod(edID, 4.);
        float rndI = mod(dot(edID, vec2(41, 53)), 4.)/4.;
        //float rndI = hash21(edID);
        float rndD = hash21(edID + .06)<.5? -1. : 1.;
        rndI = sin(TAU*rndI*rndD + iTime*fract(rndD*77.77 + .5))*.5 + .5;
        // rndD =  mod(edID.x + edID.y, 2.) - 1.; // Checkered overlap.
        
        // Mid edge with offset. Y offset then X offset.
        eM[i] = eID[i]*gSc - rndI*rndD*gSc*rF*eR; 
        eR = eR.yx;       
    }
    
    // Four random cell edge points.
    return eM;
}



// A Mondianesque distance field function... I enjoyed writing this about as 
// much as you'll enjoy reading it. :D Serioulsy though, none of this is too
// difficult, but it does involve linear intersections and rendering from the 
// perspective of neighboring cells, etc.
//
// In regard to how it works, comment out the "GRID" define to see the square
// cells and you'll see that four lines are rendered out from random positions
// on shared edges. Each of those lines meet inside the cell to form a square.
// Most of it is pretty easy. However, neighboring cells also have an effect,
// which means that you have to deal with those too... It's all doable, of 
// course, but it involves a lot of fiddly bookkeeping that no one likes, as
// is evident by the complete lack of examples out there. :)
//
vec4 distField(vec2 p){
    
    
     
    vec2 ip = floor(p/gSc);
    p -= (ip + .5)*gSc;
    
    
    vec2 svIP = ip;
 
    // Calculate the four random points on all shared cell edges.
    mat4x2 eM = getEdges(ip);
 
    // Render four lines from the random points above, the determine
    // the central square formed by their intersections.
    vec2 minE = min(vec2(eM[1].x, eM[0].y), vec2(eM[3].x, eM[2].y));
    vec2 maxE = max(vec2(eM[1].x, eM[0].y), vec2(eM[3].x, eM[2].y));
    // Central square vertices.
    mat4x2 p4 = mat4x2(minE, vec2(minE.x, maxE.y), maxE, vec2(maxE.x, minE.y));
    
    // Central square.
    vec2 rDim = (vec2(maxE.x - minE.x, maxE.y - minE.y));
    vec2 rP = mix(minE, maxE, .5);
    vec2 ap = abs(p - rP) - rDim/2.;
    float cPoly = max(ap.x, ap.y); 
     
      
    // Overall distance.
    float d;
     
     
    if(cPoly<0.){
    
        // Inside the central square.
        
        d = cPoly; // Distance.
        polyID = 4; // Region ID.
        pID = 4; // Number of vertices.
        
        // Vertices.
        vP[0] = p4[0], vP[1] = p4[1], vP[2] = p4[2], vP[3] = p4[3];
        
        // Center point.
        cntr = rP;
   
    }
    else{
    
        // We're outside the central square, so we have to determine which 
        // of the four surrounding polygons we're in.
        
        // The space outside the square.
        d = -cPoly;

        
        // Four lines eminating from the edge points.
        vec4 ln;
        for(int i = 0; i<4; i++){
            ln[i] = distLineS(p, eM[i], eM[i] - eID[i]);
        }

        
        // Determining which polygon we're in.
        ln = max(ln, -ln.wxyz);
        for(int i = 0; i<4; i++){
        
            if(ln[i]<0.){ 
            
                polyID = i; // Region ID.
                break;             
            }           
        }
        
        // We now know which of the four polygon regions we're in,
        // so now we have to use CSG to construct the distance
        // information... The vertex information requires more work,
        // and isn't completely nessary (if you're only after bound
        // information). However, I intend to perform a raymarched
        // traversal at some stage, so it's needed for that.
        
        
        // Polyon ID. The only reason we're doing this is so that we
        // don't have to write "polyID" over and over.
        int i = polyID;

        float dir = (i==0 || i==2)? 1. : -1.;
                
        
        // Calculate the vertices and dimensions of the inner square.

        // Inner square intersection point.
        vec2 ro = eM[i];
        vec2 rd = -normalize(eID[i]);
        float t = lineIntersect(ro, rd, eM[(i + 3)%4], eM[(i + 3)%4] - eID[(i + 3)%4]*8.);
        vec2 p0 = ro + rd*t;


        // The other two quadrant lines.
        mat4x2 eMD = getEdges(ip + vID[i]*2.);
        //
        // Inner square intersection point, on the opposite diagonal.
        int k = (i + 1)%4;
        ro = eMD[k];
        rd = -normalize(eID[k]);
        t = lineIntersect(ro, rd, 
                    eMD[(k + 1)%4], eMD[(k + 1)%4] - eID[(k + 1)%4]*8.);
        vec2 p1 = ro + rd*t + vID[i]*2.*gSc;
        
        // Center polygon point.
        cntr = mix(p0, p1, .5);

 

        /////////////
        // One half of the square (two sides).
        d = max(d, ln[i]);
        // The second half (the other two sides).
        vec2 q = p - p1;
        vec2 ln2 = q*sign(vID[i]);
        d = max(d, max(ln2.x, ln2.y));
      
   
        /////////
        // Vertices of the square in the first corner.
        vec2 minI = min(vec2(eMD[1].x, eMD[0].y), vec2(eMD[3].x, eMD[2].y));
        vec2 maxI = max(vec2(eMD[1].x, eMD[0].y), vec2(eMD[3].x, eMD[2].y));
        mat4x2 p4D = mat4x2(minI, vec2(minI.x, maxI.y), maxI, vec2(maxI.x, minI.y));
        
        //
        rDim = (vec2(maxI.x - minI.x, maxI.y - minI.y));
        vec2 rQ = mix(minI, maxI, .5);
        q = p - vID[i]*2.*gSc;
        vec2 aq = abs(q - rQ) - (rDim)/2.;
        float rect = max(aq.x, aq.y);
        d = max(d, -rect);
 

        //////////////////
        #if DIST_TYPE == 0
        // Overall polygon vertices.
        vP[0] = p0;
        vP[1] = vec2(p0.x, p1.y);
        vP[2] = p1;
        vP[3] = vec2(p1.x, p0.y);
        // Reverse vertex order for every odd rectangle.
        if(i%2==1){ 
           // Reverse the list order on alternate cells.
           vec2 tmp = vP[1]; vP[1] = vP[3]; vP[3] = tmp; 
        }
        #endif

        // Overall quadrant square boundary vertices. The idea is to
        // check for smaller  overlapping squares in each corner, then
        // add vertices as necessary.
        mat4x2 cP = mat4x2(vP[0], vP[1], vP[2], vP[3]);

        // Vertex index. There are a guaranteed four vertex points. If
        // an overlapping square is encounterd in any of the main square
        // corners, we'll add three vertex points.
        int vIndex = 0;

        int hit = 0;

        #if DIST_TYPE == 0
        // First corner vertices.
        eM *= dir;
        if(eM[1].x<eM[3].x && -eM[0].y<-eM[2].y){
            // Three extra vertex points per overlapping corner square.             
            vP[vIndex++] = p4[(i + 1)%4];
            vP[vIndex++] = p4[(i + 0)%4];
            vP[vIndex++] = p4[(i + 3)%4];
            hit = 1;
        }
        // If there is no overlapping square in this corner, add the
        // main square corner point only.
        if(hit==0) vP[vIndex++] = cP[0];
        #endif

        ///////////// 

        // Vertices of the square in the second corner.
        mat4x2 eMI = getEdges(svIP + eID[(i + 3)%4]*2.);
        minI = min(vec2(eMI[1].x, eMI[0].y), vec2(eMI[3].x, eMI[2].y));
        maxI = max(vec2(eMI[1].x, eMI[0].y), vec2(eMI[3].x, eMI[2].y));
        mat4x2 p4I = mat4x2(minI, vec2(minI.x, maxI.y), maxI, vec2(maxI.x, minI.y));

        rDim = (vec2(maxI.x - minI.x, maxI.y - minI.y));
        rQ = mix(minI, maxI, .5);
        q = p - eID[(i + 3)%4]*gSc*2.;
        q = abs(q - rQ) - (rDim)/2.;
        rect = max(q.x, q.y);
        d = max(d, -rect);               
        /////////// 
        
        #if DIST_TYPE == 0
        hit = 0;
        // Second corner rectangle.
        eMI *= dir;
        if(-eMI[1].x<-eMI[3].x && eMI[0].y<eMI[2].y){
            //cE = 1;              
            vP[vIndex++] = p4I[(i + 2)%4] + eID[(i + 3)%4]*2.*gSc;
            vP[vIndex++] = p4I[(i + 1)%4] + eID[(i + 3)%4]*2.*gSc;
            vP[vIndex++] = p4I[(i + 0)%4] + eID[(i + 3)%4]*2.*gSc;
            hit = 1;
        }

        if(hit==0) vP[vIndex++] = cP[1];
        #endif



        ///////////////
        #if DIST_TYPE == 0
        hit = 0;

        // Third (opposite diagonal) corner rectangle vertices.
        eMD *= dir;
        if(eMD[1].x<eMD[3].x && -eMD[0].y<-eMD[2].y){
            //cE = 1;              
            vP[vIndex++] = p4D[(i + 3)%4] + vID[i]*2.*gSc;
            vP[vIndex++] = p4D[(i + 2)%4] + vID[i]*2.*gSc;
            vP[vIndex++] = p4D[(i + 1)%4] + vID[i]*2.*gSc;
            hit = 1;
        }


        if(hit==0) vP[vIndex++] = cP[2];
        #endif
        ///////////// 
        
        // Vertices of the square in the forth (and last) corner.
        eMI = getEdges(svIP + eID[i]*2.);
        minI = min(vec2(eMI[1].x, eMI[0].y), vec2(eMI[3].x, eMI[2].y));
        maxI = max(vec2(eMI[1].x, eMI[0].y), vec2(eMI[3].x, eMI[2].y));
        p4I = mat4x2(minI, vec2(minI.x, maxI.y), maxI, vec2(maxI.x, minI.y));

        rDim = (vec2(maxI.x - minI.x, maxI.y - minI.y));
        rQ = mix(minI, maxI, .5);
        q = p - eID[i]*gSc*2.;
        q = abs(q - rQ) - (rDim)/2.;
        rect = max(q.x, q.y);
        d = max(d, -rect);                 
        
        #if DIST_TYPE == 0
        hit = 0;

        // Fourth corner rectangle vertices.
        eMI *= dir;
        if(-eMI[1].x<-eMI[3].x && eMI[0].y<eMI[2].y){
            //cE = 1;              
            vP[vIndex++] = p4I[(i + 0)%4] + eID[i]*2.*gSc;
            vP[vIndex++] = p4I[(i + 3)%4] + eID[i]*2.*gSc;
            vP[vIndex++] = p4I[(i + 2)%4] + eID[i]*2.*gSc;
            hit = 1;
        }

        if(hit==0) vP[vIndex++] = cP[3];
        #endif

        pID = vIndex; // Total number of vertex points for the polygon.

        // Updating the position based ID to the corner.
        ip += vID[i];
 
 
    
    }
    
    
    #if DIST_TYPE == 0
    // If using a signed distance field value, apply IQ's polygon formula.
    d = sdPoly(p, vP, pID);
    #endif
    
    // Debug: Center circle point.
    cir = length(p - cntr);
    
    
    /*
    // Vertex point experiments. I've left it here to use later.
    cir = 1e5;
    vec2[16] cVP = vP;
    for(int i = 0; i<pID; i++){
    
       vec2 n0 = normalize(cVP[(i + pID - 1)%pID] - cVP[i]).yx*vec2(1, -1);
       vec2 n1 = normalize(cVP[(i + 1)%pID] - cVP[i]).yx*vec2(1, -1);
       
       //vP[i] = cVP[i] + (n1 - n0)*.01;
       vec2 vI = cVP[i] + (n1 - n0)*.02;
       cir = min(cir, length(p - vI));
    }
    */

    
    #ifdef HOLES
    // Create some windows.
    if(hash21(ip + .23)<.4 && gSc.x>1./5. - .001){
        d = abs(d + .09*gSc.x) - .09*gSc.x;
        #ifndef EDGES
        d = max(d, -abs(d + .0125) - .01);
        cir = 1e5;
        #endif
    }
    #endif
    
    
    #ifdef EDGES
    // Applying more detailed edging.
    d = max(d, -abs(d + .0125) - .005);
    #endif
    
     
    // Subtle, distance-field-based corrugation.
    float lN = 80.;
    float pat = abs(fract(d*lN + .5) - .5)/lN;// - .006/3.;
    d = mix(d*1.055, d*.9, smoothstep(0., .02, pat));
    

    // Distance field ID and polygon region ID.
    return vec4(d, ip, polyID);
}

// Square grid function.
float grid(vec2 p){
 
    vec2 ip = floor(p/gSc);
    p -= (ip + .5)*gSc;
    
    return sBox(p, gSc/2.);

}


void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    // Aspect corret coordinates.
    vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;

    
   
    // Scaling and translation.
    vec2 p = uv - vec2(0, iTime/12.);
    
    
    // Scene field calculations.
    
    
    //////////////// 
    #ifdef HOLES
    
    // Blue background texture.
    
    // Rescales distance field sample.
    gSc /= 1.5;
    vec4 d4B = distField(p + .5 - vec2(iTime/12., 0));
    gSc *= 1.5;
     
    float dB = d4B.x; // Distance.
    vec2 idB = d4B.yz; // ID.
    
    // Random color.
    float rndB = hash21(idB + .1);
    vec3 rColB = .5 + .45*cos(TAU*rndB/3.5 + vec3(0, 1, 2)*1.5 - .3);
    //
    float grB = dot(rColB, vec3(.299, .587, .114));
    vec3 pColB = polyID==4? vec3(grB*.5 + .5)*vec3(.97, 1, 1.03) : rColB.zyx*1.2;
    
    /*
    // Tile distance field lines.
    float lNB = 80.;
    float patB = abs(fract(dB*lNB + .5) - .5)/lNB - .006/3.;
    pColB = mix(pColB*1.1, pColB*.9, 1. - smoothstep(0., sf, patB));
    */
    
    #endif
    //////////


    // Nearby highlighting sample.
    #ifdef BUMP_MAP
    // Hilighting sample.
    vec2 ld = normalize(vec2(-2.5, -1));
    vec4 d4Hi = distField(p - ld*.003);
    #endif

    // Scene object.
    vec4 d4 = distField(p);
    float d = d4.x; // Distance.
    vec2 id = d4.yz; // ID.
    
    // Smoothing factor.
    float sf = 1./iResolution.y;
    
    // Shadow length factor.
    float shF = iResolution.y/450.;
    
    float ew = .006; // Edge width.
     
    // Scene color -- Set to the background.
    vec3 col = vec3(.25);
    #ifdef HOLES
    col = mix(col, vec3(0), 1. - smoothstep(0., sf*shF*16., dB)); // Edge, or strke.
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, dB)); // Edge, or strke.
    col = mix(col, pColB, 1. - smoothstep(0., sf, dB + ew*.8)); // Top layer.
    #endif
    
    // ID-based coloring.
    float rnd = hash21(id + .1);
    vec3 rCol = .5 + .45*cos(TAU*rnd/3.5 + vec3(0, 1, 2)*1.5 - .3);
    // Greyscale.
    float gr = dot(rCol, vec3(.299, .587, .114));
   
    //vec3 pCol = vec3(.75);
    vec3 pCol = polyID<4? vec3(gr*.5 + .5)*vec3(.97, 1, 1.03) : rCol*1.2;
 
    
    /*
    // A more traditional Mondian palette.
    float palID = floor(hash21(id + .04)*5.);
    if(palID == 0.) pCol = vec3(1, .1, .1);
    if(palID == 1.) pCol = vec3(1, 1, .1);
    if(palID == 2.) pCol = vec3(0, .5, 1);
    if(palID == 3.) pCol = vec3(.1);
    */
    
    
    #ifdef BUMP_MAP
    // Directional derivative based bump mapping calculations. It's not
    // as good as the proper multisample one's but it's quick and simmple.
    float b = max(.5 + (d4Hi.x - d)/.003, 0.);
    float b2 = max(.5 + (max(d4Hi.x, -.0125) - max(d, -.0125))/.003, 0.);
    
    pCol *= .5 + b*b*.5 + b2*b2*.5;
    #else
    pCol *= 1.1;
    #endif
    
    /*
    // Tile distance field lines.
    float lN = 80.;
    float pat = abs(fract(d*lN + .5) - .5)/lN - ew/3.;
    pCol = mix(pCol*1.1, pCol*.9, 1. - smoothstep(0., sf, pat));
    */
    
    // Rendering the Mondrian pattern onto the background.
    //
    col = mix(col, col*.4, 1. - smoothstep(0., sf*shF*24., d)); // AO.
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, d - ew/2.)); // Edge, or strke.
    col = mix(col, pCol, 1. - smoothstep(0., sf, d + ew)); // Top layer.
    
     
    // Debug: Center point.
    //col = mix(col, vec3(0), 1. - smoothstep(0., sf, cir - ew*1.25));
    //col = mix(col, vec3(0), 1. - smoothstep(0., sf, cir - ew*1.65));
    //col = mix(col, vec3(1), 1. - smoothstep(0., sf, cir - ew*.5));

    #ifdef GRID
    // Square grid.
    float grd = abs(grid(p)) - ew;
    vec3 svCol = col;
    col = mix(col, col*.5, 1. - smoothstep(0., sf*shF*5., grd ));
    col = mix(col, col*.35, 1. - smoothstep(0., sf, grd));
    col = mix(col, (svCol + .1)*vec3(1, .6, .1)*3., 1. - smoothstep(0., sf, grd + ew*.7)); 
    #endif
   
   
    // Vignette.
    uv = fragCoord/iResolution.xy;
    col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , 1./16.);


    // Output to screen
    fragColor = vec4(sqrt(max(col, 0.)), 1);
}