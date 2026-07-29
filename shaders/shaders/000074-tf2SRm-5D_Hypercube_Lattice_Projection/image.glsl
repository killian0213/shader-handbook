// Image (image) — 5D Hypercube Lattice Projection by Shane
// https://www.shadertoy.com/view/tf2SRm

/*

    5D Hypercube Lattice Projection
    -------------------------------
    
    Slicing a plane through one layer of a rotating 5D hypercube lattice, then 
    projecting the connected points of the visible faces onto the cutting plane to 
    produce an animated rhomboid pattern that is reminiscent of packed polyhedra.
    
    This method can be used to produce an infinitely tiled Penrose configuration,
    which was one of the motivations for writing it. However, my real intention is
    to use it as a basis to code up something much more interesting... Well, that's
    the intention anyway. It remains to be seen whether I can do it or not. :)
    
    By the way, I've mentioned before that like most, the geometry relating to 
    quasicrystals, and so forth, is not my area, so if you see any descriptions 
    that don't ring true, or if you know how to improve things, etc, feel free to 
    let me know.
    
    
    
    Based on the following:
    
    deBruijn -- Mathematical Details - Greg Egan
    https://www.gregegan.net/APPLETS/12/deBruijnNotes.html
    
    Other examples:
    
    // 5D projection. Very nice, and explained well. 
    Cut n'project - knighty
    https://www.shadertoy.com/view/XdtBzH

    // Beautiful example, and it was helpful in correcting a problem I
    // was having when putting my earlier 3D demonstration together.
    2D patterns 2: aperiodic tilings - rrrola 
    https://www.shadertoy.com/view/XccXW8
    
    // People mention the humble 3D lattice projection version in passing all 
    // the time, but never provide examples, which is disappointing, since it's 
    // by far the easiest way to understand the multidimensional construction
    // process. Anyway, you can now find an example on Shadertoy. :)
    Cubic Lattice Plane Projection - Shane
    https://www.shadertoy.com/view/WcXGzS

*/

// Display the window dressing.
#define WINDOWS

// PI.
#define PI 3.14159265

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// Dave Hoskins - 
// Hash without Sine 2 (WebGL 2) 
// https://www.shadertoy.com/view/XdGfRR
float hash41(vec4 f){

    //f.xy = mod(f.xy, GRID_SIZE);
    uvec4 p = floatBitsToUint(f);
    p *= uvec4(1597334673U, 3812015801U, 2798796415U, 1979697957U);
	uint n = (p.x ^ p.y ^ p.z ^ p.w) * 1597334673U;
	return float(n & uint(0x7fffffffU))/float(0x7fffffff);
}

// Commutative smooth maximum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smax(float a, float b, float k){
    
   float f = max(0., 1. - abs(b - a)/k);
   return max(a, b) + k*.25*f*f;
}


// Signed distance to a line passing through "a" and "b".
float distLineS(vec2 p, vec2 a, vec2 b){

   b -= a; 
   return dot(p - a, vec2(-b.y, b.x)/length(b));
}

/*
// More correct signed line distance. Based on IQ's original, but with
// a sign addition.
float distLineS(vec2 p, vec2 a, vec2 b){ 

    p -= a, b -= a;
    float h = clamp(dot(p, b)/dot(b, b), 0., 1.);
    // JT's GPU determinant-based sign. Not sure if it's faster, or not.
    return length(p - b*h)*sign(determinant(mat2(b, p))); 
}
*/

// Global cubic face ID. This simply takes note of the cube face
// that produced the closest projected rhombus.
int faceID;

// Fake vec5 setup. I'm guessing future GPUs will have these built in.
struct vec5{ vec4 a4; float b; };

vec5 vec5C(float c){ return vec5(vec4(c), c); }
vec5 vec5C(float a, float b, float c, float d, float e){ 
    return vec5(vec4(a, b, c, d), e); 
}
vec5 vec5C(int a, int b, int c, int d, int e){ 
    return vec5(vec4(a, b, c, d), float(e)); 
}


