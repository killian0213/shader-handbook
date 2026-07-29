// Image (image) — Hexagon Grid Spiral Tessellation by Shane
// https://www.shadertoy.com/view/WddGDf

/*

	Hexagon Grid Spiral Tessellation
	--------------------------------
    
    This is a subdivided interlocking triskelion (triple spiral) design, or 
    depending on perspective, a hexagonal grid-based concentric spiral-arm 
    tessellation of the 2D plane.
    
    I made it because I like the aesthetics of the pattern, and I don't feel
    there are enough of these kinds of examples. Curvy spiralesque grid patterns 
    are pretty common in image form on the net, but there aren't a great deal of
    coded examples. There are a few simple ones on Shadertoy, but nowhere near 
    as many as the straight edge counterparts. This is mostly due to the fact 
    that people, myself included, prefer the relative simplicity of working with 
    straight lines.
    
    The edges of this particular pattern were created using a basic Archimedean 
    spiral function. In theory, curved shapes render pretty much the same way as
    straight edge shapes, like polygons. To construct a polygon, you determine
    the minimum 2D distance of all straight edges enclosing it. Constructing a 
    curved shape is exactly the same, except some, or all, bounding edges are 
    curved, so you are required to determine distances to curves.
    
    The only caveat is that you may require the gradient of curves that have
    varying curvature if you wish to render equiwidth lines in a single pass.
    This is the case with spirals, but gradients can be determined using analytic
    or numeric methods. In addition, spirals can be a little confusing to work 
    with, since they involve working with polar coordinates that wrap around 
    themselves.
    
    Anyway, I've roughly explained the process below. The algorithm makes use of
    repeat polar tricks, and so forth, so should be fast enough for 3D use. I'll
    post one of those later.
    

	
    Other Spiral Tessellation Examples:

    // There aren't a lot of spiral tessellations on here, but I remember
    // Fizzer's example. I was pretty happy with this one. It's an equilateral 
    // triangle tiling using sine waves as the tile edges.
    Sine Wave Tiling  -- fizzer 
    https://www.shadertoy.com/view/fdtXRn

    

*/

// PI and 2PI.
#define PI 3.14159265
#define TAU 6.28318530718


// Show the hexagon grid that the pattern is based on. Seeing the
// hexagon borders can give a better idea regarding the structure.
//#define SHOW_GRID

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

/*
// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21(vec2 f){

    // The first line relates to ensuring that icosahedron vertex identification
    // points snap to the exact same position in order to avoid hash inaccuracies.
    uvec2 p = floatBitsToUint(f + 16384.);
    p = 1664525U*(p>>1U^p.yx);
    return float(1103515245U*(p.x^(p.y>>3U)))/float(0xffffffffU);
}
*/

// Dave Hoskins's hash function.
float hash21(vec2 p){

    p = fract(p*vec2(328.523, 456.245));
    p += dot(p, p + 45.327);
    return fract(p.x*p.y);

    /*
    // Dean_the_coder's configuration.
    p = fract(p*vec2(5.3983, 5.4427));
    p += dot(p.yx, p + vec2(21.5351, 14.3137));
	return fract(p.x*p.y*95.4337);
    */
}


/*
// More correct signed line distance. Based on IQ's original, but with
// a sign addition.
float distLineS(vec2 p, vec2 a, vec2 b){ 
  
    //if(a == b) return -1e5;
    p -= a, b -= a;
    float h = clamp(dot(p, b)/dot(b, b), 0., 1.);
    // JT's GPU determinant-based sign. Not sure if it's faster, or not.
    //float s = determinant(mat2(b, p))<0.? -1. : 1.;
    // Unfortunately, the GPU "sign" function returns zero for certain pixel.
    // which we can't have for this function, so this is the workaround.
    float s = b.x*p.y<b.y*p.x? -1. : 1.;
    return length(p - b*h)*s;
     
}
*/


// Signed distance to a line passing through A and B.
float distLineSF(vec2 p, vec2 a, vec2 b){

   //if(a == b) return -1e5;
   b = min(b - a, 1.);
   return dot(p - a, vec2(-b.y, b.x)/length(b));
}




// Hexagon grid scale.
const float gSc = 1./2.4;

// Flat top hexagon, or pointed top.
const vec2 s = vec2(1, 1.732)*gSc/1.;


// Vertices and mid edge points.
vec2[6] v, e;

// Hexagon vertex IDs. They're useful for neighboring edge comparisons, etc.
// Multiplying them by "s" gives the actual vertex postion.
//
// Vertices: Clockwise from the bottom left. -- Basically, the ones 
// above rotated anticlockwise. :)

