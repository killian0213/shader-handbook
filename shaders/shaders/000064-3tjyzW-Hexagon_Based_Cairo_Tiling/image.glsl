// Image (image) — Hexagon Based Cairo Tiling by Shane
// https://www.shadertoy.com/view/3tjyzW

/*

	Hexagon Based Cairo Tiling
	--------------------------
    
    I like the aesthetics of the standard Cairo tiling arrangement, probably 
    because it's about as close to a regular pentagon tiling of the plane as 
    you're going to get. Obviously, it's not a regular pentagon tiling, but it 
    has that kind of feel to it.
    
    There are several ways to produce one, but most prefer to use a square grid,
    then take it from there. I've coded a couple of Cairo pentagon prism 
    traversals in 3D, and although most GPUs can handle the workload, things 
    start slowing down when you add details, so I've been looking for faster 
    ways to produce them.
    
    This method is quick enough, especially for the purpose of a simple bump
    mapped demonstration. However, it's not even close to the faster methods 
    I've used. Either way, I find it easy to implement, since all hexagons are 
    aligned the same way, which makes bookkeeping a little easier. More 
    importantly, it provides a basis for more interesting hexagon subdivisions -- 
    I'll post one of those in due course.
    
    Anyway, this particular implementation has languished in my account for
    years, but I found it the other day, got bored, then started adding some 
    details until I thought it was interesting enough to post. This is just a 
    simple 2D example, but I'll use one of my faster algorithms to create 
    something in 3D at a later date. Actually, I've posted one of those already,
    but I'll use a faster method next time.
    
    

	
    Other Cairo pattern examples:
    
    // A simple implementation of BigWings Youtube tutorial.
    Cairo Tiling 2 -- dosc
    https://www.shadertoy.com/view/DdVGR1
    //
    Based on:
    Live Coding: Cairo Tiling Explained! -- The Art Of Code
    https://www.youtube.com/watch?v=51LwM2R_e_o

    // Fast, and simple. 
    2d-cairo.frag -- jorge2017a1
    https://www.shadertoy.com/view/3t3cDH
    
    // Short and sweet.
    More Cairo Tiles -- mla 
    https://www.shadertoy.com/view/MlSfRd
    

*/

// PI and 2PI.
#define PI 3.14159265
#define TAU 6.2831853


// Greyscale, for that artistic look.
//#define GREYSCALE



// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21(vec2 f){

    // The first line relates to ensuring that icosahedron vertex identification
    // points snap to the exact same position in order to avoid hash inaccuracies.
    uvec2 p = floatBitsToUint(f + 16384.);
    p = 1664525U*(p>>1U^p.yx);
    return float(1103515245U*(p.x^(p.y>>3U)))/float(0xffffffffU);
}

// Commutative smooth maximum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smax(float a, float b, float k){
    
   float f = max(0., 1. - abs(b - a)/k);
   return max(a, b) + k*.25*f*f;
}

// More correct signed line distance. Based on IQ's original, but with
// a sign addition.
float distLineS(vec2 p, vec2 a, vec2 b){ 

    p -= a, b -= a;
    float h = clamp(dot(p, b)/dot(b, b), 0., 1.);
    // JT's GPU determinant-based sign. Not sure if it's faster, or not.
    //float s = determinant(mat2(b, p))<0.? -1. : 1.;
    // Unfortunately, the GPU "sign" function returns zero for certain pixel.
    // which we can't have for this function, so this is the workaround.
    float s = b.x*p.y<b.y*p.x? -1. : 1.;
    return length(p - b*h)*s; 
}

/*
// Signed distance to a line passing through "a" and "b".
float distLineS(vec2 p, vec2 a, vec2 b){

   b -= a; 
   return dot(p - a, vec2(-b.y, b.x)/length(b));
}
*/

// IQ's 2D line formula.
float distLine(vec2 p, vec2 a, vec2 b){ 

    p -= a, b -= a;
    float h = clamp(dot(p, b)/dot(b, b), 0., 1.);
    return length(p - b*h); 
}

