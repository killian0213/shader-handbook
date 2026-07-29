// Image (image) — Hexagonal Truchet Weaving by BigWIngs
// https://www.shadertoy.com/view/llByzz

// "Hexagonal Truchet Weaving" by Martijn Steinrucken aka BigWings/CountFrolic - 2017
// Email:countfrolic@gmail.com Twitter:@The_ArtOfCode
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// Here is my entry to the unoffical ShaderToy truchet competition ;)
//
// There are a few examples of hexagonal truchet on ShaderToy but they all seem to
// incorporate only curves that jump from one edge of the hexagon to an adjacent edge.
// This solution incorporates all possible curve jump combinations:
// 111 (the usual one), 113, 122, 223 and 333
// 
// A few other things of note:
// * I render the 3 curves per tile separately and layer them randomly, to get the 'weaving' effect.
// * In order to minimize small circle islands you can get sometimes I weighted the probabilities
// of tiles so that the highest probability goes to the 223 tile and the lowest to the 111 tile.
// * I randomly rotate tiles to get more variation.
// 
// Things that didn't works so well:
// I tried making proper uv coordinates for the curves, without mirroring down the middle of 
// the curve but so far haven't come up with anything useful because I keep getting curve ends 
// whose uvs don't match with their neighboring tile. This problem is compounded by the fact 
// that I'm rotating every tile randomly to get a more random look. I know that it is 
// impossible to always have perfect matching UVs but I thought I could come up with a decent
// looking work around but so far no luck. I'm sure at some point someone will come up with 
// something.
// I don't like all the if statements in my truchet function but this is the best I could come
// up without without obfuscating the hell out of things. 
//
// Credits:
// Iomateron for his explanation of hexagonal tiling:
// https://www.shadertoy.com/view/MlXyDl
// Shane for making this uber cool looking truchet effect:
// https://www.shadertoy.com/view/4td3zj
// FabriceNeyret2 for cleaning up my mainImage function.

// weights for the different types of tiles.
// actual weight is weight-previous weight
#define W111 .1
#define W113 .2
#define W122 .4
#define W223 .8
#define W333 1.

#define GRID_SIZE 18.
//#define REWIRE
#define VARY_WIDTH
float CURVE_WIDTH= .15;

// some functions
#define sat(x) clamp(x, 0., 1.)
#define S(a, b, t) smoothstep(a, b, t)

// some constants
#define I3   0.333333333	// 1/3
#define I6   0.166666666	// 1/6
#define R3   1.732050807	// square root of 3
#define IR3  0.577350269 	// the inverse of the square root of 3
#define HIR3 0.288675134	// half the inverse of the square root of 3
#define S60  0.866025404	// sine of 60 degrees
#define C60  0.5

float Remap01(float a, float b, float t) {
    return (t-a)/(b-a);
}

float N21(vec2 id) { return fract(sin(id.x*324.23+id.y*5604.342)*87654.53); }

vec4 UvCirc(vec2 uv, float radius, float thickness) {
	vec2 st = vec2(atan(uv.x, uv.y), length(uv));
    
    float t = thickness/2.;
    float w = .01;
    
    float r1 = radius-t;
    float r2 = radius+t;
    
    float mask = S(t+w, t, abs(radius-st.y));
    float alpha = S(t+.1, t, abs(radius-st.y));
    alpha = alpha*alpha*mix(.5, 1., mask);
    
    return vec4(st.x*radius, st.y, mask, alpha);
}

vec4 UvBeam(vec2 uv, float thickness) {
	float t = thickness/2.;
    float w = .01;
    float mask = S(t+w, t, abs(uv.y));
    float alpha = S(t+.1, t, abs(uv.y));
    alpha = alpha*alpha*(.5+.5*mask);
    
    return vec4(uv.x, uv.y, mask,alpha);
}

