// Common (common) — Voronoi Greeble Displacement by Shane
// https://www.shadertoy.com/view/NllyWf

// Displacement texture variations. A reset will be necessary for each change.
// I.e., you'll need to hit the back button. 
// Variations: 0 through to 2
#define VARIATION 3

// Random texture object rotation. Hit the back button.
//#define RAND_ROT

// Add in pattern border line detail. Hit the back button.
#define LINES


// Adding a bit of corrugation. It's interesting, but not on by default.
// Hit the back button.
//#define CORRUGATE




// The cubemap texture resultion.
#define cubemapRes vec2(1024)

// Relates to iFrame.
int frame0 = 0;



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
*/


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
    p = mod(p, gSc.xy);
    return fract(sin(dot(p, vec2(27.609, 157.583)))*43758.5453); 
}


// Dave Hoskins puts together some pretty reliable hash functions. This is 
// his unsigned integer based vec3 to vec3 version.
vec3 hash33(vec3 p){

    p = mod(p, gSc);
    // Addendum: The float values cast to unsigned integers can be quite small,
    // in this particular case, so I've increased them for greater randomization.
    p *= vec3(9528.609, 7157.583, 7357.781);
	uvec3 q = uvec3(ivec3(p))*uvec3(1597334673U, 3812015801U, 2798796415U);
	q = (q.x^q.y^q.z)*uvec3(1597334673U, 3812015801U, 2798796415U);
	return -1. + 2.*vec3(q)*(1./float(0xffffffffU));
}

 
/*
vec3 hash33(vec3 p){

    
    //p = mod(p, gSc);
    //float n = sin(dot(p, vec3(7, 157, 113)));    
    //return fract(vec3(2097152, 262144, 32768)*n)*2. - 1.; 
    
    // Dave's hash function. More reliable with large values, but will still eventually break down.
    //
    // Hash without Sine.
    // Creative Commons Attribution-ShareAlike 4.0 International Public License.
    // Created by David Hoskins.
    // vec3 to vec3.
    p = mod(p, gSc);
	p = fract(p*vec3(.10313, .10307, .09731));
    p += dot(p, p.yxz + 19.1937);
    p = fract((p.xxy + p.yxx)*p.zyx)*2. - 1.;
    return p;
   
    
    
    // Note the "mod" call. Slower, but ensures accuracy with large time values.
    //mat2  m = rot2(mod(iTime, 6.2831853));	
	//p.xy = m * p.xy;//rotate gradient vector
    //p.yz = m * p.yz;//rotate gradient vector
    ////p.zx = m * p.zx;//rotate gradient vector
	//return p;
    

}
*/
 

// vec4 to vec4 hash.
vec4 hash41T(vec4 p){
    p = mod(p, vec4(gSc.x));
    return fract(sin(p)*43758.5453);
}

// Compact, self-contained version of IQ's 3D value noise function.
float n3DT(vec3 p){    
    
    // Square partioning.
    // Local corner points and local coordinates.
	vec3 ip = floor(p); p -= ip;
    
    // Smoothing.
    p = p*p*(3. - 2.*p); 
    //p *= p*p*(p*(p*6. - 15.) + 10.);
    
    
    // Random vector.    
	const vec3 s = vec3(27, 111, 57);
    // Randomizing corner points.
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    
    // Interpolate X.
    h = mix(hash41T(h), hash41T(h + s.x), p.x);
    // Interpolate Y.
    h.xy = mix(h.xz, h.yw, p.y);
    // Interpolate Z.
    return mix(h.x, h.y, p.z); // Range: [0, 1].
}

/*
// IQ's unsigned box formula.
float sBoxS(in vec2 p, in vec2 b, in float sf){

  return length(max(abs(p) - b + sf, 0.)) - sf;
}

// IQ's unsigned box formula.
float sBoxS(in vec3 p, in vec3 b, in float sf){

  return length(max(abs(p) - b + sf, 0.)) - sf;
}
*/

// IQ's signed box formula.
float sBoxS(in vec2 p, in vec2 b, in float sf){
   

  vec2 d = abs(p) - b + sf;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - sf;
}

