// Common (common) — Pentagon Line Animation by Shane
// https://www.shadertoy.com/view/tXBGD3

#define TAU 6.2831853

float tm;

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

    // Polar angle wrapping. See the bump map function.
    f.y = mod(f.y, 5.);
    
    // The first line relates to ensuring that icosahedron vertex identification
    // points snap to the exact same position in order to avoid hash inaccuracies.
    uvec2 p = floatBitsToUint(f + 16384.);
    p = 1664525U*(p>>1U^p.yx);
    return float(1103515245U*(p.x^(p.y>>3U)))/float(0xffffffffU);
}

// IQ's "uint" based uvec3 to float hash.
float hash31(vec3 f){

    //f.xy = mod(f.xy, GRID_SIZE);
    uvec3 p = floatBitsToUint(f);
    p = 1103515245U*((p >> 2U)^(p.yzx>>1U)^p.zxy);
    uint h32 = 1103515245U*(((p.x)^(p.y>>3U))^(p.z>>6U));

    uint n = h32^(h32 >> 16);
    return float(n & uint(0x7fffffffU))/float(0x7fffffff);
}


// Subdivided rectangle grid.
vec4 getGrid(vec2 p, inout vec2 sc){
    
    // Block offsets.
    vec2 ipOffs = vec2(0);
    // Row or column offset. Values like "1/3" would offset more
    // haphazardly, but I wanted to maintain a little symmetry.
    const float offDst = .5; 
    if(mod(floor(p.y/sc.y), 2.)<.5){
        p.x -= sc.x*offDst; // Row offset.
        ipOffs.x += offDst;
    }
    //if(mod(floor(p.x/sc.x), 2.)<.5){
        //p.y -= sc.y*offDst; // Column offset.
        //ipOffs.y += offDst;
    //}
    
    vec2 oP = p;
    
    // Block ID.
    vec2 ip;
    
    //#define EQUAL_SIDES
    
    // Subdivide.
    for(int i = 0; i<3; i++){
        
        // Current block ID.
        ip = floor(p/sc) + .5;
        float fi = float(i)*.0617; // Unique loop number.
        #ifdef EQUAL_SIDES        
        // Squares.
        
        // Random split.
        if(hash21(ip + .253 + fi)<.5){
           sc /= 2.;
           p = oP;
           ip = floor(p/sc) + .5; 
        }
        
        #else
        
        // Powers of two rectangles.
        
        // Random X-split.
        if(hash21(ip + .653 + fi)<.5){//3 && sc.x>1./8.
           sc.x /= 2.;
           p.x = oP.x;
           ip.x = floor(p.x/sc.x) + .5;
        }
        // Random Y-split.
        if(hash21(ip + .447 + fi)<.5){ // && sc.y>1./8.
           sc.y /= 2.;
           p.y = oP.y;
           ip.y = floor(p.y/sc.y) + .5;
        }
        
        #endif
         
    }
    
    // Local coordinates and cell ID.
    return vec4(p - ip*sc, (ip + ipOffs)*sc);

}

// IQ's 3D signed box formula: I tried saving calculations by using the unsigned one, and
// couldn't figure out why the edges and a few other things weren't working. It was because
// functions that rely on signs require signed distance fields... Who would have guessed? :D
float sBoxS(vec3 p, vec3 b, float sf){

  p = abs(p) - b + sf;
  return min(max(p.x, max(p.y, p.z)), 0.) + length(max(p, 0.)) - sf;
}

// IQ's 2D signed box formula with some added rounding.
float sBoxS(vec2 p, vec2 b, float sf){

  p = abs(p) - b + sf;
  return min(max(p.x, p.y), 0.) + length(max(p, 0.)) - sf;
}


// Surface bump function..
float bumpSurf3D(in vec3 p, in vec3 n){

 
    vec2 sc = vec2(1, 1)/3.; // Scale.

    // Polar coordinates for a polar pattern to match the scene.
    p.xy = vec2(length(p.xy), atan(p.y, p.x)/TAU*5.);
    
    
    // Local coordinates and cell ID.
    vec4 p4 = getGrid(p.xy, sc); 
    vec2 id = p4.zw; // The cell ID is an "inout" variable.


    // Edge factor.
    float ef = min(sc.x, sc.y);

    float d = sBoxS(p4.xy, sc/2., ef*.05);


    return min(-d, .01);//1. - smoothstep(-.007, .007, d);
    

}
 
// Standard function-based bump mapping routine: This is the cheaper four tap version. 
// There's a six tap version (samples taken from either side of each axis), but this 
// works well enough.
vec3 doBumpMap(in vec3 p, in vec3 n, float bumpfactor){
    
    // I try not to rotate entire scenes from the map function, since it's 
    // faster to use the camera... Anyway, to bump function position and
    // normal need to rotate to match.
    mat2 m = rot2(tm/16. + 3.14159/4.);

    // Larger sample distances give a less defined bump, but can sometimes lessen the 
    // aliasing.
    const vec2 e = vec2(.001, 0);  
    vec3 v0 = e.xyy;
    vec3 v1 = e.yxy;
    vec3 v2 = e.yyx;
 
    mat2 invM = m;//inverse(m);
    v0.xy = invM*v0.xy;
    v1.xy = invM*v1.xy;
    v2.xy = invM*v2.xy; 
    
    mat4x3 p4 = mat4x3(p, p - v0, p - v1, p - v2);
    for(int i = 0; i<4; i++) p4[i].xy = m*p4[i].xy;
    
    // This utter mess is to avoid longer compile times. It's kind of 
    // annoying that the compiler can't figure out that it shouldn't
    // unroll loops containing large blocks of code.
 
    vec4 b4;
    for(int i = 0; i<4; i++){
        b4[i] = bumpSurf3D(p4[i], n);
        if(n.x>1e5) break; // Fake break to trick the compiler.
    }
    
    // Gradient vector: vec3(df/dx, df/dy, df/dz);
    vec3 grad = (b4.yzw - b4.x)/e.x; 
   
    
    // Six tap version, for comparisson. No discernible visual difference, in a lot of 
    //cases.
    //vec3 grad = vec3(bumpSurf3D(p - e.xyy) - bumpSurf3D(p + e.xyy),
    //                 bumpSurf3D(p - e.yxy) - bumpSurf3D(p + e.yxy),
    //                 bumpSurf3D(p - e.yyx) - bumpSurf3D(p + e.yyx))/e.x*.5;
    
  
    // Adjusting the tangent vector so that it's perpendicular to the normal. It's some 
    // kind of orthogonal space fix using the Gram-Schmidt process, or something to that 
    // effect.
    grad -= n*dot(n, grad);          
         
    // Applying the gradient vector to the normal. Larger bump factors make things more 
    // bumpy.
    return normalize(n + grad*bumpfactor);
	
}

