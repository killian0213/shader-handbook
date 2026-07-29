// Image (image) — Multiscale Triangle Truchet by Shane
// https://www.shadertoy.com/view/dllyD7

/*

    Multiscale Triangle Truchet
    ---------------------------
    
    I put this together ages ago, but took a while to pretty it up
    enough to deem it worth releasing. Anyway, if you've ever seen 
    one of these patterns on stock image sites, or wherever, and 
    wondered how they were made, I hope this helps.
    
    Construction is reasonably straight forward: Produce a triangle 
    grid, subdivide it, create separate concentric circle arcs around 
    each triangle cell vertex, then render each of them in random 
    order -- A quick way to do that is to randomly rotate the local 
    triangle cell coordinates then render the arcs in their original
    order.
    
    If you investigate these patterns on the net, you'll see that 
    they're all flat in appearance, which look pretty cool as well, 
    however, to differentiate this example from others, I rendered 
    it in a faux 3D style.
    
    
    Other examples:
    
    // A simpler to understand square version, for anyone interested.
    Subdivided Grid Truchet Pattern - Shane
    https://www.shadertoy.com/view/NdKfRD
    
    // An extruded simplex weave. Eventually, I'll convert this
    // example to the 3D environment.
    Simplex Weave - Shane
    https://www.shadertoy.com/view/WdlSWl
    
    // There aren't a great deal of subdivided triangle grid examples
    // on here, but here's a simple one.
    tritree 2 - FabriceNeyret2 
    https://www.shadertoy.com/view/MlsBzH


*/

// The subdivided triangle grid. Oddly enough, viewing the grid can help
// facilate a better understanding of how a grid pattern is formed. :)
//#define GRID 

// Two color schemes - Red and white: 0, Black and white: 1.
#define COLOR 0

// Number of possible subdivisions. Larger numbers will work,
// but will slow your machine down. This example is designed to
// work with numbers 0 to 2. For 3 and 4, etc, you'll need to change
// the triangle scale variable below.
#define DIV_NUM 2
// Triangle scale.
#define triSc 1./3.



// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.619, 57.583)))*43758.5453); }


// Signed distance to a line passing through A and B.
float distLineS(vec2 p, vec2 a, vec2 b){

   b -= a; 
   return dot(p - a, vec2(-b.y, b.x)/length(b));
}


// IQ;s signed distance to an equilateral triangle.
// https://www.shadertoy.com/view/Xl2yDW
float getTri(in vec2 p, in float r){

    const float k = sqrt(3.0);
    p.x = abs(p.x) - r;
   
    p.y = p.y + r/k; 
    if(p.x + k*p.y>0.) p = vec2(p.x - k*p.y, -k*p.x - p.y)/2.;
    p.x -= clamp(p.x, -2.*r, 0.);
    return -length(p)*sign(p.y);
   
    /*   
    const float k = sqrt(3.0);
    p.y = abs(p.y) - r; // This one has been reversed.
    p.x = p.x + r/k;
    if( p.y + k*p.x>0.) p = vec2(-k*p.y - p.x, p.y - k*p.x)/2.0;
    p.y -= clamp( p.y, -2.0, 0.0 );
    return -length(p)*sign(p.x);
    */  
}


////////
// A 2D triangle partitioning. I've dropped in an old routine here.
// It works fine, but could do with some fine tuning. By the way, this
// will partition all repeat grid triangles, not just equilateral ones.

// Skewing coordinates. "s" contains the X and Y skew factors.
vec2 skewXY(vec2 p, vec2 s){ return mat2(1, -s.yx, 1)*p; }

// Unskewing coordinates. "s" contains the X and Y skew factors.
vec2 unskewXY(vec2 p, vec2 s){ return inverse(mat2(1, -s.yx, 1))*p; }

// Triangle scale: Smaller numbers mean smaller triangles, oddly enough. :)
const float scale = triSc;

// Rectangle scale.
const vec2 rect = (vec2(1./.8660254, 1))*scale;

// Skewing half way along X, and not skewing in the Y direction.
const vec2 sk = vec2(rect.x*.5, 0)/scale;