// For those who are interested, the standard othonormal cubic pattern, the 4D 
// Annan-Beenker pattern, the centered 5D Penrose, etc, all occur when the tilted plane 
// has a normal that runs through the hypercube diagonal.
//
// With that information, you can do some math to determine the other basis vectors 
// (via Eigenvector calculations), two of which turn out to be the vectors below. They're 
// written in transcendental form because it turns out that the same logic translates to 
// all higher dimensional setups. 
//
// Planes described by hypercube diagonals will yeild higher dimension Eigenvectors that 
// look very similar to the following, and will produce nice patterns. The well known 
// Penrose patterns and the lesser known Amman Beenker patterns can be produced this way.
//
// Two normalized vectors describing a plane with a normal pointing along a hypercube's 
// long diagonal (vec5(1, 1, 1, 1, 1)/sqrt(5)), which is analogous to the 3D vector, 
// vec3(1)/sqrt(3).
vec5 U = vec5(cos(PI/5.*vec4(0, 1, 2, 3))/sqrt(5./2.), cos(PI/5.*4.)/sqrt(5./2.));
vec5 V = vec5(sin(PI/5.*vec4(0, 1, 2, 3))/sqrt(5./2.), sin(PI/5.*4.)/sqrt(5./2.));


// Writing some 5 element vector functions: I hacked these together pretty quickly, 
// so there'd be nicer ways to get the job done, but they work.
//
// The idea was to take advantage of the faster vec4 operations, and so forth. I'm not 
// sure whether it was worth it, or not, but it's done now. :) In theory, it should 
// make the 6th, 7th and 8th dimensional version easier to write, so there's that.

vec5 mul(vec5 v, float s){ return vec5(v.a4*s, v.b*s); }
vec5 mul(vec5 u, vec5 v){ return vec5(u.a4*v.a4, u.b*v.b); }
vec5 add(vec5 u, float s){ return vec5(u.a4 + s, u.b + s); }
vec5 add(vec5 u, vec5 v){ return vec5(u.a4 + v.a4, u.b + v.b); }
//vec5 sub(vec5 u, float s){ return vec5(u.a4 - s, u.b - s); }
vec5 sub(vec5 u, vec5 v){ return vec5(u.a4 - v.a4, u.b - v.b); }

//vec5 div(vec5 v, float s){ return vec5(v.a4/s, v.b/s); }
vec5 floor5(vec5 u){ return vec5(floor(u.a4), floor(u.b)); }
//vec5 round5(vec5 u){ return vec5(round(u.a4), round(u.b)); }

// Dot product, swizzel, normalization.
float dot5(vec5 p, vec5 q) { return dot(p.a4, q.a4) + p.b*q.b; }
vec5 swizzle(vec5 u){ return vec5(vec4(u.a4.yzw, u.b), u.a4.x); }
vec5 norm(vec5 u){ return mul(u, 1./sqrt(dot5(u, u))); }

// I needed a "mat2x5" structure to switch between 2 and 5 dimensional space. 
struct mat2x5{ vec5 a5; vec5 b5; };

// "mat2x5" by 2D vector multiplication.
vec5 mul(mat2x5 m, vec2 p){ return add(mul(m.a5, p.x), mul(m.b5, p.y)); }

// "mat2x5" by 5D vector multiplication.
vec2 mul(mat2x5 m, vec5 v5){ 
     return vec2(dot5(v5, m.a5), dot5(v5, m.b5)); 
}

// "mat2x5" by "mat2x2" multiplication.
mat2x5 mul(mat2x5 m, mat2x2 m2){ 
     
     vec5 u5 = add(mul(m.a5, m2[0].x), mul(m.b5, m2[0].y));
     vec5 v5 = add(mul(m.a5, m2[1].x), mul(m.b5, m2[1].y));
     return mat2x5(u5, v5); 
}

// Global rhombus vertices.
mat4x2 gV;
// Global rhombus ID and local coordinates.
vec5 gID;
vec2 gP;


// Length factor.
float lF; 

