// Buffer B (buffer) — Wackelkontakt (4k intro) by slerpy
// https://www.shadertoy.com/view/ts2yWm

// stage 1: "tracer"

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // [debugging code]
    
    //#define CUSTOM_SAMPLE_COUNT 10
    
    #if 0
    //  ^ set this to 1 to skip the shader stage
    fragColor=2.*texelFetch(D,ivec2(fragCoord),0);
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

    // [stage specific code]

    // sample loop
    #ifdef CUSTOM_SAMPLE_COUNT
    for(int i=0;i<CUSTOM_SAMPLE_COUNT;i++)
    #else
    for(int i=0;i<200;i++)
    #endif
    {
        // update random vector to keep it random
        S();
        
        // camera movement
        float h=fract(clamp(tt,2.,20.)-1e-5),
              s=1.2*pow(1.-h,5.5);
        vec2  f=.07*sqrt(r.z)*pl(T*r.w),             // depth of field
              u=(v+r.xy-.5-.5*R.xy)/R.y,             // pixel uv
             rv=pl(.2*(R.z-.1*h+99.*min(0.,w-12.))); // rotation vector
        
        // camera setup
        mat3 rm=rx(.3*rv.x)*ry(.6*rv.y);        // calculate rotation matrix
        vec3 o=rm*vec3(z*.5*f,-s-1.),           // get camera origin
             d=rm*normalize(vec3(z*u-f,s+2.));  // get camera direction
        
        // get color from screen
        c+=texelFetch(D,ivec2(R.y*(o.xy-d.xy*o.z/d.z)+.5*R.xy),0) // intersect ray with screen and fetch texture
           	+.01*pow(.5+.5*d.y,3.);                               // add super simple skybox
        
        // ^ Because we can be sure that it's always going to hit the same geometry,
        //   we can directly calculate the texture coordinate from camera direction and orientation.
        //   This shortcut is not only great for size, but also performance.
    }
    
    // brightness correction
    #ifdef CUSTOM_SAMPLE_COUNT
    c*=1.6/float(CUSTOM_SAMPLE_COUNT);
    #else
    c/=125.;
    #endif

    // [common code across all stages]
    
    fragColor=c;
}