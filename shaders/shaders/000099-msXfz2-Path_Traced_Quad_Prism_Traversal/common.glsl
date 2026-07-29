// Common (common) — Path Traced Quad Prism Traversal by Shane
// https://www.shadertoy.com/view/msXfz2


// If you want things to wrap, you need a wrapping scale.  Wrapping is not much 
// different to regular mapping. You just need to put "p = mod(p, gSc)" in the hash 
// function for anything that's procedurally generated with random numbers. If you're 
// using a repeat texture, then that'll have to wrap too.
const vec3 gSc = vec3(6);

// Maximum frames to perform the precalculation.
int maxFrames = 1;

// Cube map resolution.
#define cubemapRes vec2(1024)


/* 
// Reading into one of the cube faces, according to the face ID. To save on cycles,
// I'd hardcode the face you're after into all but the least costly of situations.
// This particular function is used just once for an update in the "CubeA" tab.
//
// The four cube sides - Left, back, right, front.
// NEGATIVE_X, POSITIVE_Z, POSITIVE_X, NEGATIVE_Z
// vec3(-.5, uv.yx), vec3(uv, .5), vec3(.5, uv.y, -uv.x), vec3(-uv.x, uv.y, -.5).
//
// Bottom and top.
// NEGATIVE_Y, POSITIVE_Y
// vec3(uv.x, -.5, uv.y), vec3(uv.x, .5, -uv.y).
vec4 tx(samplerCube iCh, vec2 p, int id){    

    vec4 rTx;
    
    vec2 uv = fract(p) - .5;
    // It's important to snap to the pixel centers. The people complaining about
    // seam line problems are probably not doing this.
    //p = (floor(p*cubemapRes) + .5)/cubemapRes; 
    
    vec3[6] fcP = vec3[6](vec3(-.5, uv.yx), vec3(.5, uv.y, -uv.x), vec3(uv.x, -.5, uv.y),
                          vec3(uv.x, .5, -uv.y), vec3(-uv.x, uv.y, -.5), vec3(uv, .5));
 
    
    return texture(iCh, fcP[id]);
}
*/

// Wrapping cube face conversion.
vec2 convert(in vec2 p){ return fract((floor(p*cubemapRes) + .5)/cubemapRes) - .5; }

// Cube face conversion with no wrapping.
vec2 convert2(in vec2 p){ return ((floor(p*cubemapRes) + .5)/cubemapRes); }
//float convert2(in float p){ return ((floor(p*cubemapRes.x) + .5)/cubemapRes.x); }


// Cube face conversion with no wrapping.
vec4 convert2(in vec4 p){ return ((floor(p*cubemapRes.xyxy) + .5)/cubemapRes.xyxy); }


vec4 tx0(samplerCube iCh, vec2 p){
    vec2 uv = convert(p);
    return texture(iCh, vec3(-.5, uv.yx));
 
}
/*
vec4 tx1(samplerCube iCh, vec2 p){

    vec2 uv = convert(p);
    return texture(iCh, vec3(.5, uv.y, -uv.x));
}
*/

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }



// IQ's vec2 to float hash.
float hash21B(vec2 p){  
    return fract(sin(mod(dot(p, vec2(27.619, 57.583)), 6.2831853))*43758.5453); 
}

// IQ's vec2 to float hash.
float hash21(vec2 p){  
    p = mod(p, gSc.xy);
    return fract(sin(mod(dot(p, vec2(27.609, 57.583)), 6.2831853))*43758.5453); 
}


///////////////////

// Standard bit encoding and decoding... Every coder's favorite task! :D
// It's used for a specific task involving packing four low resolution 
// floats (stored in the form of integers) into one channel. Normally, you 
// could pack four large integers into one vector slot, but texture storage 
// complicates things, which traslates to smaller integers and less float
// resolution... I won't bore you with it. :)
const uint ni = 6U;
const float fi = float(ni);

const uvec4 bitEnc = uvec4(1, ni, ni*ni, ni*ni*ni);
vec4 EncodeFloatRGBA(float v) {
    
    return mod(vec4(uvec4(v)/bitEnc), fi);
}

float DecodeFloatRGBA(vec4 v) {

    //return float(uint(v.x) + uint(v.y)*ni + uint(v.z)*ni*ni + uint(v.w)*ni*ni*ni);
    return dot(vec4(uvec4(v)), vec4(bitEnc));
}



// Quad bound: We don't need an actual distance, so can take some shortcuts.
// I hacked this together, so there would be faster ways to do it.
float sdQuadBound(in vec2 p, mat4x2 v){
 
     
    //e[0] = normalize(v[0] - v[1]).yx*vec2(1, -1);
    //e[1] = normalize(v[1] - v[2]).yx*vec2(1, -1);
    //e[2] = normalize(v[2] - v[3]).yx*vec2(1, -1);
    //e[3] = normalize(v[3] - v[0]).yx*vec2(1, -1); 
    float d = dot(p - v[0], normalize(v[0] - v[1]).yx*vec2(1, -1));
    d = max(d, dot(p - v[1], normalize(v[1] - v[2]).yx*vec2(1, -1)));
    d = max(d, dot(p - v[2], normalize(v[2] - v[3]).yx*vec2(1, -1)));
    d = max(d, dot(p - v[3], normalize(v[3] - v[0]).yx*vec2(1, -1)));
    return d;

}


// Rectangle dimensions: Any numbers should work. Obviously, vec2(1)
// will produce squares.
vec2 s = 1./gSc.xy; //vec2(1, 1)/6.;

// IQ's vec2 to float hash.
vec2 hash22T(vec2 p){ 
    
    p = mod(p, 1./s);    
    
    p = fract(sin(mod(vec2(dot(p, vec2(12.783, 78.137)), 
                           dot(p, vec2(41.581, 57.263))), 6.2831853))
                          *vec2(43758.5453, 23421.6361));
    
    return mod(floor(p*float(ni)), float(ni));
    
    //return texture(iChannel0, p/64.).xy*2. - 1.; 
}