float distField(vec2 p){


    // This is an annoying hack to move the plane projection vectors off 
    // of the zero mark... It helps avoid some kind of zero based error... 
    // I need to have a think about it, but this seems to fix it. Tecnically,
    // these should be renormalized, so I'm doing that, but I don't think it 
    // matters too much here.
    U = add(U, 1e-6); U = norm(U);
    V = add(V, 1e-6); V = norm(V);

    // The original unrotated skew matrix. Not really needed, but I'm 
    // using it to ID individual cubes. 
    mat2x5 spaceSkew0 = mat2x5(U, V);
    
    // Adding a touch of cirular canvas movement to break things up.
    p += vec2(cos(iTime/8.), sin(iTime/10.))*2.;
    
       
    // Rotating the projection plane by rotating the vectors describing it. 
    // Rotating normal vectors won't change the length, so renormalizing isn't 
    // necessary. There are probably far more interesting rotation scenarios
    // possible when using quarternions, or whatever, but the following conveys
    // that basic idea.
    U.a4.xy *= rot2(iTime/6.5);
    V.a4.xy *= rot2(iTime/6.5);
    U.a4.yz *= rot2(iTime/7.);
    V.a4.yz *= rot2(iTime/7.);
    U.a4.zw *= rot2(iTime/7.5);
    V.a4.zw *= rot2(iTime/7.5);
     
    // Implementing fake vec5 vectors is painful. :)
    vec2 Uwv = vec2(U.a4.w, U.b); // The last two vec5 slots.
    vec2 Vwv = vec2(V.a4.w, V.b); // The last two vec5 slots.
    Uwv *= rot2(iTime/8.);
    Vwv *= rot2(iTime/8.);
    U.a4.w = Uwv.x; U.b = Uwv.y;
    V.a4.w = Vwv.x; V.b = Vwv.y;
/*    
    U.a4.xz *= rot2(iTime/8.);
    V.a4.xz *= rot2(iTime/8.);
    U.a4.yw *= rot2(iTime/8.5);
    V.a4.yw *= rot2(iTime/8.5); 
*/

    
    // Taking the original 2D coordinates, then moving them into
    // a 2D plane (described by U and V) running through 5D space.
    // 
    mat2x5 spaceSkew = mat2x5(U, V);
  
    vec5 p5 = mul(spaceSkew, p);
     
    // The X-axis othonormal vector. It's used with a swizzled form of itself 
    // to produce the XY, YZ, ZW, XW, XZ, YW, etc., face combinations.
    //
    // As an aside, the number of face combinations for each dimension would be
    // the number of combinations for two elements in a set of N, which would 
    // be the sum from 1 to "N - 1". Therefore a 3D cube would have (1 + 2), or
    // three faces, a 4D cube would have (1 + 2 + 3), or 6 faces, a 5D hypercube
    // would have 10, and so on. This also means that calculations for higher
    // order cubes are slower.
    //
    vec5 nA = vec5C(1., 0., 0., 0., 0.);
    vec5 nB = vec5C(0., 1., 0., 0., 0.);
    
    vec5 id; // ID vector, used for coloring purposes.
    
    float d = 1e5; // The rhomboid distance.
    
    
    // Used to save the closest face projection matrix.
    mat2 svMF;
    vec2 svP;
    
    // Iterate through the 10 hypercube face combinations. You need to do this 
    // to fill in all the gaps... An analogy would be that you couldn't cast a 
    // complete 3D cube shadow onto a wall with just one square cube face.
    for(int j = 0; j<10; j++){
        
        // Hypercube face projection matrix. This thing is too unweildly.
        // It's definitely in need of some rearranging... but it works.
        mat2 mF = transpose(inverse(mat2(mul(spaceSkew, nA), mul(spaceSkew, nB)))); 
         
        // Projecting 5D to 2D, and vice versa... It's more of a conversion
        // than a projection per se... I'll rename it later. :)
        mat2x5 spaceProj = mul(spaceSkew, mF);

        // Casting the 5D point (near the rotated 2D plane) to the face plane 
        // described by two of the five axes, then snapping it to the nearest 
        // vertex on the cubic face. By checking the four square face planes 
        // around it (for coverage reasons), you can choose the closest one, then 
        // cast it back down to the plane. The result will be some kind of 
        // rhomboid.
        
        // Nearest cube face vertex.
        vec2 ip2D = floor(vec2(dot5(p5, nA), dot5(p5, nB)) + .5); 
       
        // Checking the four cube face squares surrounding the nearest cube
        // face vertex. With all the casting and recasting, I can't but help
        // think that there's probably some nice trickery that could cut a
        // lot of the transforms back.
        for(int i = 0; i<4; i++){
        
            
            // The center of the neighboring cube face.
            vec2 ip2DI = ip2D + vec2(i%2, i/2) - .5;
            
            // Casting back to 5D space, in order to cast back down to the plane.
            vec5 ip5 = add(mul(spaceProj, ip2DI), .5);
            ip5 = floor5(ip5);
            // Converting to local 5D face coordinates: This uses some hypercube mapping 
            // trickery (1. - nA - swizzle(nA)) and the fact that "fract(p) = p - floor(p)".
            vec5 n5 = sub(vec5C(1.), add(nA, nB));
            vec5 lP5 = sub(p5, mul(n5, ip5));
            // Converting the local 5D coorindates back down to the plane.
            // By the way, the mat2x5 matrix can switch between the 2 spaces
            // simply by changing the order: 2D = 5D*mat2x5, 5D = ma2x5*2D.
            p = mul(spaceProj, lP5) - ip2DI;
            
          
            // Use the skewed local coordinates to produce a rhomboid. We'll render
            // a perfect rhomboid later using the vertices. However, to find the nearest,
            // you only need perform boundary checks.
            float rhom = max(abs(p.x), abs(p.y)) - .5;
              
            // Check to see if this rhomboid (or skewed square, if you prefer) 
            // is closer than the others, then update if necessary.
            if(rhom<d){
                
                d = rhom; // New minimum distance.
                faceID = j; // Face ID, referring to multiple faces.
                id = add(mul(spaceSkew0, ip2DI), vec5C(.5)); // ID for coloring.
                  
                // Face projection matrix and local face coordinates.
                svMF = mF;
                svP = p;
     
            }

        }
        
        // Swizzle to the next orthonormal face combination. Hypercube visible 
        // faces are analogous to the cube face combinations, XY, YZ, XZ, but
        // there are more of them, namely: XY, YZ, ZW, WX, etc.
        // The following should cover it, but there would be better ways.
        nA = swizzle(nA); 
        nB = swizzle(nB); 
        if(j==4){ nB = vec5C(0., 0., 1., 0., 0.); }
        if(j==8){ nB = vec5C(0., 0., 0., 1., 0.); }
     
    }
    
    ///////////////
    
    float det = determinant(svMF);

    // I wanted absolute pixel perfect rhombuses, so I calculated them the
    // long, old-fashioned way... Probably not the best way though. :)
    svMF = transpose(inverse(svMF));
    // Screen space coordinates.
    mat4x2 vID = svMF*mat4x2(vec2(-.5), vec2(-.5, .5), vec2(.5), vec2(.5, -.5));
 

    // Reverse the vertex order if the determinant of the face projection matrix
    // is less than zero... There's probably an earlier way to detect this.
    if(det<0.) vID = mat4x2(vID[3], vID[2], vID[1], vID[0]); 
   
    svP = svMF*svP;
    d = -1e5;
    // Standard polygon rendering.
    for(int i = 0; i<4; i++){
         // Rendering back in screen space.
        float lnI = distLineS(svP, vID[i], vID[(i + 1)%4]);
        d = max(d, lnI);

    } 
    
    
    /*
    // Suvdividing the quads into triangles. Not right for this
    // example, but I'm leaving it here for later use.
    #if 1
    //if(hash41(id.a4 + float(faceID)/40. + .02)<.5){
    if(faceID>-4){

        // 1, 6, and 7 are in reverse order.
        float divLn = distLineS(svP, vID[1], vID[3]);
        //if(length(vID[0] - vID[2])<length(vID[1] - vID[3])) 
         //divLn = distLineS(svP, vID[0], vID[2]);

        if(divLn<0.){
            d =  max(d, divLn);
            faceID = faceID*2;
        }
        else {
            d = max(d, -divLn);
            faceID = faceID*2 + 1;
        }

    }
    #endif
    */

    // Saving the vertices and local coordinates and ID.
    gV = vID;
    gP = svP;
    gID = id;


   
    // Return the distance.
    return d;
 
}