// Pointed top hexagon.
const float gSc = 1./2.;
const vec2 s = vec2(1.25, 1.25)*gSc;


// Hexagon vertex and edge IDs. They're useful for neighboring edge comparisons, etc.
// Multiplying them by "s" gives the actual vertex postion.

// Multiplied by 12 to give integer entries only.
const vec2[6] vID = vec2[6](vec2(-6, -2), vec2(-6, 2), vec2(0, 4), 
                      vec2(6, 2), vec2(6, -2), vec2(0, -4));

const vec2[6] eID = vec2[6](vec2(-6, 0), vec2(-3, 3), vec2(3, 3), vec2(6, 0), 
                      vec2(3, -3), vec2(-3, -3));


// Vertices and mid edge points. These will be precalculated at run time.
vec2[6] v, e;

// Hexagonal bound: Not technically a distance function, but it's
// good enough for this example.
float getHex(vec2 p){
    
    float poly = -1e5;
    p = abs(p);
    for(int i = 0; i<3; i++){
    
        float lnI = distLineS(p, v[i], v[i + 1]);
        poly = max(poly, lnI);
    
    }
     
    return poly;
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
    //return dot(q.xy/gSc, q.xy/gSc)<dot(q.zw/gSc, q.zw/gSc)? vec4(q.xy, ip.xy*12.) : vec4(q.zw, ip.zw*12. + 6.);
    return getHex(q.xy)<getHex(q.zw)? vec4(q.xy, ip.xy*12.) : vec4(q.zw, ip.zw*12. + 6.);

}

// Polygon vertices.
vec2[5] pV;
// Polygon coordinates.
vec2 gP;

// Pentagon triangle distance.
float gTri;
// Middle circle ID.
int midCir;