// Triangle ID.
float gTri;

// Number of random triangle subdivisions.
float subSc = 0.;

// Triangle routine, with additinal subdivision. It returns the 
// local tringle coordinates, the vertice IDs and vertices.
vec4 getTriVerts(in vec2 p, inout mat3x2 vID, inout mat3x2 v){
   

    // Skew the XY plane coordinates.
    p = skewXY(p, sk);
    
    // Unique position-based ID for each cell. Technically, to get the central position
    // back, you'd need to multiply this by the "rect" variable, but it's kept this way
    // to keep the calculations easier. It's worth putting some simple numbers into the
    // "rect" variable to convince yourself that the following makes sense.
	vec2 id = floor(p/rect) + .5; 
    // Local grid cell coordinates -- Range: [-rect/2., rect/2.].
	p -= id*rect; 
    
    
    // Equivalent to: 
    //gTri = p.x/rect.x < -p.y/rect.y? 1. : -1.;
    // Base on the bottom (-1.) or upside down (1.);
    gTri = dot(p, 1./rect)<0.? 1. : -1.;
   
    // Puting the skewed coordinates back into unskewed form.
    p = unskewXY(p, sk);
    
    
    // Vertex IDs for each partitioned triangle: The numbers are inflated
    // by a factor of 3 to ensure vertex IDs are precisely the same. The
    // reason behind it is that "1. - 1./3." is not always the same as
    // "2./3" on a GPU, which can mess up hash logic. However, "3. - 2."
    // is always the same as "1.". Yeah, incorporating hacks is annoying, 
    // but GPUs don't work as nicely as our brains do, unfortunately. :)
    if(gTri<0.){
        vID = mat3x2(vec2(-1.5, 1.5), vec2(1.5, -1.5), vec2(1.5));
    }
    else {
        vID = mat3x2(vec2(1.5, -1.5), vec2(-1.5, 1.5), vec2(-1.5));
    }
    
    // Triangle vertex points.
    for(int i = 0; i<3; i++) v[i] = unskewXY(vID[i]*rect/3., sk); // Unskew.
  
    // Centering at the zero point.
    vec2 ctr = (v[0] + v[1] + v[2])/3.;
    p -= ctr;
    v[0] -= ctr; v[1] -= ctr; v[2] -= ctr;
    
     // Centered ID, taking the inflation factor of three into account.
    vec2 ctrID = (vID[0] + vID[1] + vID[2])/3.;//vID[2]/3.;
    vec2 tID = id*3. + ctrID;   
    // Since these are out by a factor of three, "v = vertID*rect/3.".
    vID[0] -= ctrID; vID[1] -= ctrID; vID[2] -= ctrID;
    
    // A number to represent the number of subdivisions a triangle
    // has undergone.
    subSc = 0.;
    
    /////////////////////////////
    #if DIV_NUM > 0
    
    // The random triangle subdivsion addition. I put this together pretty
    // quickly, so there'd probably be better ways to do it. By the way, if
    // you know of ways to improve the following, feel free to let me know.
    for(int j = 0; j<DIV_NUM; j++){
    
        // Randomly subdivide.
        if(hash21(tID + float(j + 1)/128.)<.4){
            
            // Increase the subdivision number.
            subSc++;

            // Subdividing an equilateral triangle into four smaller 
            // equilateral ones. Use the "GRID" define and refer to the 
            // resultant imagery, if you're not sure.

            mat3x2 mid, midID; // Midpoints.
            vec3 dl; // Divding lines.

            for(int i = 0; i<3; i++){
                int ip1 = (i + 1)%3;
                mid[i] = mix(v[i], v[ip1], .5); // Mid points.
                midID[i] = mix(vID[i], vID[ip1], .5); // Mid point IDs.
                // Divinding lines -- separating  the midpoints.            
                dl[i] = distLineS(p, mid[i], mix(v[ip1], v[(i + 2)%3], .5));  
            }

            // Choosing which of the four new triangles you're in. The top
            // triangle is above the first midpoint dividing line, the
            // bottom right is to the right of the next diving line and the
            // bottom left is to the left of the third one. If you're not in
            // any of those triangles, then you much be in the middle one...
            // By the way, if you know of better, faster, logic to subdivide
            // a triangle into four smaller ones, feel free to let me know. :)
            //
            if(dl[0]<0.){ // Top.   
                v[0] = mid[0]; vID[0] = midID[0];
                v[2] = mid[1]; vID[2] = midID[1];        
            }
            else if(dl[1]<0.){ // Bottom right.   
                v[1] = mid[1]; vID[1] = midID[1];
                v[0] = mid[2]; vID[1] = midID[2];        
            }
            else if(dl[2]<0.){ // Bottom left.   
                v[2] = mid[2]; vID[2] = midID[2];
                v[1] = mid[0]; vID[1] = midID[0];        
            }  
            else { // Center.
               v[0] = mid[0]; vID[0] = midID[0];
               v[1] = mid[1]; vID[1] = midID[1];
               v[2] = mid[2]; vID[2] = midID[2];  
               gTri = -gTri;
            }

            // Triangle center coordinate.
            ctr = (v[0] + v[1] + v[2])/3.;
            // Centering the coordinate system -- vec2(0) is the triangle center.
            p -= ctr;
            v[0] -= ctr; v[1] -= ctr; v[2] -= ctr;

             // Centered ID, taking the inflation factor of three into account.
            ctrID = (vID[0] + vID[1] + vID[2])/3.;//vID[2]/3.;
            tID += ctrID;   
            // Since these are out by a factor of three, "v = vertID*rect/3.".
            vID[0] -= ctrID; vID[1] -= ctrID; vID[2] -= ctrID;
        }
    }
    
    #endif

    // Triangle local coordinates (centered at the zero point) and 
    // the central position point (which acts as a unique identifier).
    return vec4(p, tID);
}