// Multiplied by 12 to give integer entries only.
const vec2[6] vID = vec2[6](vec2(-6, -2), vec2(-6, 2), vec2(0, 4), 
                      vec2(6, 2), vec2(6, -2), vec2(0, -4));

const vec2[6] eID = vec2[6](vec2(-6, 0), vec2(-3, 3), vec2(3, 3), vec2(6, 0), 
                      vec2(3, -3), vec2(-3, -3));


// Hexagonal bound: Not technically a distance function, but it's
// good enough for this example.
float getHex(vec2 p){
    
    // Flat top and pointed top hexagons.
    return max(dot(abs(p.yx), vec2(1.73205, 1)/2.), abs(p.x));    
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
 
}


vec2 gID; // Global sprial arm ID.
vec2 gID0; // The hexagon ID with sprial arm boundaries.



// Sprial rotation to line things up. No rotation is needed for
// this configuration, but it is required for others.
const float rA = 0.; 

// Angular wrapping value. This one spirals four vertices
// for each center to vertex run. I hardcoded a bunch of
// things, so other values (2./6, etc.) would need a complete
// overhall of the figures... I might generalize it later.
const float aWrap = gSc*4./6.;

// Metallic grey or colored.
int type = 0;


vec2 getShape(vec2 p, float r){

    // Rotate all the spiral elements.
    vec2 q = p;
    q *= rot2(rA);
    
    // Angular spiral component.
    float a = fract(atan(q.y, -q.x)/TAU);
    // Assosiated sextant index.
    int index = int(a*6.)%6;
   
    
    // The radial component of a single spiral: Spirals are nothing more than 
    // polar coordinates (or similar) that have had the radial component 
    // reconfigured slightly. In particular, we add a portion of the angular 
    // component to the length. If you're not familiar with the concept, use 
    // polar coordinates to render some concentric circles, then add a fraction 
    // of the angular component to the length.  
    //
    float l = length(q); // Circular radial component (sans angular adjustment).
    //
    // Rotate this arm to the correct position. 
    vec2 q0 = rot2(-TAU/6.*float(index))*q;
    float a0 = fract(atan(q0.y, -q0.x)/TAU);
    q0.y = l + a0*aWrap; // Spiral radian component.
    
    // Spiral repeat width scale. Designed to produce six spirals.
    float scl = aWrap/6.; 
 
    // Spiral logic can do my head in at times. :) In this case, once
    // we've spiraled past four vertices, we've hit the triangular middle
    // section of the triskelion (located on the hexagon grid vertices).
    int triskelion = q0.y<scl*4.5? 0 : 1;
    
    // The overall distance.
    float d;
    
    float iy; // Spiral arm number.
    
    
    gID0 = gID; // Central hexagon ID.

    
    // If we're not in the central triskelion area, then we're inside
    // one of the spiral arms, so construct those. By the way, for those
    // who are wondering why I haven't used an "if-else" statement, it's
    // an old GPU thing. Sometimes, GPUs will calculate everyting inside
    // the "if" and the "else" statement combined, which is not helpful. :)
    if(triskelion==0){
        
        // Spiral curves are polar coordinates with an angle-based 
        // component. The is a common Archimedean spiral arrangement.
        //float l = length(p.xy);
        q.y = l + a*aWrap;
        // Splitting the single spiral into six repeat spiral arms.
        q.y += scl/2.;
        iy = floor(q.y/scl);
        q.y -= (iy + .5)*scl;

        // Inner and outer curved spiral edges. No different to bounding
        // shapes with arcs or straight lines.
        float d0 = q.y - scl/2.;
        float d1 = q.y + scl/2.;
        d = max(d0, -d1)/r;//(abs(q.y) - scl/2.)/r;

    
    }
    
    ///////
    if(triskelion == 1){
    
       // Cutting out the side arcs of the triskellion. 
       d = -(q0.y - scl*4.5)/r;
       
       // Cutting out the other side arc across the cell boundary... Grid logic
       // can be really confusing. The shape we're rendering spans across the
       // hexagon cell boundary. Therefore, we need to render from the perspective
       // of the neighboring cell... And yes. This took me more than one try to 
       // get the figures right. :)
       vec2 qL = p - e[(index + 1)%6]*2.;
       qL *= rot2(TAU/6.*float(index)); 
       float l2 = length(qL);
       float a2 = fract(atan(qL.y, -qL.x)/TAU);
       qL.y = l2 + a2*aWrap;
       d = max(d, -(qL.y - scl*8.5)/r);
       
         
       // Match the color up to the correct spiral arm.
       iy = float(index + 5);
    }    
    
    
    ///////////
     
    // Partioning the triskelion and rendering vertices.
    q = p.xy - v[(index + 1)%6];
    q *= rot2(atan(1., 3.)/2.);

    if(triskelion==1){
        
         // Partitioning the triskelion with two dividing lines.
         float lnI = distLineSF(q, vec2(0), v[(index + 2)%6]);
         float lnI2 = distLineSF(q, vec2(0), v[(index + 4)%6]);
         float ln = max(lnI, -lnI2);
         
         // If we're inside the partitioning lines, subdivide.
         if(ln<0.) d = max(d, ln);
         else {
            
            // We're outside, or inside the neighbor, so update
            // accordingly.
            
            d = max(d, -ln);
            
            // Set the positional ID to the neighboring polygon.
            gID0 += eID[index]*2.;
            
            // Update the spiral arm ID as well.
            iy = mod(iy + 2., 6.);
            
         }
        
    } 
     
 
    // Give each spiral arm a unique ID.
    //gID = gID0 + vID[int(iy)%6];
    gID = gID0 + vID[int(iy + 2.)%6]/2.;
      
    
      
    /////////////////////////
    // Applying some vertices for decorative purposes.
    vec2 qq = q;
    qq *= rot2(float(index + 1)*PI/3.);
    qq.y = abs(qq.y) - .12*gSc; 
    float vert = length(qq);
    
    // The vertices span the hexagon boundaries, so we need to render
    // them on the other side of the edge... It's one of those annoyances
    // that sometimes occurs when working with repeat grids.
    qq = q;
    qq *= rot2(float(index + 3)*PI/3.);
    qq.y = abs(qq.y) - .12*gSc; 
    vert = min(vert, length(qq));
  
    int index2 = int(a*6.)%6;
    qq = p.xy - rot2(-.4)*v[(index2 + 1)%6]*.75;
    vert = min(vert, length(qq));
       
    qq = q - e[(index + 3)%6]*.48;
    vert = min(vert, length(qq));
  
    d = max(d, -(vert - .015*gSc));
    ////////////////////////////
   
    
    
    // Type: Metal or color.
    type = hash21(gID + .1)<.5? 0 : 1;
    //type = mod(iy, 2.)==1.?  0 : 1;
    //type = iy != mod(floor(iTime*2. + hash21(gID + .32)*6.), 6.)?  0 : 1;
    //type = sin(hash21(gID + .1)*TAU + iTime)<.0? 0 : 1;
     
     // Add some extra detail to the colored spirals.
    if(type==1) d = abs(d + .029*gSc) - .029*gSc;//*(1. + length(p.xy));
    
    // Distance and spiral arm ID. 
    return vec2(d, iy);
 
}