// IQ's signed box formula.
float sBoxS(in vec3 p, in vec3 b, in float sf){
   

  vec3 d = abs(p) - b + sf;
  return min(max(max(d.x, d.y), d.z), 0.) + length(max(d, 0.)) - sf;
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

/*
// IQ's exponential-based smooth maximum function. Unlike the polynomial-based
// smooth maximum, this one is associative and commutative.
float smaxExp(float a, float b, float k){

    float res = exp(k*a) + exp(k*b);
    return log(res)/k;
}
*/

// IQ's exponential-based smooth minimum function. Unlike the polynomial-based
// smooth minimum, this one is associative and commutative.
float sminExp(float a, float b, float k){

    float res = exp(-k*a) + exp(-k*b);
    return -log(res)/k;
}

// mat3 rotation... I did this in a hurry, but I think it's right. :)
mat3 rot(vec3 ang){
    
    vec3 c = cos(ang), s = sin(ang);

    return mat3(c.x*c.z - s.x*s.y*s.z, -s.x*c.y, -c.x*s.z - s.x*s.y*c.z,
                c.x*s.y*s.z + s.x*c.z, c.x*c.y, c.x*s.y*c.z - s.x*s.z,
                c.y*s.z, -s.y, c.y*c.z);
    
}



/*
// IQ's extrusion formula.
float opExtrusion(in float sdf, in float pz, in float h){
    
    vec2 w = vec2(sdf, abs(pz) - h);
  	return min(max(w.x, w.y), 0.) + length(max(w, 0.));

}

// Signed distance to a regular hexagon -- using IQ's more exact method.
float sdHexagon(in vec2 p, in float r){
    
  const vec3 k = vec3(-.8660254, .5, .57735); // pi/6: cos, sin, tan.

  // X and Y reflection.
  p = abs(p);
  p -= 2.*min(dot(k.xy, p), 0.)*k.xy;
    
  // Polygon side.
  return length(p - vec2(clamp(p.x, -k.z*r, k.z*r), r))*sign(p.y - r);
    
}

*/

// This is a variation on a regular 2-pass Voronoi traversal that produces a Voronoi
// pattern based on the interior cell point to the nearest cell edge (as opposed
// to the nearest offset point). It's a slight reworking of Tomkh's example, which
// in turn, is based on IQ's original example. The links are below:
//
// On a side note, I have no idea whether a faster solution is possible, but when I
// have time, I'm going to try to find one anyway.
//
// Voronoi distances - iq
// https://www.shadertoy.com/view/ldl3W8
//
// Here's IQ's well written article that describes the process in more detail.
// https://iquilezles.org/articles/voronoilines
//
// Faster Voronoi Edge Distance - tomkh
// https://www.shadertoy.com/view/llG3zy
//
//
vec3 cellID;
int gIFrame;

ivec4 gID2;

// Distance metric: Put whatever you want here.
float distMetric(vec3 p, vec3 b, int id){
    
    
    if(id==0){
    	return (dot(p, p));///2.; // Sphere squared.
    }
    else {
        
        //float d2 = sBoxS(p.xy, b.xy/1., 0.);
        //float d2 = sdHexagon(p.xy, min(b.x, b.y));
        //return opExtrusion(d2, p.z, b.z/1.);
        
        //return sBoxS(p, b, .1);

        
        //return (dot(p, p)) - b.x*b.x;
        //return length(p) - b.x; // Standard spherical Euclidean distance.

        //return max(max(length(p.xy), length(p.yz)), length(p.xz)); // Cylinder cross.

        //p = max(abs(p)*.8660254 + p.yzx*.5, -p);
        //return max(max(p.x, p.y), p.z); // Triangular.

        // Uncomment this for all metrics below.
        p = abs(p) - b;
        
        
        //p = (p + p.yzx)*.7071;
        //return max(max(p.x, p.y), p.z); // Can't remember -- Diamond related. :)


        return max(max(p.x, p.y), p.z); // Cube.
        //return (p.x + p.y + p.z)*.5;//.57735; // Octahedron.
        
        
        //p = (p - p.yzx);
        //p = abs(p) - b;
        //return max(max(p.x, p.y), p.z);
        
        
        // Mixtures.
        //return mix(max(max(p.x, p.y), p.z), length(p), .15);

        //p = p*.8660254 + p.yzx*.5;
        //return max(max(p.x, p.y), p.z); // Hex.
/*
        p = abs(p) - b;
        float taper = (p.x + p.y + p.z)/3.*2.*.65 + .35; // Linear gradient of sorts.
        //float taper = p.y + .5; // Original.
        //taper = mix(taper, max(taper, .5), .35); // Flattening the sharp edge a bit.

        p = abs(p)*2.;
        //p = vec2(abs(p.x)*1.5, (p.y)*1.5 - .25)*2.; // Used with triangle.

        float shape = max(max(p.x, p.y), p.z); // Square.
        //float shape = max(p.x*.866025 - p.y*.5, p.y); // Triangle.
        //float shape = max(p.x*.866025 + p.y*.5, p.y); // Hexagon.
        //float shape = max(max(p.x, p.y), (p.x + p.y)*.7071); // Octagon.
        //float shape = length(p); // Circle.
        //float shape = dot(p, p); // Circle squared.


        //shape = (shape - .125)/(1. - .125);
        //shape = smoothstep(0., 1., shape);


        //return shape;
        return max(shape, taper);
        */

    }
    
}

vec3 vIP;

// 2D 3rd-order Voronoi: This is just a rehash of Fabrice Neyret's version, which is in
// turn based on IQ's original. I've simplified it slightly, and tidied up the "if" statements.
//
vec3 Voronoi(in vec3 q, in vec3 sc, in vec3 rotF, float offsF, int rowOff, int id){
    
    
	//const vec3 sc = vec3(1, 2, 1);
    gSc /= sc;
 	vec3 d = vec3(1e5); // 1.4, etc.
    
    float r;
    
    const int n = 3;
    // Widen or tighten the grid coverage, depending on the situation. Note the large 
    // spread. That's to cover the third order distances. In a lot of cases, (3x3x3) is enough,
    // but in some, 729 taps (9x9x9), or even more, might be necessary.
    //
    // Either way, this is fine for static imagery, but needs to be reined in for realtime use.
    for(int z = -n; z <= n; z++){ 
        for(int y = -n; y <= n; y++){ 
            for(int x =-n; x <= n; x++){

                vec3 cntr = vec3(x, y, z) - floor(float(n)/2. + .001);
                vec3 p = q;
    
                if(rowOff == 1){
                    // Alternate 3D row offset -- Due to the cube's construction,
                    // only one slice at a time will work... There might be a more
                    // interesting way to shuffle things, but this'll do.
                    if(mod(floor(p.z/sc.x - cntr.z), 2.)>.5){
                        if(mod(floor(p.x/sc.x - cntr.x), 2.)<.5) p.y += sc.y/2.;
                    }
                    else if(mod(floor(p.y/sc.y - cntr.y), 2.)<.5) p.x += sc.x/2.;
                }
                
                 
				vec3 ip = floor(p/sc - cntr) + .5; 
                p -= (ip)*sc;
                //ip += cntr;
                
                // Random position and rotation vectors.
                vec3 rndP = hash33(ip);
                vec3 rndR = hash33(ip + 3.)*6.2831*rotF;

                // Rotate.
                p = rot(rndR)*p;
                //p.xy *= rot2(rndR.x);
                //p.yz *= rot2(rndR.y);
                //p.zx *= rot2(rndR.z);
               
               
                //rndP = floor(rndP*16.)/16.;
                // Postional offset.
                p -= rndP*offsF*sc;
                
                
                // Scale -- Redundant here.
				vec3 b = sc/2.*vec3(1, 1, 1);//*(hash33(ip)*.5 + .5);
                // Distance metric.
                r = distMetric(p, b, id);
                
                if(r<d.x) vIP = ip;

                // 1st, 2nd and 3rd nearest distance metrics.
                d.z = max(d.x, max(d.y, min(d.z, r))); // 3rd.
                d.y = max(d.x, min(d.y, r)); // 2nd.
                d.x = min(d.x, r);//smin(d.x, r, .2); // Closest.
                
                // Redundant break in an attempt to ensure no unrolling.
                // No idea whether it works or not.
                if(d.x>1e5) break; 

            }
        }
    }

    
    return d;//min(d, 1.);
    
}