//////////
// Rendering a colored distance field onto a background. I'd argue that
// this one simple function is the key to rendering most vector styled
// 2D Photoshop effects onto a canvas. I've explained it in more detail
// before. Here are the key components:
//
// bg: background color, fg: foreground color, sf: smoothing factor,
// d: 2D distance field value, tr: transparency (0 - 1).
vec3 blend(vec3 bg, vec3 fg, float sf, float d, float tr){

     return mix(bg, fg, (1. - smoothstep(0., sf, d))*tr);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){


    // Aspect correct screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
    
    // Global scaling and translation.
    float gSc = 1.;
    // Smoothing factor, based on global scaling.
    float sf = gSc/iResolution.y;
    // Depending on perspective; Moving the oject toward the bottom left, 
    // or the camera in the north easterly (top right) direction. 
    vec2 p = rot2(-3.14159/12.)*uv*gSc - vec2(-.57735, -1)*iTime/32.;
    
 
    // Cell coordinate, ID and triangle orientation id.
    // Cell vertices and vertex ID.
    mat3x2 v, vID;
    
    // Returns the local coordinates (centered on zero), cellID, the 
    // triangle vertex ID and relative coordinates.
    vec4 p4 = getTriVerts(p, vID, v);
    p = p4.xy;
    vec2 triID = p4.zw;
    float tri = gTri;
    
    float sL = length(v[0] - v[1]);
    
    // Grid triangles. Some are upside down.
    //vec2 q = tri<0.? p*vec2(1, -1) : p;
    vec2 q = p*vec2(1, tri); // Equivalent to the line above.
    float tr = getTri(q, length(v[0])*.8660254);

   
    // Nearest vertex ID.
    float vert = 1e5;
    vec3 arc, ang; // Three vertex arcs and corresponding angles.
   
    
    // Random value based on the overall triangle ID.
    float rnd = hash21(triID + .1);
    
    // Random rotation, in incrents of 120 degrees to maintain symmetry.
    p = rot2(floor(rnd*72.)*6.2831853/3.)*p;
    
    

    // Nearest vertex, vertex-arc and angle (subtended from each vertex) calculations.
    for(int i = 0; i<3; i++){
    
        // Current vertex. By the way, you could change this to a hexagon or
        // dodecahedron metric, and multiply the side length variable, "sL" by
        // "sqrt(3)/2" to produce a straight line pattern.
        float vDist = length(p - v[i]);
        
        // Nearest overall vertex.
        vert = min(vert, vDist); 
        
 
        // One of three arcs that loop around each vertex. This is still
        // circle distance at this point, but the rest of the calculations 
        // are performed outside the loop (see below).
        arc[i] = (vDist - sL*2./3.);
       
        // Angle of each pixel on each arc. As above, further calculations
        // are performed outside the loop for speed.
        vec2 vp = p - v[i];
        ang[i] = atan(vp.y, vp.x);
    }
    

    
    // The concentric line number; It needs to be a factor of three. I've opted
    // for a tightly bound pattern. Using something like "6." will work, but due
    // to the shading setup, changing the global triangle "scale" variable to 
    // something higher will look better.
    const float lNum = 1.*3.; 
    // Side length factor that halves each time the triangle subdivides.
    // Using: "pow(2, a) = exp2(a)" and "exp2(a)/exp2(b) = exp2(a - b)".
    float sL0 = sL*exp2(subSc - float(DIV_NUM)); 
    float lW = sL0/lNum;// Concentric line width.
    vec3 ln = abs(mod(arc + lW/2., lW) - lW/2.) - lW/4.; // Repeat lines.
 
 
     
    // Restricing the concentric line field to the vertex arc size.
    ln = max(arc - lW/4., ln);
    //ln -= lW/4.*.15; // Change the colored line width, if so desired.
  
        


     // RENDERING.
    
    // Background, set to black.
    vec3 col = vec3(0);
    
    // Resolution factor for shadow width -- It's a hack to make sure shadows
    // have the same area influence at different resolutions. If you think it's
    // confusing, you'll get no arguments from me. :)
    float resF = iResolution.y/450.;
    
    // Using the angle (subtented to the arc vertex) to create some faux shading.
    vec3 sh = -cos(ang*6.)*.5 + .5;
    
    // Rendering the three sets of double arcs.
    for(int i = 0; i<3; i++){


        // Concentric line color.
        #if COLOR == 0
        vec3 lnCol = mix(vec3(1, .6, .2), vec3(1, .1, .2), 1./(1. + sh[i]));
        #else
        vec3 lnCol = mix(vec3(.14, .16, .2), vec3(.14, .1, .2), 1./(1. + sh[i]));
        #endif
        
        lnCol *= sh[i]*.35 + .65;
 
        // White concentric line color, which some added shading.
        vec3 lnCol2 = vec3(1)*((sh[i]*sh[i])*.4 + .6);
        
        // Just a hack to lighten the spokes around the vertices.
        // It's not really necessary and not entirely accurate. 
        lnCol2 = blend(lnCol2, lnCol2 + .15, sf*2., vert - lW, 1. - sh[i]);      
   
   
        // Rendering.
        // Very subtle drop shadows, tapered by the shadow factor, which 
        // was a last minute hack to avoid triangle boundary issues. 
        col = blend(col, lnCol2/32.,  sf*6.*resF, arc[i] - lW/4., sqrt(sh[i]));
        
        // Two colored lines and dark edges.
        col = blend(col, lnCol2, sf, arc[i] - lW/4. + .005, 1.); // Colored line.
        //col = blend(col, vec3(0), sf*2.*resF, ln[i], sh); // Line shadows.
        col = blend(col, vec3(0), sf, ln[i], 1.); // Edges.
        col = blend(col, lnCol, sf, ln[i] + .005, 1.); // White lines.   
   

    } 
    
    
    #ifdef GRID
    // Grid boundaries.
    col = blend(col, vec3(0), sf, abs(tr) - .004, 1.);
    col = blend(col, vec3(1, .6, .2)*1.5, sf, abs(tr) - .0005, 1.);
    #endif
    
    
    // Subtle vignette.
    uv = fragCoord/iResolution.xy;
    col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , 1./32.);
    // Colored variation.
    //col = mix(col.zyx, col, pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , 1./8.));

    
    // Rough gamma correction.
    fragColor = vec4(sqrt(max(col, 0.)), 1);
}