// The pixel gradient of the spiral shapes... There's probably
// a better, possibly analytic way to do this.
float distFDX(vec2 p4){
    
    vec2 eps = vec2(1e-5, 0);
    vec2 q = p4.xy;
    q *= rot2(rA);
    float a = atan(q.y, -q.x)/TAU;
    q.y = length(q) + a*aWrap;
    
    vec2 qx = p4.xy - eps;
    qx *= rot2(rA);
    a = atan(qx.y, -qx.x)/TAU;
    qx.y = length(qx) + a*aWrap;
    
    vec2 qy = p4.xy - eps.yx;
    qy *= rot2(rA);
    a = atan(qy.y, -qy.x)/TAU;
    qy.y = length(qy) + a*aWrap;
    
    return length(vec2(qx.y, qy.y) - q.y)/eps.x;//

}
 


void mainImage(out vec4 fragColor, in vec2 fragCoord){

    
    // Aspect correct screen coordinates.
    float res = iResolution.y;
    vec2 uv = (fragCoord.xy - iResolution.xy*.5)/res;
    
    // Global scale factor.
    const float sc = 1.;
    // Smoothing factor.
    float sf = sc/res;
    
    // Scene rotation, scaling and translation.
    mat2 sRot = rot2(atan(1., 3.)); // Scene rotation.
    vec2 camDir = sRot*normalize(s); // Camera movement direction.
    vec2 ld = sRot*normalize(vec2(1, -1)); // Light direction.
    vec2 p = sRot*uv*sc + camDir*iTime*gSc/4.;
    
    // The vertex and edge IDs are multiplied by 12, so we're factoring that in.
    vec2 sDiv12 = s/12.;
    
    // Precalculate the hexagon cell vertex and mid-edge positions.
    for(int i = 0; i<6; i++){
        v[i] = vID[i]*sDiv12; // Vertices.
        e[i] = eID[i]*sDiv12; // Edges.
    }  
    
  
    // Hexagonal grid coordinates.
    vec4 p4 = getGrid(p);
 
        
    // Rendering the grid boundaries.
    float gHx = getHex(p4.xy);
    
     
    // Edge width.
    float ew = .0035;
   
    // Precalculating the function based pixel gradient to use as a
    // derivative based scaling factor for equiwidth lines. This is necessary
    // for curves with variable curvature... There's probably a better way to
    // do this than brute force numeric methods.
    float r = distFDX(p4.xy);
    //float r = fwidth(q.y)*res*.7; // Way cheaper, but not accurate enough.
      
    // Setting the global position ID to the central hexagon point.
    gID = p4.zw;  
    
    // Obtain a second sample of the shape within the hexagon cell
    // in order to perform some cheap bump mapping.
    vec2 p2B = getShape(p4.xy - ld*.001, r);
    float dHi = p2B.x;
    
    gID = p4.zw; // Resetting the position based ID.
    
    // Obtain the shape within the hexagon cell.
    vec2 p2 = getShape(p4.xy, r);
    float d = p2.x; // Shape distance
    float id = p2.y; // Spiral arm ID.
 
   
 
    // Random shape value.
    float rnd2 = hash21(gID + .12) - .5;
    
    // Coloring.
    vec3 pCol = .5 + .45*cos(TAU*(id + 5.)/6./1. + rnd2*.5 + vec3(0, 1, 2)*1.65);
 
    // Blending the colors from the center of the spiral outwards.
    // Not always, but gradient can add extra visual appeal.
    vec3 pCol2 = .5 + .45*cos(TAU*float(id + 4.)/6./1. + rnd2*.5 + vec3(0, 1, 2)*1.65);
    pCol = mix(pCol2, pCol, smoothstep(.5, .8, length(p4.xy)/gSc*2.));
     
    // Bump highlight calculations.
    float b = max(.5 + (max(dHi, -.008) - max(d, -.008))/.001, 0.);
    
    
   
    //
    if(type==0){
        // Metallic.
        float gr = dot(pCol*.2 + .04, vec3(.299, .587, .114)); // Greyscale.
        pCol = vec3(.9, 1, 1.1)*gr;
        pCol *= .5 + b*b*b*2.5; // Faux diffuse highlighting. 
        
        // Extra metallic sheen.
        //float b2 = max(.5 + (dHi - d)/.001, 0.);
        //pCol *= .75 + vec3(.4, .5, .6)*b2;
    }
    else {
        // Colors.
        // Blinking colors.
        //pCol = mix(pow(pCol, vec3(1.5))*2., pCol, 
        //           1. - smoothstep(.6, .8, sin(TAU*hash21(gID + .4) + iTime)));
        pCol *= .5 + b; // Faux diffuse highlighting. 
    } 
    
   
    // Render the colored spiralesque shapes.
    vec3 col = vec3(.05);
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, d)));
    col = mix(col, pCol, (1. - smoothstep(0., sf, d + ew*1.5)));
      
          
    
    // Distance field-based concentric pattern lines.
    //float lNum = 80.;
    //float pat = (abs(fract(d*lNum - 1./4.) - .5) - .2)/lNum;
    //col = mix(col*1.25, col*.75, 1. - smoothstep(0., sf, pat));
    col *= sin(d*TAU*80.)*.25 + 1.;
    
    
    /////////
    // Subtle spiral shadows -- I put this in as an afterthought.
    // I'm not sold on it yet, but it gives a slight warped surface
    // with dispersed shadow feel.
    float ftr = gSc*1.5;
    //rA = 0.;
    vec2 q = p4.xy*vec2(-1, 1);
 
    q *= rot2(rA);
    float a = atan(q.y, -q.x)/TAU;
    q.y = (length(q)/ftr + a*2.); 
    
    float scl = 1./3.;
    float iy = floor(q.y/scl);
    q.y -= (iy + .5)*scl;    
    
    //float r = getR(q);
    float lns = abs(q.y)/r;// - .006;//  - .01;
     
    float sh = cos(lns*TAU*3.)*.4  + 1.;
    sh *= smoothstep(.1, .5, length(p4.xy)/gSc);
    
    col *= sh*.6 + .6;
    //////////  
    
    
    
    // Seeing the hexagon borders can give a better idea regarding
    // the structure.
    #ifdef SHOW_GRID
    float hx = getHex(p4.xy) - gSc/2.;
    float bord = abs(hx) - ew/2.;
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, bord - ew*1.5)); // Edge, or strke.
    col = mix(col, vec3(1), 1. - smoothstep(0., sf, bord)); // Edge, or strke.
    #endif    
    
    // Vignette.
    uv = fragCoord/iResolution.xy;
    col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , 1./16.);

    // Rough gamma correction.
    fragColor = vec4(sqrt(max(col, 0.)), 1);
}