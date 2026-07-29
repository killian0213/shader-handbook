// Common (common) — Jigsaw by Shane
// https://www.shadertoy.com/view/XdGBDW

// Used for debug purposes, but it does give you a better look at the 
// pattern outline.
//#define FLAT_PATTERN

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// Translational movement.
vec2 moveXY(float t){
    return vec2(1./4., -1./12.)*t;
}

/*
// IQ's smooth minium function. 
float smin(float a, float b , float s){
    
    float h = clamp(.5 + .5*(b-a)/s, 0., 1.);
    return mix(b, a, h) - h*(1. - h)*s;
}


// Smooth maximum, based on IQ's smooth minimum.
float smax(float a, float b, float s){
    
    float h = clamp(.5 + .5*(a-b)/s, 0., 1.);
    return mix(b, a, h) + h*(1. - h)*s;
}
*/

// Commutative smooth maximum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smax(float a, float b, float k){
    
   float f = max(0., 1. - abs(b - a)/k);
   return max(a, b) + k*.25*f*f;
}


// Commutative smooth minimum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smin(float a, float b, float k){

   float f = max(0., 1. - abs(b - a)/k);
   return min(a, b) - k*.25*f*f;
}

// vec2 to float hash.
float hash(vec2 p){
    return fract(sin(dot(p, vec2(41.71, 112.97)))*43758.5453);
}

// vec3 to float hash.
float hash31(vec3 p){
   
    float n = dot(p, vec3(13.163, 157.247, 7.951)); 
    return fract(sin(n)*43758.5453); 
}

// Unique jigsaw piece cell ID.
vec2 cellID;

/*
// Random stepped height field.
float getCellHeight(vec2 id){
    
    float cellHeight = hash(id);
    cellHeight = floor(cellHeight*7.999)/7.;
    return cellHeight*.075;
    
}
*/

// Sinusoidal stepped height field.
float getCellHeight(vec2 p){
    
    #ifdef FLAT_PATTERN
    // Handy for debug purposes.
    return .0375;
    #else
    // Any kind of cheap flowing height field will do. 
    float cellHeight = (dot(sin(p*2.2 - cos(p.yx*1.4)), vec2(.25)) + .5);
    cellHeight = floor(cellHeight*7.999)/7.;
    return cellHeight*.075;
    #endif
}


