// Image (image) — Triangle Grid Spiral Weave by Shane
// https://www.shadertoy.com/view/7syfWz

/*

    Triangle Grid Spiral Weave
    --------------------------
    
    Utilizing a 2D simplex grid to produce an animated interlinked three 
    pronged spiral pattern. I guess another way to put it would be 
    unwrapping a well known icosahedral weave pattern and placing it on a 
    2D plane. :)
    
    I love perusing images of various mathematical objects online. Among
    my favorites are polyhedral weaves. Anyone who's done this will know
    that descriptions of the construction process are hard to come by, so 
    I'm always left trying to figure it out on my own. Thankfully, I enjoy 
    that kind of thing. Icosahedral based weaves are easier to decipher, 
    since they consist of equilateral spherical triangles, which means you 
    can usually map them to a 2D equilateral triangle grid.
    
    With the aforementioned in mind, the purpose of this particular example 
    was to work within the confines of a simple 2D simplex space in 
    preparation for conversion to a 3D icosahedral setting. Rightly or
    wrongly, I made the decision not to use Bezier curves, since it'd make 
    3D conversion at an acceptable frame rate very difficult.
    
    Constructing the spiral objects in each cell using basic distance field
    shapes -- like circles and triangles -- involved more trial and error 
    than I had hoped, but it turned out to be a relatively simple process 
    in the end.
    
    I wasn't going to post a 2D version, but after putting this together, I 
    got bored and added highlights and a few other things until it looked 
    presentable. I'll post the icosaheral version next... unless I get 
    sidetracked with some interesting Shadertoy post. :)
    
    
    
    Other examples:
    
    // A relatively simple 3D weave, and one of the many really 
    // nice Shadertoy examples that slipped under the radar.
    Moorish Rose - athibaul
    https://www.shadertoy.com/view/tdVfDz

    // I made a much simpler interlocked 2D hexagonal pattern a while ago.
    Hexagonal Interlacing - Shane
    https://www.shadertoy.com/view/llfcWs


*/

// Inner object color - Orange: 0, Green: 1.
#define COLOR 0

// Variable width edges.
//#define VARIABLE_WIDTH


// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.619, 57.583)))*43758.5453); }


// Commutative smooth minimum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
vec2 smin(vec2 a, vec2 b, float k){

   vec2 f = max(vec2(0), 1. - abs(b - a)/k);
   return min(a, b) - k*.25*f*f;
}

/*
// Commutative smooth maximum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
vec2 smax(vec2 a, vec2 b, float k){
    
   vec2 f = max(vec2(0), 1. - abs(b - a)/k);
   return max(a, b) + k*.25*f*f;
}
*/


////////
// A 2D triangle partitioning. I've dropped in an old routine here.
// It works fine, but could do with some fine tuning. By the way, this
// will partition all repeat grid triangles, not just equilateral ones.

// Skewing coordinates. "s" contains the X and Y skew factors.
vec2 skewXY(vec2 p, vec2 s){ return mat2(1, -s.yx, 1)*p; }

// Unskewing coordinates. "s" contains the X and Y skew factors.
vec2 unskewXY(vec2 p, vec2 s){ return inverse(mat2(1, -s.yx, 1))*p; }

// Triangle scale: Smaller numbers mean smaller triangles, oddly enough. :)
float scale = 1./3.;

float gTri;

vec4 getTriVerts(vec2 p, inout vec2[3] vID, inout vec2[3] v){

    // Rectangle scale.
    vec2 rect = (vec2(1./.8660254, 1))*scale;
    // Skewing half way along X, and not skewing in the Y direction.
    vec2 sk = vec2(rect.x*.5, 0)/scale; // 12 x .2

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
    
 
    // Vertex IDs for each partitioned triangle.
    if(gTri<0.){
        vID = vec2[3](vec2(-.5, .5), vec2(.5, -.5), vec2(.5));
    }
    else {
        vID = vec2[3](vec2(.5, -.5), vec2(-.5, .5), vec2(-.5));
    }
    
    // Triangle vertex points.
    for(int i = 0; i<3; i++) v[i] = unskewXY(vID[i]*rect, sk); // Unskew.
    
    // Centering at the zero point.
    vec2 ctr = v[2]/3.; // Equilateral equivalent to: (v[0] + v[1] + v[2])/3.;
    p -= ctr;
    v[0] -= ctr;
    v[1] -= ctr;
    v[2] -= ctr;
    
    // Specific centered triangle ID.
    ctr = vID[2]/3.; //(vID[0] + vID[1] + vID[2])/3.;//vID[2]/2.;
    id += ctr;
    // Not used here, but for jigsaw pattern creation, etc, the vertex IDs
    // need to be correctly centered too.
    //vID[0] -= ctr; vID[1] -= ctr; vID[2] -= ctr; 


    // Triangle local coordinates (centered at the zero point) and 
    // the central position point (which acts as a unique identifier).
    return vec4(p, id);
}

