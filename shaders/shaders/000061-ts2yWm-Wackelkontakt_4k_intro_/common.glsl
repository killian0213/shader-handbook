// Common (common) — Wackelkontakt (4k intro) by slerpy
// https://www.shadertoy.com/view/ts2yWm

// shader uniforms
#define R vec4(iResolution.xy, mod(iTime, 150.), 0)
#define D iChannel0

// ^ R.w is the shader stage in the actual intro,
//   so intead of having 3 different shaders (one for each stage),
//   we only have a single shader which we run in a loop.
//   This approach makes the framework a bit more compact
//   and allowes for a lot of minification in the shader.

// global variables
float P,T;   // pi, tau
vec4 r,c,m;  // random vector, color, mask

// ^ These variables are defined at declaration in the actual intro.
//   Since this is not allowed on Shadertoy, they are left undefined
//   here and assigned a value in the "shadertoy fix-up" section in
//   the main function of every stage.

// shuffle function
void S()
{
    // hash global "random vector" variable
    r=fract(1e4*sin(r)+r.wxyz);
    
    // Instead of making a function that returns random numbers,
    // this intro has a global variable `r` which holds random
    // numbers. Whenever those numbers were used, we call this
    // shuffle function afterwards to replace the values of `r`.
    
    // The hashing function itself is not very good, but it's
    // short and random enough for the small number of samples
    // used in the path tracer.
    
    // If you do decide to use it, make sure to initialize `r`
    // with a non-zero vector and shuffle at least 5 times before
    // the first use.
}

// polar function
vec2 pl(float a)
{
    // angle -> point on unit circle
    return vec2(cos(a),sin(a));
}

// rotation functions
mat3 rx(float a){return mat3(1,0,0,0,cos(a),sin(a),0,-sin(a),cos(a));}
mat3 ry(float a){return mat3(cos(a),0,sin(a),0,1,0,-sin(a),0,cos(a));}

// 2D hash function
vec2 H(vec2 p)
{
    vec3 r=vec3(p,1);
    
    for(int i=0;i<4;i++)
        r=fract(1e4*sin(r)+r.yzx);
       
    // ^ Same hashing function used in the shuffle function (S)
    //   with the same variable name to aid compression.
    
    // Fun fact: The Nvidia GTX and RTX cards implement the sin
    // function slightly differently and this noise function does
    // a great job amplifying those tiny differences, so a lot of
    // effects in this intro can look quite different depending
    // on what graphics card you're using.
    
    // We only found out because we noticed the noise patterns
    // looked different on the compo machine compared to what we
    // intended it to look like. If you want to see the intro
    // exactly as we designed it, check out noby's capture linked
    // as "youtube" or "video" on the pouet page.
    
    return r.xy;
}

// 2D continuous noise function
vec2 N(vec2 p)
{
    vec2 i=floor(p),f=p-i,o=vec2(0,1);
    
    return mix(mix(H(i),
                   H(i+o),f.y),
               mix(H(i+o.yx),
                   H(i+o.y),f.y),f.x);
}

// 2D continuous perlin noise function
vec2 pr(vec2 u)
{
    vec2 y=.0*u,n=y+2.;
    
    for(int i=0;i<8;i++)
        y+=N(u*n)/n,n*=2.;
    
    return y;
}