// It can be annoying trying to follow someone's esoteric code logic, but trust me, the
// idea behind it is pretty simple... even if it took me way too long to realize how simple
// it was. :) Anyway, construct a four sided shape with curved sides (using circles), identify 
// all four neighbors, then add a little circle to the edge of one, and take away a circle 
// from its neighbor.
//
// By the way, the nice straight square version is "much" simpler, but doesn't quite have that 
// jigsaw feel. I wish it did, because I could have saved a lot of small headaches. :)
//
float jigsawPiece(vec2 p, vec2 ip){
    
    // Random ID threshold.
    const float rnd = .5;
    
    // The four border IDs: As an example, take the northern, or upper, border.
    // The currect cell ID is "ip." The upper cell wil have ID "ip + vec2(0, 1)."
    // The unique "border" ID will be the average of the two, which will be
    // "(ip + ip + vec2(0, 1))/2." which is "ip + vec2(0, .5)." This means the 
    // current cell's upper border ID will always match the lower border ID of the
    // cell above.
    //
    // The idea is to use the unique cell border ID to generate the random number.
    // If it is above a certain threshold add, or take, a circle, then -- and this
    // is the bit that confused me -- do the opposite with the opposite border. In
    // pseudo code:
    //
    // if (hash(IDNorth)>thresshold) addCircle();
    // if (hash(IDSouth)<=thresshold) takeCircle();
    //
    // It still confuses me if I think about it too much, but it works. In fact, you
    // could use this process to fit any random shapes together.
    
    
    // Four random border IDs.
    vec4 idJoinNSEW = vec4(hash(ip + vec2(0, .5)), hash(ip + vec2(0, -.5)), 
                           hash(ip + vec2(.5, 0)), hash(ip + vec2(-.5, 0)));
    
    
    const float ew = .015; // Jigsaw edge width.
    const float cw = .14; // Jigsaw connector circle width.
    // Jigsaw circle offset perpendicularly from the border. If you change this,
    // find the "sR" varialbe below, and make adjustments there too.
    vec4 sR = vec4(.07); 

   
    // Unfortunately, the "sign" function returns -1, 1 and 0, but we don't want 
    // zero. :) Hence, the line below. Although, there's probably a more efficient 
    // WebGL specific way to do it.
    //
    //vec4 sNSEW = sign(vec4(idJoinN, idJoinS, idJoinE, idJoinW) - rnd);
    vec4 sNSEW = vec4(idJoinNSEW.x>rnd? 1.: -1., idJoinNSEW.y>rnd? 1.: -1., 
                      idJoinNSEW.z>rnd? 1.: -1., idJoinNSEW.w>rnd? 1.: -1.);

    
    // Used to check alternating tiles in the checkerboard pattern. Tiles are either
    // vertically convex and horizontally concave, or vice versa. By the way, I proabably
    // could have gone with quarter rotation (p = p.yx) logic, but I was allowing for
    // assymetrical varations at the time.
    //
    float checkerPat = (mod(ip.x + ip.y, 2.)<.5)? 1. : -1.;
    // Used to reorient tiles, depending on the checkerboard setup.
    vec2 e = checkerPat>0.? vec2(1, 0) : vec2(0, 1); 
    
    // Main tile slab construction.
    // The large circle is used to add curvature to the square sides to give even 
    // more of a jigsaw pattern feel.
    vec2 lROffs = vec2(2); // Large circle offset away from the center.

    // Large circle radius. Equal to the distance from the translated central circle
    // point to the corner of the border in question. This is a northern border
    // calculation.
    //float lRConvex = length(vec2(.5, .5) -  vec2(0, -r2.y));
    //float lRConcave = length(vec2(.5, .5) -  vec2(0, 1. + r2.y));
    float lR = length(vec2(.5, .5) -  vec2(0, -lROffs.y));
    
    // Move the point perpendicularly away from the border, then construct a large
    // circle equal in radius from the new central point to the corner of the square
    // side. In this case, due to symmetry, all circles will have the same radius.
    //
    // I left the following lines so you could see the logic behind the construction.
    // Obviously, I went with shorter "abs" version.
    //float c2N = length(p + lROffs.y*e.yx) - lR + ew/2.;
    //float c2S = length(p - lROffs.y*e.yx) - lR + ew/2.;
    //float c2E = length(p + (1. + lROffs.x)*e.xy) - lR - ew/2.;
    //float c2W = length(p - (1. + lROffs.x)*e.xy) - lR - ew/2.;
    //float d = max(c2N, c2S);
    //d = smax(d, -min(c2E, c2W), .05);

    // Equivalent to the lines above, just less work for the GPU.
    float c2NS = length(abs(p) + lROffs.y*e.yx) - lR + ew/2.;
    float c2EW = length(abs(p) - (1. + lROffs.x)*e.xy) - lR - ew/2.;
    float d = smax(c2NS, -c2EW, .05);
    
    
    
    // Damn logic. If you switch the points based on checker pattern convexity, you have
    // to rotate the unique border IDs with them. So obvious, but this mistake cost me more time 
    // than I care to admit. Oh, and why I'm at it, I put this line below the unique rotation
    // block, so those went haywire too. :)
    idJoinNSEW = checkerPat<0.? idJoinNSEW.zwxy : idJoinNSEW; 
    sNSEW = checkerPat<0.? sNSEW.zwxy : sNSEW; 
    sR = checkerPat>0.? sR.zwxy : sR; 
    

    // I wanted to edge out the connector circles 
    if(idJoinNSEW.x<=rnd) sR.x = .1;
    if(idJoinNSEW.y>rnd) sR.y = .1;
    if(idJoinNSEW.z>rnd) sR.z = .1;
    if(idJoinNSEW.w<=rnd) sR.w = .1;    

    
    // With straight edges, you can simply translate the jigsaw connecter bits along the X and Y borders.
    // However, with curved edges, they need to follow the curves subtented from the main cirecles pivotal
    // point - Don't worry, I groaned about it too. :D 
    
    // Clamped to stop the circles from overlapping the edges.
    vec4 rAng = clamp((idJoinNSEW - .5), - .35, .35)*3.14159/20.; 
    mat2 rotN = rot2(rAng.x);
    mat2 rotS = rot2(rAng.y);
    mat2 rotE = rot2(rAng.z);
    mat2 rotW = rot2(rAng.w);


    const float sf = .05; // Smoothing factor. The effect is subtle, but rounds the pieces a little.
    
    // The connector circles run along the out curved edges of the jigsaw pieces. They're rotionally 
    // offset by a unique amount (based on unique border ID).
    float cN = length(rotN*(p + lROffs.y*e.yx) - (lR - ew - .0 - sNSEW.x*sR.x)*e.yx) - cw;
    float cS = length(rotS*(p - lROffs.y*e.yx) + (lR - ew - .0 + sNSEW.y*sR.y)*e.yx) - cw;
    float cE = length(rotE*(p -  (1. + lROffs.x)*e.xy) + (lR - ew - .0 + sNSEW.z*sR.z)*e.xy) - cw;
    float cW = length(rotW*(p +  (1. + lROffs.x)*e.xy) - (lR - ew - .0 - sNSEW.w*sR.w)*e.xy) - cw;

    
    // As explained above, test the unique random border number against a threshold
    // and either smoothly add or take away the connector circles. Make sure to do the exact
    // opposite with the border directly opposite.
    d = (idJoinNSEW.x>rnd)? smax(d, -(cN - ew), sf) : smin(d, cN, sf);
    d = (idJoinNSEW.y<=rnd)? smax(d, -(cS - ew), sf) : smin(d, cS, sf);
    d = (idJoinNSEW.z>rnd)? smax(d, -(cE - ew), sf) : smin(d, cE, sf);
    d = (idJoinNSEW.w<=rnd)? smax(d, -(cW - ew), sf) : smin(d, cW, sf);
    

    // Return the 2D distance field value.
    return d;
    
}



