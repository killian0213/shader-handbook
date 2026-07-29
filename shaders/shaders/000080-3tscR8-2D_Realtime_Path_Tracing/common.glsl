// Common (common) — 2D Realtime Path Tracing by Shane
// https://www.shadertoy.com/view/3tscR8

// Temporal camera reprojection: Without this option, you can see what the original
// looks like without the higher sampling this technique brings. Just for the record,
// the noisy image has a certain kind of shabby chic appeal to me. :D
#define TEMPORAL_REPROJECTION

// Show the Truchet pattern, or not. The alternative is just a grid of circles.
// If you change this from the Truchet pattern to the circles one, remember to hit the 
// back\reset button to reload the cube map.
//
// The Truchet pattern is more interesting, but I believe the static circles play off
// the light better.
#define TRUCHET_PATTERN


// Even cheaper without the light tracing, but the shadows won't be there. 
// However, I've darkened the surrounds to give that effect.
#define LIGHT_TRACE

// Display the underlying distance field. Sometimes, this can be helpful. The
// lighting definitely isn't as interesting though.
//#define DISTANCE_FIELD_ONLY


// Grid boundaries.
//#define SHOW_GRID


// Display the glowing light. It just a glowing blob moving in front of the
// camera through the pattern.
//#define SHOW_LIGHT


// Distance field object ID. For the Truchet case, we're simply flagging the
// inner and outer rails to give them some color.
vec2 gIP;

// Grid pattern repeat scale. Baking wrapped distance fields into textures can be 
// a little fiddly. Basically, the pattern is wrapped on a 32 by 32 unit basis.
float repSc = 32.;

// The cubemap texture resolution.
//#define iRes0 vec2(1024)

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }



// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.619, 57.583)))*43758.5453); }

vec2 hash22(vec2 p) {
    //return vec2(0);
    return fract(sin(vec2(dot(p, vec2(12.989, 78.233)), dot(p, vec2(41.898, 57.263))))
                      *vec2(43758.5453, 23421.6361));
}

// IQ's vec2 to float hash, but with a repeat factor. If you repeat random
// textures to wrap, then you need to wrap the random functions.
float hash21Rep(vec2 p){ 
    p = mod(p, repSc); 
    return fract(sin(dot(p, vec2(27.619, 57.583)))*43758.5453); 
}

vec2 hash22Rep(vec2 p) {
    //return vec2(0);
    p = mod(p, repSc);
    return fract(sin(vec2(dot(p, vec2(12.989, 78.233)), dot(p, vec2(41.898, 57.263))))
                      *vec2(43758.5453, 23421.6361));
}

// Believe it or not, the simple one-line function below took me ages to figure out. The 
// only refrences to it seem to be from some Microsoft documentation somewhere, because it's 
// all written in some obscure way that involves the term, "fract(p)*2. - 1.," etc.
//
// Anyway, the following should have been obvious to me, but it wasn't: A unit cube centered 
// on a grid has six faces with a center at vec3(0), and 8 vertices at coordinates, 
// vec3(-.5, -.5, -.5), vec3(-.5, -.5, .5), etc. Therefore, using very basic UV mapping logic, 
// the faces will be the following:
//
// Left face: 
// // Wrapping and centering coordinates on the YZ plain: 
// p.yz = fract(p.yz) - .5;
// // The X coordinate is at "-.5".
// p.x = -.5;
// // Texture coordinate. 
// vec4 tx = texture(texChannel, vec3(-.5, fract(p.yz) - .5));
//
// All faces follow the same logic, with a bit of UV flipping to get things facing the right 
// way, etc. Using uv = fract(uv) - .5:
//
// The four cube sides - Left, back, right, front.
// NEGATIVE_X, POSITIVE_Z, POSITIVE_X, NEGATIVE_Z
// vec3(-.5, uv.yx), vec3(uv, .5), vec3(.5, uv.y, -uv.x), vec3(-uv.x, uv.y, -.5).
//
// Bottom and top.
// NEGATIVE_Y, POSITIVE_Y
// vec3(uv.x, -.5, uv.y), vec3(uv.x, .5, -uv.y).
//
//
// From what I've noticed, the size of the cube you use doesn't seem to matter -- I'm 
// assuming this is due to an internal normalization process. Therefore, to save extra 
// calculations (which matter when doing 3D stuff), you may as well use the unit cube 
// figures above -- instead of vec3(fract(p)*2. - 1., 1), vec3(fract(p) - .5)*n, n), etc.
 

// Reading in the texture from the right face of the cube: I chose this because it 
// writes more easily, but you can read from any, or as many, faces you'd like. I'm
// assuming that all sides index into memory at the same rate, otherwise you'd have to
// take that into consideration when favoring one side or the other.
//
// By the way, "p" is simply your "uv" coordinates, which are usually: 
// uv = fragCoord/iResolution.y, but could represent cube sides, like p.xz, etc.
vec4 tx(samplerCube tx, vec2 p){    

    return texture(tx, vec3(fract(p) - .5, .5));
}

// IQ's box function, with modified smoothing element.
float sBoxS(in vec2 p, in vec2 b, in float rf){
  
  vec2 d = abs(p) - b + rf;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - rf;
    
}

// IQ's box function.
float sBox(in vec2 p, in vec2 b){
    
  vec2 d = abs(p) - b;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.));
}