// IQ;s signed distance to an equilateral triangle.
// https://www.shadertoy.com/view/Xl2yDW
float sdEqTri(in vec2 p, in float r){

    const float k = sqrt(3.0);
    p.x = abs(p.x) - r;
    p.y = p.y + r/k;
    if(p.x + k*p.y>0.) p = vec2(p.x - k*p.y, -k*p.x - p.y)/2.;
    p.x -= clamp(p.x, -2.*r, 0.);
    return -length(p)*sign(p.y);
}

float dist(vec2 p){
    
    return length(p);
    
    //p = abs(p);
    //return max(p.y*.8660254 + p.x*.5, p.x);

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


// Signed distance to a line passing through A and B.
float distLineS(vec2 p, vec2 a, vec2 b){

   b -= a; 
   return dot(p - a, vec2(-b.y, b.x)/length(b));
}

 

// Angle between 3D vectors. Similar to the 2D version. It's easy to derive
// this yourself, or look it up on the internet.
float angle(vec2 p0, vec2 p1){

    return acos(dot(p0, p1)/(length(p0)*length(p1)));
}
 

void mainImage(out vec4 fragColor, in vec2 fragCoord){


    // Aspect correct screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
    
    // Global scaling and translation.
    float gSc = 1.;
    // Smoothing factor, based on global scaling.
    float sf = 1./iResolution.y*gSc;
    // Depending on perspective; Moving the oject toward the bottom left, 
    // or the camera in the north easterly (top right) direction. 
    vec2 p = rot2(3.14159/12.)*uv*gSc - vec2(-1, -.57735*0.)*iTime/50.;
    
 
    // Global coordinate copy.
    vec2 oP = p;
    
    // Light direction.
    vec2 ld = normalize(vec2(-1, -1.5));


    // Cell coordinate, ID and triangle orientation id.
    // Cell vertices and vertex ID.
    vec2[3] v, vID;
    
    // Returns the local coordinates (centered on zero), cellID, the 
    // triangle vertex ID and relative coordinates.
    scale = 1./3.;
    vec4 p4 = getTriVerts(oP, vID, v);
    p = p4.xy;
    vec2 triID = p4.zw; 
    
    // Background cell triangle and highlight triangle sample.
    vec2 qt = p*vec2(1, gTri);
    float tr = (max(abs(qt.x)*.8660254 + qt.y*.5, -qt.y));
    qt = (p - ld*.005)*vec2(1, gTri);
    float trHi = (max(abs(qt.x)*.8660254 + qt.y*.5, -qt.y));
     

    
    // Vertices and corresponding highlight.
    float vert = 1e5, vertHi = 1e5;
    vec2[3] mid, midA, midB;
    float sL = length(v[0] - v[1]);
    // Larger numbers push the points toward edges, but bring the rings closer.
    float offs = 1./(8. + sin(iTime/3.)*4.); 
    
    // Spiral thickness factor.
    float th = 0.; 
    
    // Triangle center: Trivial here.
    vec2 cntr = vec2(0); //(v[0] + v[1] + v[2])/3.;
 
    
    // Nearest vertex, and edge mid-points and offsets on either side.
    for(int i = 0; i<3; i++){
        
        int ip1 = (i + 1)%3;
        
        // Nearest vertex point.
        vert = min(vert, length(p - v[i]));
        vertHi = min(vertHi, length(p - ld*.005 - v[i]));
        
        // Mid edge point, and complimentary offsets.
        mid[i] = mix(v[i], v[ip1], .5);
        midA[i] = mix(v[i], v[ip1], .5 - offs);
        midB[i] = mix(v[i], v[ip1], .5 + offs);

    }  
    
    
    // The two cell objects (top and bottom). Each consist of curved 
    // spiral arms attached to a central shape.
    vec2 obj = vec2(1e5); 
    vec2 objHi = vec2(1e5); 
    
    // Creating three spiral arms. How you do that is up to you. I've
    // rendered three arcs centered on the triangle center and cutting
    // offset mid-points on each edge. I could have taken a faster
    // polar approach, but was using the process for nonsymmetrical 
    // examples... I won't bore you with the details, suffice to say 
    // that this is not a processor intensive example anyway and I'll 
    // make the conversion later.
    //
    for(int i = 0; i<3; i++){
        
        int ip2 = (i + 2)%3;
        
        // The origin and radius of the circle that will become the
        // spiral arc for this edge. It's centered just off the midway
        // point, and its radius is the distance from the triangle cell
        // center to a point on the other side.
        vec2 o = midB[i];
        float r = length(midA[0]);
        
        // The bottom arcs.
        vec2 q = p;
        float ring = abs(dist(q - o) - r); // Arc, or ring.
        // Cutting the arc in half by restricting it to one third of the triangle.
        // By the way, there are only three partitions needed per sample, and I'm 
        // calculating six all up, which is wasteful and lazy, but not too costly.
        // Either way, I'll fix it up later.
        ring = max(ring, max(distLineS(q, cntr, mid[i]), 
                             distLineS(q, mid[ip2], cntr))); // 
        obj.x = min(obj.x, ring); // Bottom spiral arm object.
        
        // For the top spirals, we reflect across the X-axis -- You can 
        // see this visually. Practically speaking, it means flipping the
        // X-coordinate and using the same functions again.
        q *= vec2(-1, 1);
        ring = abs(dist(q - o) - r);
        ring = max(ring, max(distLineS(q, cntr, mid[i]),  
                              distLineS(q, mid[ip2], cntr)));
        obj.y = min(obj.y, ring); // Top spiral arm object.
 
        // Highlighting sample calculations. Doing the same as above, but 
        //at a slightly offset position in the direction of the light.
        q = p - ld*.005;
        ring = abs(dist(q - o) - r);
        ring = max(ring, max(distLineS(q, cntr, mid[i]),  
                             distLineS(q, mid[ip2], cntr)));
        objHi.x = min(objHi.x, ring);
 
        q *= vec2(-1, 1); 
        ring = abs(dist(q - o) - r); 
        ring = max(ring, max(distLineS(q, cntr, mid[i]),  
                             distLineS(q, mid[ip2], cntr)));
        objHi.y = min(objHi.y, ring);
        
      
    }
    
    // Roughly turning the central triangle to coincide with the changing spiral
    // arm rotation. It's a hack due to the fact that we're not using Bezier curves, 
    // but it's close enough.
    float angR = -3.14159/10. + angle(midA[0] - cntr, (v[2] - v[1]));//-3.14159/15.
    // Central triangle, and its offset sample.
    vec2 trR = rot2(-angR)*p*vec2(1, gTri);
    vec2 trRRef = rot2(-angR)*(p*vec2(-1, 1))*vec2(1, gTri);
    vec2 trM = vec2(sdEqTri(trR, sL/6.), sdEqTri(trRRef, sL/6.));
    trR = rot2(-angR)*(p - ld*.005)*vec2(1, gTri);
    trRRef = rot2(-angR)*((p - ld*.005)*vec2(-1, 1))*vec2(1, gTri);
    vec2 trM2 = vec2(sdEqTri(trR, sL/6.), sdEqTri(trRRef, sL/6.));

    // Adding a bit of thickness. Where you apply this depends on the look you're
    // after. A lot of it is trial and error.
    obj -= sL/12.;
    objHi -= sL/12.;
    
    // Smoothly blending the spiral arms with a central shape. It's not mandatory,
    // but it adds visual interest.
    //
    // Triangles.
    obj = smin(obj, trM - sL/16., .03);//*max(1. - length(p)/sL, 0.)
    objHi = smin(objHi, trM2 - sL/16., .03);//*max(1. - length(p)/sL, 0.)
    // Circles: Cheap, but not as neat. 
    //obj = smin(obj, vec2(length(p) - sL/7.), .06);
    //objHi = smin(objHi, vec2(length(p - ld*.005) - sL/7.), .06);
  

     // Applying extra thickness here put the emphasis on the triangle.
     obj -= sL/24.;//*max(1. - length(p)/sL*1.4, 0.);
     objHi -= sL/24.;//*max(1. - length(p - ld*.005)/sL*1.4, 0.);

 
  
    /*
    // Degug. Untangling the weave.
    if(gTri<0.){ 
        float tmp = ln.x; ln.x = ln.y; ln.y = tmp;
        tmp = lnHi.x; lnHi.x = lnHi.y; lnHi.y = tmp;
    }
    */
    
    // Directional gradient values for hightlighting.
    
    // Pinwheel objects.
    vec2 b = max(objHi - obj, 0.)/.005;
    b = pow(b, vec2(4))*2.5;
    //
    // Vertex rivot objects.
    float bVert = max(vertHi - vert, 0.)/.005;
    bVert = pow(bVert, 4.)*2.5;
    //
    // Background triangles.
    float bTr = max(trHi - tr, 0.)/.005;
    //bTr = pow(bTr, 4.)*2.5;
    
    // Background line pattern.
    const float lNum = 96.;
    float lnD = (rot2(6.2831/3.)*oP).x;
    float tLns = smoothstep(0., sf, (abs(fract(lnD*lNum - .333) - .5)*2. - .333)/lNum/2.);
   
    
    // Background color.
    vec3 bCol = vec3(.125);
    // Outer object color.
    vec3 oCol = vec3(.1); // Outer rim.
    // Inner object color
    #if COLOR == 0
    vec3 oCol2 = vec3(3, .6, .1);  // Orange.
    #else
    vec3 oCol2 = vec3(.2, 1.2, .5); // Green.
    #endif
    // Mixing the colors a little.
    //oCol2 = mix(oCol2, oCol2.xzy, length(p)/length(midA[0])/4.);
    oCol2 = mix(oCol2, oCol2.xzy, dot(sin(uv*3. - cos(uv.yx*6.)), vec2(.1)) + .2);
    
      // Bump color.
    vec3 bumpCol = vec3(.92, .97, 1);
  
    // Apply lines to the colors.
    oCol2 *= tLns*.5 + .5;
    bCol *= tLns*.5 + .5;
    
    // Initiating the scene to the bump mapped triangle grid background.
    vec3 col = bCol + bumpCol*bTr*.3;
    
   

    // Rendering some triangles onto the background, but leaving the edges.
    col = blend(col, col*2., sf*2., abs(tr - scale/3.) - .004, 1.);
    col = blend(col, vec3(0), sf, abs(tr - scale/3.) - .002, 1.);
    
   
    
    // Resolution factor for shadow width -- It's a hack to make sure shadows
    // have the same area influence at different resolutions. If you think it's
    // confusing, you'll get no arguments from me. :)
    float resF = iResolution.y/450.;
    
    // Triangle grid vertices.
    vert -= .035; // Vertex radius.
    vertHi -= .035;
    col = blend(col, vec3(0), sf*8.*resF, vertHi, .5); // Drop shadow.
    col = blend(col, vec3(0), sf, vert, 1.);  // Dark edge.
    col = blend(col, oCol + bumpCol*bVert*.3, sf, vert + .005, 1.); // Outer.
    col = blend(col, vec3(0), sf, vert + .018, 1.); // Inner dark edge.
    col = blend(col, oCol*.7 + bumpCol*bVert*.2, sf, vert + .018 + .005, 1.); // Inner.
    col = blend(col, col*1.5, sf*1., abs( vert + .018 + .005 - .007) - .002, 1.); // Highlight.

    
    // The object layers: Shadows, edges, highlights, etc. Start on the outside,
    // then work inwards adding layers (using the "blend" function) as you go.
    //
    // Edge thickness factor.
    
    #ifdef VARIABLE_WIDTH
    th = sL/(9.5 + (sin(iTime/4.)*.5 + .5)*10.5); // Variable width edges. 
    #else
    th = sL/12.; // Constant width.
    #endif

    // Lower spiral arms.
    vec3 svCol = col; // For transparency.
    col = blend(col, vec3(0), sf*12.*resF, objHi.x, .5); // Drop shadow.
    col = blend(col, vec3(0), sf, obj.x, 1.); // Dark outer edge.
    col = blend(col, mix(oCol + bumpCol*b.x*.3, svCol, .15), sf, obj.x + .005, 1.); // Outer color.
    col = blend(col, vec3(0), sf, obj.x + th, 1.); // Dark inner edge.
    col = blend(col, mix(oCol2 + bumpCol*b.x*.3, svCol, .25), sf, obj.x + th + .005, 1.); // Inner.
    col = blend(col, col*1.5, sf*1., abs(obj.x + th - .005) - .002, 1.); // Highlight.
   
    // The upper spiral arms.
    svCol = col;
    col = blend(col, vec3(0), sf*12.*resF, objHi.y, .5);
    col = blend(col, vec3(0), sf, obj.y, 1.);
    col = blend(col, mix(oCol + bumpCol*b.y*.3, svCol, .15), sf, obj.y + .005, 1.);
    col = blend(col, vec3(0), sf, obj.y + th, 1.);
    col = blend(col, mix(oCol2 + bumpCol*b.y*.3, svCol, .25), sf, obj.y + th + .005, 1.);
    col = blend(col, col*1.5, sf*1., abs(obj.y + th - .005) - .002, 1.);
    
    
 
    // Subtle vignette.
    uv = fragCoord/iResolution.xy;
    col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , 1./16.);
    // Colored variation.
    //col = mix(col.zyx, col, pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , 1./16.));

    
    // Rough gamma correction.
    fragColor = vec4(sqrt(max(col, 0.)), 1);
}