// Return the distance of ray origin to the line intersection point
// in the direction of the unit direction ray. If the ray falls outside
// the line between points "a" and "b", it won't detect a hit... Not
// all line algorithms work this way. By the way, if anyone knows of a
// faster, more efficient version of this, feel free to let me know.
float lineIntersect(vec2 ro, vec2 rd, vec2 a, vec2 b){

    vec2 v1 = ro - a;
    vec2 v2 = b - a;
    vec2 v3 = vec2(-rd.y, rd.x);

    float dotP = dot(v2, v3);
    if(abs(dotP)<1e-6) return 1e8;

    float t1 = (v2.x*v1.y - v2.y*v1.x)/dotP;
    float t2 = dot(v1, v3)/dotP;

    if(t1 >= 0. && (t2 >= 0. && t2 <= 1.)) return t1;

    return 1e8;
}



void mainImage(out vec4 fragColor, in vec2 fragCoord){

    // Aspect correct screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
    
    // Scaling, smoohthing factor and translation.
    float gSc = 6.;
    float sf = gSc/iResolution.y;
    vec2 p = uv*gSc; 
    
    
    // Window offset.
    float dOffs = distField(p - normalize(vec2(-1))*.05);
    U = vec5(cos(PI/5.*vec4(0, 1, 2, 3))/sqrt(5./2.), cos(PI/5.*4.)/sqrt(5./2.));
    V = vec5(sin(PI/5.*vec4(0, 1, 2, 3))/sqrt(5./2.), sin(PI/5.*4.)/sqrt(5./2.));
  
    // The scence -- Distance (d.x) and 4D ID (d.p).
    float d = distField(p);
    float oD = abs(d) - .035;
    
    // Polygon color, based on the face ID.
    vec3 pCol = .5 + .45*cos(PI*2.*float(faceID)/10./4. + vec3(0, 1, 2)*1.);
    
    //if(faceID>3) pCol = pCol.zyx; // Debug face identification.
    
   
    // Mixing a bit of random color with the face color.
    float rnd = hash41(gID.a4 + gID.b/10. + float(faceID)/40.);
    vec3 rCol = .5 + .45*cos(PI*2.*rnd + vec3(0, 1, 2)*1.);
    pCol = mix(pCol, rCol*rCol*1., .1);
    

   
 
    // Applying the outer rhombus.
    vec3 col = vec3(0);
    //col = mix(col, vec3(0), (1. - smoothstep(0., sf, d)));
    col = mix(col, pCol, (1. - smoothstep(0., sf, d + .025)));
    // Top to bottom screen gradient.
    col = mix(col.zyx, col.yzx, uv.y + .5);    
    
    // Adding the inner details. From this point on, it's all window dressing.
    // You don't need any of it.
  
    
    #ifdef WINDOWS
    
    // Inner color.
    float rnd2 = hash41(gID.a4 + gID.b/10. + float(faceID)/40. + .1);
    d += .05 + .025;
    
    // Window color, I think.
    pCol /= (.33 + dot(pCol, vec3(.299, .587, .114)));
    pCol = mix(pCol, mix(pCol.zxy, pCol.yxz, uv.y + .5), .75);     
    pCol = min(pCol + vec3(1, 1, .0)*.4, 1.);
    
   
    // Window lines.
    float wLn = distLineS(gP, gV[1], gV[3]);
    
    float sh = 1.;
    // Only render lines on one side of a diagonal.
    if(wLn>.0){
       float lns = (abs(fract(wLn*20.) - .5) - .1)/20.;
       lns = max(lns, d + .21);
       lns = smoothstep(0., sf, lns)*.9 + .1;
       sh *= lns;
    }
    
 
    
    // Windows and rivots...
    float stripX = max(distLineS(gP, gV[0], gV[1]), distLineS(gP, gV[2], gV[3]));
    float stripY = max(distLineS(gP, gV[1], gV[2]), distLineS(gP, gV[3], gV[0]));
    
    // Moving all the vertex points inward, in order to render smaller windows.
    // It's a method I used to use when dealing with font bevels in the past.
    // I find it overcomplicated (line intersections feel like overkill), but 
    // I can't think of another way around it. Anyway, it's done now.
    float ew = .08;
    float rivot = 1e5;
    for(int i = 0; i<4; i++){
        
        // Start at the vertex, then edge it out by its edge normal.
        vec2 nI = normalize(gV[(i + 1)%4] - gV[i]).yx*vec2(1, -1);
        vec2 ro = gV[i] + nI*ew;
        vec2 rd = normalize(gV[(i + 1)%4] - gV[i]); // First edge tangent.
        // Next edge vertices, edged out by the edge normal.
        vec2 nIp1 = -normalize(gV[(i + 2)%4] - gV[(i + 1)%4]).yx*vec2(1, -1);
        vec2 a = gV[(i + 1)%4] - nIp1*ew;
        vec2 b = gV[(i + 2)%4] - nIp1*ew;
        // Intersect point.
        float t = lineIntersect(ro, rd, a, b);
        vec2 pnt = ro + t*rd;
        // Rivot distance.
        rivot = min(rivot, length(gP - pnt));
    
    }

    // Render the rivots.
    vec3 svCol = col;
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, rivot - .025)));
    
    // Applying the windows.
    //if(faceID<=4){
    if(rnd2<.4){
    
        d = max(stripX, stripY);
        d += .06 + .1;
        // Inner rhombus.
        col = mix(col, vec3(0), (1. - smoothstep(0., sf, d)));
        col = mix(col, svCol + .1, (1. - smoothstep(0., sf, d + .035)));
        
        // Inner rhombus.
        d += .06;
        col = mix(col, vec3(0), (1. - smoothstep(0., sf, d)));
        col = mix(col, pCol*sh, (1. - smoothstep(0., sf, d + .035)));

    }
    
    // Applying a bit of faux AO... Not great, but close enough.
    col = mix(col, col*.8 + pCol*.01, 1. - smoothstep(0., sf*8.*iResolution.y/450., (oD)));
    
    #endif
    
    // Rough gamma correction.
    fragColor = vec4(sqrt(max(col, 0.)), 1);
}