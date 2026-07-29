// Common (common) — 3D Turing Texture by Shane
// https://www.shadertoy.com/view/NsSSDW

// The cubemap texture resultion.
#define cubemapRes vec2(1024)

int frame0 = 0;

// If you use all four channels of one 1024 by 1024 cube face, that would be
// 4096000 storage slots (1024*1024*4), which just so happens be 160 cubed.
// In other words, you can store the isosurface values of a 160 voxel per side
// cube into one cube face of the cubemap.
//
// The voxel cube dimensions: That's the one you'd change, but I don't really
// see the point, since setting it to the maximum resolution makes the most
// sense. For demonstrative purposes, dropping it to say, vec3(80), will show
// how a decrease in resolution will affect things. Increasing it to above the
// allowable resolution (for one cube face) to say, vec3(200), will display the
// wrapping issues.
//
// On a side note, I'm going to put up an example later that uses four of the 
// cubemap faces, which should boost the resolution to 256... and hopefully,
// not add too much to the complexity, and consequent lag that would follow.
const vec3 dimsVox = vec3(100); 
const vec3 scale = vec3(1, 1, 1);
const vec3 dims = dimsVox/scale;

 
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
vec4 tx(samplerCube tx, vec2 p, int id){    

    vec4 rTx;
    
    vec2 uv = fract(p) - .5;
    // It's important to snap to the pixel centers. The people complaining about
    // seam line problems are probably not doing this.
    //p = (floor(p*cubemapRes) + .5)/cubemapRes; 
    
    vec3[6] fcP = vec3[6](vec3(-.5, uv.yx), vec3(.5, uv.y, -uv.x), vec3(uv.x, -.5, uv.y),
                          vec3(uv.x, .5, -uv.y), vec3(-uv.x, uv.y, -.5), vec3(uv, .5));
 
    
    return texture(tx, fcP[id]);
}


vec4 texMapCh(samplerCube tx, vec3 p){
    
    p *= dims;
    int ch = (int(p.x*4.)&3);
    p = mod(floor(p), dims);
    float offset = dot(p, vec3(1, dims.x, dims.x*dims.y));
    vec2 uv = mod(floor(offset/vec2(1, cubemapRes.x)), cubemapRes);
    // It's important to snap to the pixel centers. The people complaining about
    // seam line problems are probably not doing this.
    uv = fract((uv + .5)/cubemapRes) - .5;
    return vec4(1)*texture(tx, vec3(-.5, uv.yx))[ch];
    
}

// Used in conjunction with the function below. When doing things eight times over, any 
// saving is important. If I could trim this down more, I would, but there's wrapping
// and pixel snapping to consider. Having said that, I might take another look at it,
// at some stage.
vec4 txChSm(samplerCube tx, in vec3 p){
   
    p = mod(floor(p), dims);
    //vec2 uv = mod(floor(dot(p, vec3(1, dims.x, dims.x*dims.y))/vec2(1, cubemapRes.x)), cubemapRes);
    vec2 uv = floor(dot(p, vec3(1, dims.x, dims.x*dims.y))/vec2(1, cubemapRes.x));
    // It's important to snap to the pixel centers. The people complaining about
    // seam line problems are probably... definitely not doing this. :)
    uv = fract((uv + .5)/cubemapRes) - .5;
    return texture(tx, vec3(-.5, uv.yx));
    
}