vec4 df(vec2 p){

    // Scale.
    float sc = gSc;
    
    // The vertex and edge IDs are multiplied by 12, so we're factoring that in.
    vec2 sDiv12 = s/12.;
    float ySkew = sDiv12.y*2./3.;

    
    // Precalculate.
    for(int i = 0; i<6; i++){
    
        v[i] = vID[i]*sDiv12;
        //e[i] = eID[i]*sDiv12;
        
        // Tweaking the vertices to give the hexagon a certain shape.
        if(i!=2 && i!=5) v[i].y -= sign(v[i].y)*ySkew;
        else v[i].y += sign(v[i].y)*ySkew;
    }    
    
    
    // Edges.
    for(int i = 0; i<6; i++)  e[i] = mix(v[i], v[(i + 1)%6], .5);
   
    
    
    // Hexagonal grid coordinates.
    vec4 p4 = getGrid(p);

   
     // Rendering the grid boundaries, or just some black hexagons in the center.
    float gHx = getHex(p4.xy);
    
    // Vertices. Only here for debugging purposes.
    //float vert = 1e5;
    
    // Edge width.
    float ew = .01*sc;
 
    // Hexagon border.
    //float poly = -1e5;
    float poly = gHx;
    
    /*
    // Iterate through all six sides of the hexagon cell.
    for(int i = 0; i<6; i++){
    
        //float lnI = distLineS(p4.xy, v[i], v[(i + 1)%6]);
        //poly = max(poly, lnI);
        
        
        // Vertices at the ends of this edge.
        float v1 = length(p4.xy - v[i]);
        // Vertices for this edge.
        vert = min(vert, v1);
     
    }
    */
    
    // Subdividing the main hexagon into four pentagons.
    vec4 lnS;
    float div;
    
    // Two central pivot points.
    float sL = length(e[0] - e[3]);
    vec2 p0 = vec2(-sL/8.*.8660254, 0.);//vec2(-sL/2., 0)*.75;
    vec2 p1 = p0*vec2(-1, 1);
    
    //p0 = rot2(PI/6.*cos(iTime))*p0;
    //p1 = rot2(PI/6.*sin(iTime))*p1;
    
    //vert = min(vert, length(p4.xy - p0));
    //vert = min(vert, length(p4.xy - p1));
    
    // The four mid-point edge positions.
    mat4x2 e4 = mat4x2(e[1], e[2], e[4], e[5]); 
    for(int i = 0; i<4; i++){
       
       vec2 pp = i==0 || i==3? p0 : p1;
       lnS[i] = distLineS(p4.xy, pp, e4[i]);
       
       //vert = min(vert, length(p4.xy - e4[i]));
    }
    
    //vert -= ew*3.;
   
    // The dividing line between to two central pivot points.
    div = distLineS(p4.xy, p0, p1);
    
    // Partitioning into the four sections.
    lnS = max(lnS, -lnS.yzwx);
    lnS.xz = max(lnS.xz, vec2(-div, div));
    
    // Subdivided polygon ID.
    int pID = 0;
    
    
    // Determining which pentagon we're in.
    for(int i = 0; i<4; i++){
       
        float lnI = lnS[i];
        if(lnI<0.){
           poly = max(poly, lnI);
           pID = i;
           break;
        }
    }
    
    // Vertices, based on polygon ID.
    // In order: top, right, bottom, left.
    
    if(pID==0 || pID==2){
        // Top and bottom pentagon vertices.
        pV[0] = e4[pID];
        pV[1] = pID==0? v[2] : v[5];
        pV[2] = e4[(pID + 1)%4];
        if(pID==0){ pV[3] = p1; pV[4] = p0; }
        else { pV[3] = p0; pV[4] = p1; }
    }
    else {
        // Left and right pentagon vertices.
        // 1 or 3.
        pV[0] = e4[pID];
        pV[1] = pID==1? v[3] : v[0];
        pV[2] = pID==1? v[4] : v[1];
        pV[3] = e4[(pID + 1)%4];
        if(pID==1){ pV[4] = p1; }
        else { pV[4] = p0;  }
    }
    
    poly = -1e5;
    //float polyHi = -1e5;
    for(int i = 0; i<5; i++){
        poly = max(poly, distLineS(p4.xy, pV[i], pV[(i + 1)%5]));
        //polyHi = smax(polyHi, distLineS(p4.xy - .001, pV[i], pV[(i + 1)%5]), .0*sc);
    }
    
///////
    // Splitting the resultant pentagon into five triangles. This isn't part of 
    // the Cairo pentagon tiling, but I thought it'd look interesting.
    float tri = 0.;
    
    vec2 cntr = vec2(0);
    for(int i = 0; i<5; i++){
        cntr += pV[i]/5.;
    }
    
    // Giving each pentagon its own coordinate system.
    p4.xy -= cntr;
    for(int i = 0; i<5; i++) pV[i] -= cntr;
    cntr = vec2(0);

    // Spinning wheels.
    midCir = 0;
    int wheel = hash21(p4.zw + float(pID)/4. + .057)<.5? 0 : 1;
    //int wheel = (pID==0 || pID==3)? 0 : 1;
    if(wheel==1){
        
        // Rotation.
        float midLine = length(p4.xy - cntr) - .07;
        if(midLine<0.){
           
           // Animation.
           float dir = hash21(p4.zw + float(pID)/4. + .06)<.5? -1. : 1.;
           
           float t = fract(iTime/8. + hash21(p4.zw + float(pID)/4. + .18));
           t = smoothstep(.4, .6, t)*TAU;
           //for(int i = 0; i<5; i++) pV[i] = cntr + rot2(iTime*dir/2.)*(pV[i] - cntr);
           p4.xy = rot2(t*dir)*p4.xy;
           
           midCir = 1;
           
        }
        
    }
    
    // Triangle partitioning.
    float ln[5];
    for(int i = 0; i<5; i++){ ln[i] = distLineS(p4.xy, cntr, pV[i]); }
    
    
    int tID = 0; // Triangle ID.
    
    // Determining which triangle we're in.
    for(int i = 0; i<5; i++){
         
         float lnI = smax(ln[i], -ln[(i + 1)%5], .008);
         if(lnI<0.){
             tID = i;
             tri = smax(poly, lnI, .008); // Triangle distance.
             break;
         }
    }
    
    // Construct the circle in the middle.
    if(wheel==1){
  
        float midLine = abs(length(p4.xy - cntr) - .07);
        //float midLine = abs(poly + .045);
        tri = smax(tri, -midLine, .008);
    }
    
    // Global triangle distance.
    gTri = tri;


//////



    // Save the local coordinates.
    gP = p4.xy;
     
    return vec4(poly, pID, p4.zw);
}

