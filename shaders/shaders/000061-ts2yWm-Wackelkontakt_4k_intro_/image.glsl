// Image (image) — Wackelkontakt (4k intro) by slerpy
// https://www.shadertoy.com/view/ts2yWm

// stage 2: "post"

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // [debugging code]
    
    #if 0
    //  ^ set this to 1 to skip the shader stage
    fragColor=texelFetch(D,ivec2(fragCoord),0);
    return;
    #endif
    
    // [shadertoy fix-up]
    
    P=acos(-1.),T=2.*P;    // calculate pi and tau
    c=.0*R,m=c;            // init c and m as vec4(0)
    
    // ^ Both of these steps are done outside
    //   the main function in the actual intro.

    // [common code across all stages]
    
    vec2 v=gl_FragCoord.xy;  // get short mutable pixel coord
    r=vec4(v,R.yz);          // init random vector using pixel coord + time
    S();S();S();S();         //   and hash it 8 times
    S();S();S();S();         // *shuffle*, *shuffle*, *shuffle*

    float tt=R.z*7./48.,     // current chord playing in the soundtrack
    w=floor(tt)*step(2.,tt), // camera movement offset
    z=1.-.3*smoothstep(-.7,.0,-abs(tt-2.1))   // zoom around 00:14
        +.2*smoothstep(-1.,0.,-abs(tt-20.));  // zoom around 02:17
    if(tt<8.)z-=pow(tt/8.,48.);               // camera plunge at 00:54
    
    // ^ None of these camera specific vars are needed
    //   in this stage and they are only here for completeness.

    // [stage specific code]

    // get uv
    v/=R.xy;
    
    // calculate bloom
    for(float a=.0;a<T;a+=.63)
        c+=max(textureLod(D,v+7.8*pl(a)/R.xy/*+.011*R.xy/R.x*/,5.5)-.06,0.);
    
    // ^ The bloom is a simple mipmap blur with circular sampling to make it less blocky.
    //   The code commented out above is needed in the intro to offset the texel centers
	//   from 'lower left corner' (default in OpenGL) to 'center' (used in Shadertoy).
    //   The constant used for the offset is calculated like this:
    //   offset = texel_size/2 = pow(2,-mipmap)/2 = 1/(2^6.5) = ~0.0110485
    
    // final color
    c=pow(texture(D,v)+.02*c,vec4(.45))+.01*(r.x-.5);
	//      ^color      ^bloom  ^gamma    ^film noise
    
    // [common code across all stages]
    
    fragColor=c;
}