// "jigDist" contains four 2D jigsaw values, so we find the height for each 
// of the pieces and return the minimum 3D and 2D distance. By the way, I 
// left it in 2x2 loop form for informative purposes. I could easily have
// unrolled it.
//
vec2 jigsaw(vec3 p3, vec4 jigDist){
    
    const float jSc = 4.; // I had to tweak the scale to get things right.
    vec2 p = p3.xy*jSc;    
    const vec2 sc = vec2(2, 2);
    
    // The 3D and 2D distance values.
    float d = 1e5, d2 = 1e5;

    // The height of each object.
    float cellHeight = 0.;
    
    // Iterating through four repeat grids of objects - each spaced out to skip the
    // object in between. This way the individual grid objects will easily fit in
    // their cells.
    // 
    // G1 G2 G1 G2 G1 G2
    // G3 G4 G3 G4 G3 G4
    // G1 G2 G1 G2 G1 G2
    // G3 G4 G3 G4 G3 G4 // Etc.
    //
    for(int j = 0; j<=1; j++){
        for(int i = 0; i<=1; i++){
        

            vec2 ip = floor((p - vec2(i, j))/sc)*sc;
     
            // The main calculation. Normally expensive, but it's been precalculated
            // so is just being read out.
            //float c = jigDist[j*2 + i]; 
            //float c = jigsawPiece(mod(p + vec2(i, j), sc) - sc/2., ip + vec2(i, j));
            
            // Swizzling to avoid the switch statement generated by "dynamic vector indexing".
            // The following two lines are equivalent to the indexed line above.
            // Thanks to Cyberjax for this suggestion. It helps the compiler out a bit.
            float c = jigDist.x;
            jigDist.xyzw = jigDist.yzwx;

            // Record the minimum object's cell ID.
            if(c<d2) {
                cellID = ip + vec2(i, j);
            }
            
            // Minimum 2D field value.
            d2 = min(d2, c);
            
            // The height of the object.
            cellHeight = getCellHeight(ip + vec2(i, j));

            // Minimum 3D field value.
            d = min(d, smax(c/jSc, abs(p3.z - cellHeight - .0) - .5, .0115));
            


        }
    }
    
    // Return the 3D and 2D field values.
    return vec2(d, d2);
    
}

// The 2D jigsaw pattern value. Called via "Buf A" once per frame. See the function above
// for an explanation. By the way, if you're only interested in a 2D jigsaw value, this
// function will suffice.
vec4 jigsaw4(vec3 p3){
    
    const float jSc = 4.;
    vec2 p = p3.xy*jSc; // I had to tweak the scale to get things right.
    const vec2 sc = vec2(2, 2);
    
    vec4 d4 = vec4(0);
    
    for(int j = 0; j<=1; j++){
        for(int i = 0; i<=1; i++){

            vec2 ip = floor((p - vec2(i, j))/sc)*sc;
            vec2 q = mod(p + vec2(i, j), sc) - sc/2.;

            float c = jigsawPiece(q, ip + vec2(i, j));
            

            // Swizzling to avoid the switch statement generated by "dynamic vector indexing".
            // Thanks to Cyberjax for this suggestion. It helps the compiler out a bit.
            //d4[j*2 + i] = c;
            d4.x = c;
            d4.xyzw = d4.yzwx;

        }
    }
    
    // Return the four 2D texture values. We'll use them later -- in the raymarching 
    // equation -- to determine the minimum 3D extruded block field value.
    return d4;
    
}