float bFunc(vec2 p){

    
    float poly = (df(p).x);
    
    float ew = .005;
     
    
    float tri = gTri + ew*3.;
    
    poly += .0025;
    
    return -poly - smoothstep(0., ew*1.5, -tri)*.005;
}

// Standard function-based bump mapping function, with an edge value 
// included for good measure.
vec3 doBumpMap(in vec2 p, in vec3 n, float bumpfactor){
    
    // Sample difference. Usually, you'd have different ones for the gradient
    // and the edges, but we're finding a happy medium to save cycles.
    vec2 e = vec2(.002, 0);
    
    //float f = bFunc(p).x; // Bump function sample.
    float fxL = bFunc(p - e.xy); // Sample in the X-direction.
    float fyL = bFunc(p - e.yx); // Sample in the Y-direction.
    float fxR = bFunc(p + e.xy); // Sample in the X-direction.
    float fyR = bFunc(p + e.yx); // Sample in the Y-direction.
    
    vec3 grad = (vec3(fxL - fxR, fyL - fxR, 0))/e.x/2.;   
     
    // Applying the bump function gradient to the surface normal.
    grad -= n*dot(n, grad);          
    
    // Return the normalized bumped normal.
    return normalize(n + grad*bumpfactor );
	
}


// A very simple random line routine. It was made up on the
// spot, so there would certainly be better ways to do it.
float randLines(vec2 p){
    
    // Scaling.
    float sc = 100.;
    p *= sc;
    
    // Offset the rows for a more random look.
    p.x += hash21(vec2(floor(p.y), 7) + .2)*sc;
    
    // Cell ID and local coordinates.
    vec2 ip = floor(p);
    p -= ip + .5;
    
    // Distance field value and random cell number.
    float d;
    float rnd = hash21(ip + .34);
    
    // Randomly, but not allowing for single dots.
    if(rnd<.333 && mod(ip.x, 2.)==0.){
    
       // Dots on either side of the cell wall mid-points, to create a space.
       d = min(length(p - vec2(-.5, 0)), length(p - vec2(.5, 0)));
        
    }
    else {
        // Otherwise, just render a line that extends beyond the cell wall
        // mid-points.
        d =  abs(distLineS(p, vec2(-1, 0), vec2(1, 0)));
    }
    
    // Applying some width.
    d -= 1./6.;
    
    // Scaling down the distance value to match scaling up
    // the coordinates.
    return d/sc;
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
    mat2 sRot = mat2(1, 0, 0, 1); //rot2(PI/6.); // Scene rotation.
    vec2 camDir = sRot*normalize(s); // Camera movement direction.
    //vec2 ld = sRot*normalize(vec2(1, -1)); // Light direction.
    vec2 p = sRot*uv*sc + camDir*iTime/16.;
    
     
    
///////////////    
    // Unit direction vector. Used for some mock lighting.
    vec3 rd = normalize(vec3(uv, .5));
    
    // Face normal for and XY plane sticking out of the screen.
    vec3 n = vec3(0, 0, -1);
    
    // Bump mapping the normal and obtaining an edge value.
    float bumpFactor = .75;
    n = doBumpMap(p, n, bumpFactor);
   
    // Light postion, sitting back from the plane and animated slightly.
	vec3 lp =  vec3(sin(iTime)*.3, cos(iTime*1.3)*.3, -1) - vec3(uv, 0);
    
    // Liight distance and normalizing.
    float lDist = max(length(lp), .001);
    vec3 ld = lp/lDist;
    // Unidirectional lighting -- Sometimes, it looks nicer.
    //vec3 ld = normalize(vec3(-.3 + sin(iTime)*.3, .5 + cos(iTime*1.3)*.2, -1));
    
    // Light attenuation.
    float atten = 1./(.25 + lDist*lDist*.5);;
	
	// Diffuse, specular and Fresnel.
	float diff = max(dot(n, ld), 0.);
    diff = pow(diff, 4.);
    float spec = pow(max(dot(reflect(-ld, n), -rd), 0.), 16.);
	// Fresnel term. Good for giving a surface a bit of a reflective glow.
    float fre = min(pow(max(1. + dot(rd, n), 0.), 4.), 2.);
    //float fre = min(pow(max(1. - max(dot(-rd, n), 0.), 0.), 4.), 2.);
   
////////////////


    // Polygon information.
    vec4 d4 = df(p);
    // ID, distance and polygon (pentagon) ID.
    vec2 id = d4.zw;
    float poly = d4.x; // Pentagon.
    float pID = d4.y;
    float tri = gTri; // Pentagon triangle.
    

    // Random polygon coloring.
    //vec3 pCol = bg;
    float rnd = hash21(id + float(pID)/4. + float(midCir)*.0 + .3);
    //float rnd2 = hash21(id + float(pID)/4. + .23);
    //vec3 pCol = .5 + .45*cos(TAU*rnd/4. + vec3(3, .5, 1)*2.);
    vec3 pCol = .55 + .45*cos(TAU*rnd/4.5 + vec3(0, 1, 2));
    //vec3 pCol = .55 + .45*cos(TAU*rnd/4. + vec3(0, 1, 2)*(rnd2*.5 + .5));
    //pCol = mix(pCol.xzy, pCol.yzx, smoothstep(.3, .7, uv.y + .5));
    
    // Spinning wheel coloring.
    if(midCir==1){
       pCol /= (.5 + pCol)/1.25;
       //pCol = mix(pCol, vec3(1)*dot(pCol, vec3(.299, .587, .114)), .5);
    }
    
    // Edge width.
    float ew = .005;
     
    // Rendering the polygon and edges.
    vec3 svCol = pCol;
    pCol = mix(vec3(0), pCol*1.0 + .0, 1. - smoothstep(0., sf, tri + ew));
    pCol = mix(pCol, min(pCol, 1.)*.1, (1. - smoothstep(0., sf, tri + ew*3.)));
    pCol = mix(pCol, svCol, (1. - smoothstep(0., sf, tri + ew*4.)));
    
    #ifdef GREYSCALE
    pCol = mix(pCol, vec3(1)*dot(pCol, vec3(.299, .587, .114)), .9);
    #endif
   
    /*
    // A bit of backfill light.
    vec3 fillDir = vec3(-ld.xy, 0.);
    float bl = max(dot(fillDir, n), 0.);
    pCol += pCol*vec3(.05, .2, 1)*bl*bl*8.;
    */
    

    // Adding a random line pattern to the background.
    float pat = randLines(rot2(PI/4.)*gP);
    pCol = mix(pCol*1.2, pCol*.7, 1. - smoothstep(0., sf, max(pat, tri + ew*3.)));

    // Quick Lighting Tech - blackle
    // https://www.shadertoy.com/view/ttGfz1
    // Studio and outdoor.
    //float ambience = pow(length(sin(sn*2.)*.45 + .5), 2.);
    float ambience = length(sin(n*2.)*.5 + .5)/sqrt(3.)*smoothstep(-1., 1., -n.z); 

    
    // Applying the lighting.
    vec3 col = pCol*(diff + ambience + spec*vec3(1, .7, .3)*8. + fre*vec3(.1, .3, 1)*12.);
    

    // Using the distance function value for some faux shading.
    float shade = max(-poly*7. + .05, 0.);
    //pCol *= shade*shade*1.5 + .05;// 
    col *= shade;
    // Faux triangle center AO.
    col = mix(col*1.2, col*.8, 
              1. - smoothstep(0., sf*res/450.*2., abs(tri + ew*5.) - ew/2.));
     
    col *= atten; // Light attenuation.
    
     
    // Vignette.
    uv = fragCoord/iResolution.xy;
    col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , 1./16.);

    // Rough gamma correction.
    fragColor = vec4(pow(max(col, 0.), vec3(1./2.2)), 1);;
}