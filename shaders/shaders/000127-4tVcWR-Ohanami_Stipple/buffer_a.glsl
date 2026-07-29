// Buffer A (buffer) — Ohanami Stipple by fizzer
// https://www.shadertoy.com/view/4tVcWR

float time;

vec2 t;

float ti;
float col=1e3,col2=1e3,col3=1e3;

// Signed distance field function.
float f(vec3 p)
{
    col3=p.y-(.5+.5*cos(p.x*2.))*.1;

    float d=max(col3,length(p.xz)-5.5);
    float s=1.,ss=1.6;
    
    // Tangent vectors for the branch local coordinate system.
    vec3 w=normalize(vec3(-.8+cos(iTime/30.)*.01,1.2,-1.));
    vec3 u=normalize(cross(w,vec3(0,1,0)));

    int j=int(min(floor(ti-1.),7.));

    float scale=min(.3+ti/6.,1.);
    p/=scale;

    // Evaluate the tree branches, which are just space-folded cylinders.
    for(int i=0;
        d=min(d,scale*max(p.y-1.,max(-p.y,length(p.xz)-.1/(p.y+.7)))/s),
        p.xz=abs(p.xz),
        p.y-=1.,
        i<j;
        p*=mat3(u,normalize(cross(u,w)),w), // Rotate in to the local space of a branch.
        p*=ss,
        s*=ss,
        ++i);

    return min(d,col=max(0.,length(p)-.25)/s);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;

    t=(uv*2.-1.)*.5;
    t.x*=iResolution.x/iResolution.y;

    time=140.;

    // Timing value used in the original demo.
    ti=max(0.,time)/3.;
    ti=noise(floor(gl_FragCoord.xy))+(floor(ti)+clamp(fract(ti)*2.,0.,1.));
    ti=floor(ti);

    float zoom=1.5;
    vec2 filmoffset=vec2(0);

    // Set up camera and primary ray.
    vec3 ro=vec3(-2.5+cos(iTime/4.),.1+cos(ti*17.)*.1+iMouse.y/iResolution.y*2.,3.5);
    vec3 rd=normalize(vec3(t.xy+filmoffset,zoom));
    if(ti==10.)ro.y+=2.;
    vec3 camtarget=vec3(0,1.3,0);

    vec3 w=normalize(camtarget-ro);
    vec3 u=normalize(cross(w,vec3(0,1,0)));
    vec3 v=normalize(cross(w,-u));

    rd=mat3(u,v,w)*rd;

    fragColor.rgb=vec3(.8,.8,1.)/6.;
    float s=20.;

    // Signed distance field raymarch.
    float t=0.,d=0.;
    for(int i=0;i<100;++i)
    {
        d=f(ro+rd*t);
        if(d<1e-3)break;
        t+=d;
        if(t>10.)return;
    }

    // Colourise ground, branch/trunk, or cherry blossom.
    {
        vec3 rp=ro+rd*t;
        fragColor.rgb=vec3(.75,.6,.4)/1.5;
        if(col<2e-3)fragColor.rgb=vec3(1.,.7,.8);
        if(col3<2e-2&&(ti<17.||ti>22.))fragColor.rgb=vec3(.5,1.,.6)/3.;
    }

    // Lighting.
    vec3 ld=normalize(vec3(1.,3.+cos(ti)/2.,1.+sin(ti*3.)/2.));
    float e=1e-2;
    float d2=f(ro+rd*t+ld*e);
    float l=max(0.,(d2-d)/e);

    float d3=f(ro+rd*t+vec3(0,1,0)*e);
    float l2=max(0.,.5+.5*(d3-d)/e);

    {
        vec3 rp=ro+rd*t;
        if(ti>12.&&ti<22.)
            if(col2<1e-2||d3+d2/7.>0.0017&&pow(valnoise(rp.xz*8.),2.)>abs(ti-18.)/5.)fragColor.rgb=vec3(.65);
    }

    {
        vec3 rp=ro+rd*t;
        if(ti>12.&&ti<17.)
            if(col2<1e-2||d3+d2/7.>0.0017&&valnoise(rp.xz*8.)<(ti-12.)/3.)fragColor.rgb=vec3(.65);
    }

    vec3 rp=ro+rd*(t-1e-3);

    // Directional shadow.
    t=0.1;
    float sh=1.;
    for(int i=0;i<30;++i)
    {
        d=f(rp+ld*t)+.01;
        sh=min(sh,d*50.+0.3);
        if(d<1e-4)break;
        t+=d;
    }

    fragColor.rgb*=1.*sh*(.2+.8*l)*vec3(1.,1.,.9)*.7+l2*vec3(.85,.85,1.)*.4;
    fragColor.rgb=clamp(fragColor.rgb,0.,1.);
}