vec3 Truchet(vec2 uv, float n) {
	uv-= .5;
    uv.x /= R3;
    
    vec4 v1 = vec4(0);
    vec4 v2 = vec4(0);
    vec4 v3 = vec4(0);
    
    float w = .15;
    
    // get random rotation for each tile
    // since its only six could probably precompute / do some trickery
    float r = floor(fract(n*5.)*6.)/6.;
    r *= 6.28;
    float s = sin(r);
    float c = cos(r);
    mat2 rot = mat2(c, -s, s, c);
    uv *= rot;
		
    if(n<W111) {
        v1 = UvCirc(uv-vec2(0, I3), I6, CURVE_WIDTH);		// jump 1
    	v2 = UvCirc(uv-vec2(HIR3, -I6), I6, CURVE_WIDTH);	// jump 1
    	v3 = UvCirc(uv-vec2(-HIR3, -I6), I6, CURVE_WIDTH);	// jump 1
    }
    else if(n<W113) {
        v1 = UvCirc(uv-vec2(0, I3), I6, CURVE_WIDTH);		// jump 1
        v2 = UvCirc(uv-vec2(0, -I3), I6, CURVE_WIDTH);		// jump 1
        v3 = UvBeam(uv, CURVE_WIDTH);						// jump 3
    }
    else if(n<W122) {
        v1 = UvCirc(uv-vec2(-HIR3, -I6), I6, CURVE_WIDTH);	// jump 1
        v2 = UvCirc(uv-vec2(IR3, 0), .5, CURVE_WIDTH);		// jump 2
        v3 = UvCirc(uv-vec2(HIR3, .5), .5, CURVE_WIDTH);	// jump 2
    }
    else if(n<W223) {
        v1 = UvCirc(uv-vec2(IR3, 0), .5, CURVE_WIDTH);		// jump 2
        v2 = UvCirc(uv-vec2(-IR3, 0), .5, CURVE_WIDTH);   	// jump 2  
        v3 = UvBeam(uv, CURVE_WIDTH);						// jump 3
    } else {
        mat2 rot60 = mat2(C60, -S60, S60, C60);
    	mat2 rot60i = mat2(C60, S60, -S60, C60);
        
        v1 = UvBeam(uv, CURVE_WIDTH);						// jump 3
 		v2 = UvBeam(uv*rot60, CURVE_WIDTH);					// jump 3
    	v3 = UvBeam(uv*rot60i, CURVE_WIDTH); 				// jump 3
    }
    
    float d1 = fract(n*10.);		// expand my random number by taking digits
    float d2 = fract(n*100.);
    float d3 = fract(n*1000.);
    float dMin = min(d1, min(d2, d3));
    
    // composite in different orders
    vec4 v = d1<.166 ? mix(v1, mix(v2, v3, v3.a), max(v2.a, v3.a))
           : d1<.333 ? mix(v1, mix(v3, v2, v2.a), max(v2.a, v3.a))
           : d1<.5   ? mix(v2, mix(v1, v3, v3.a), max(v1.a, v3.a))
           : d1<.666 ? mix(v2, mix(v3, v1, v1.a), max(v1.a, v3.a))
           : d1<.833 ? mix(v3, mix(v1, v2, v2.a), max(v1.a, v2.a))
           :           mix(v3, mix(v2, v1, v1.a), max(v1.a, v2.a));     

    v.gr*=0.; // mask out some failed uv experiments
   
    return vec3(v.rgb);
}

void mainImage( out vec4 O, vec2 u )
{
    u = ( u / iResolution.x - .5 ) * GRID_SIZE;
    float t = iTime * .02,
          S = sin(t), C = cos(t);
    u *= mat2(-C, S, S, C);
    u.x += iTime*1.;
	
    #ifdef VARY_WIDTH
    CURVE_WIDTH = mix(.05, .25, (sin(u.x+sin(u.y))+sin(u.y*.35))*.25+.5);
    #endif
    
    vec2 s = vec2(1.,R3),
         a = mod(u     ,s)*2.-s,
         b = mod(u+s*.5,s)*2.-s;

    u /= s;
    
    float da = dot(a, a);
	float db = dot(b, b);
    
    vec2 id = da < db 
                  ? floor(u) 
                  : floor(u+=.5)-.5;
    
    
    float n = N21(id);
    #ifdef REWIRE
    n = N21(id+vec2(floor(iTime*.1+n)));
    #endif
    O = Truchet(fract(u), n).rgbb;
    
    float outline = S(.7, 1.2, min(da, db));
    O.b = max(O.b, outline*.5);
}