// Smooth texture interpolation that access individual channels: You really need this -- I 
// wish you didn't, but you do. I wrote it a while ago, and I'm pretty confident that it works. 
// The smoothing factor isn't helpful at all, which surprises me -- I'm guessing it molds things 
// to the shape of a cube. Anyway, it's written in the same way that you'd write any cubic 
// interpolation: 8 corners, then a linear interpolation using the corners as boundaries.
//
// It's possible to use more sophisticated techniques to achieve better smoothing, but as you 
// could imagine, they require more samples, and are more expensive, so you'd have to think about 
// it before heading in that direction -- Perhaps for texturing and bump mapping.
vec4 texMapSmoothCh(samplerCube tx, vec3 p){

    // Voxel corner helper vector.
	//const vec3 e = vec3(0, 1, 1./4.);
	const vec2 e = vec2(0, 1);

    // Technically, this will center things, but it's relative, and not necessary here.
    //p -= .5/dimsVox.x;
    
    p *= dimsVox;
    vec3 ip = floor(p);
    p -= ip;

    
    //int ch = (int(ip.x)&3), chNxt = ((ch + 1)&3);  //int(mod(ip.x, 4.))
    //ip.x /= 4.;
/*
    float c = mix(mix(mix(txChSm(tx, ip + e.xxx, ch).x, txChSm(tx, ip + e.yxx, chNxt).x, p.x),
                     mix(txChSm(tx, ip + e.xyx, ch).x, txChSm(tx, ip + e.yyx, chNxt).x, p.x), p.y),
                 mix(mix(txChSm(tx, ip + e.xxy, ch).x, txChSm(tx, ip + e.yxy, chNxt).x, p.x),
                     mix(txChSm(tx, ip + e.xyy, ch).x, txChSm(tx, ip + e.yyy, chNxt).x, p.x), p.y), p.z);
*/
    
     vec4 txA = txChSm(tx, ip + e.xxx);
     vec4 txB = txChSm(tx, ip + e.yxx);

     float c = mix(mix(mix(txA.x, txB.x, p.x), mix(txA.y, txB.y, p.x), p.y),
                   mix(mix(txA.z, txB.z, p.x), mix(txA.w, txB.w, p.x), p.y), p.z);

 
 	/*   
    // For fun, I tried a straight up average. It didn't work. :)
    vec4 c = (txChSm(tx, ip + e.xxx*sc, ch) + txChSm(tx, ip + e.yxx*sc, chNxt) +
             txChSm(tx, ip + e.xyx*sc, ch) + txChSm(tx, ip + e.yyx*sc, chNxt) +
             txChSm(tx, ip + e.xxy*sc, ch) + txChSm(tx, ip + e.yxy*sc, chNxt) +
             txChSm(tx, ip + e.xyy*sc, ch) + txChSm(tx, ip + e.yyy*sc, chNxt) + txChSm(tx, ip + e.yyy*.5, ch))/9.;
 	*/
    
    return vec4(c);

}

// If you want things to wrap, you need a wrapping scale. It's not so important
// here, because we're performing a wrapped blur. Wrapping is not much different
// to regular mapping. You just need to put "p = mod(p, gSc)" in the hash function
// for anything that's procedurally generated with random numbers. If you're using
// a repeat texture, then that'll have to wrap too.
vec3 gSc;


// Fabrice's concise, 2D rotation formula.
//mat2 rot2(float th){ vec2 a = sin(vec2(1.5707963, 0) + th); return mat2(a, -a.y, a.x); }
// Standard 2D rotation formula - Nimitz says it's faster, so that's good enough for me. :)
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }


// 3x1 hash function.
//float hash31(vec3 p){ return fract(sin(dot(p, vec3(21.471, 157.897, 113.243)))*45758.5453); }



// IQ's vec2 to float hash.
float hash21(vec2 p){
    return fract(sin(dot(p, vec2(27.609, 157.583)))*43758.5453); 
}

// David_Hoskins puts together some pretty reliable hash functions. This is 
// his unsigned integer based vec3 to vec3 version.
vec3 hash33(vec3 p){

    p = mod(p, gSc);
	uvec3 q = uvec3(ivec3(p))*uvec3(1597334673U, 3812015801U, 2798796415U);
	q = (q.x^q.y^q.z)*uvec3(1597334673U, 3812015801U, 2798796415U);
	return -1. + 2. * vec3(q) * (1./float(0xffffffffU));
}




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


