// Image (image) — Ohanami Stipple by fizzer
// https://www.shadertoy.com/view/4tVcWR

float time;
float seed;
float rand() { return fract(sin(seed++)*43758.545); }

vec4 samp(vec2 p)
{
    p.y*=1280./720.;
    return texture(iChannel0,p/2.+.5)*1.05;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    time=iTime;
    vec2 t=(uv*2.-1.)*.55;
    t.x*=iResolution.x/iResolution.y;

    fragColor = texture(iChannel0, uv);

    // Sample the input image to pick locations to splat circular shapes from.
    vec3 c=vec3(.8,.8,1)/6.;
    vec2 p=t;
    for(int n=0;n<2;++n)
    {
        float maxr=mix(1./22.,1./4.,1.-float(n))*.4;

        ivec2 uo=ivec2(floor(p/maxr));
        for(int i=-1;i<2;++i)
            for(int j0=-1;j0<2;++j0)
            {
                vec2 u=vec2(uo)+vec2(i,((uo.x+i)&1)==1?-j0:j0);
                seed=u.x*881.+u.y*927.+float(n)*1801.;
                for(int k=0;k<11;++k)
                {
                    vec2 o=(u+vec2(rand(),rand()))*maxr;
                    vec2 p2=p-o;
                    vec3 cc=samp(o).rgb;
                    float a=dot(cc,vec3(1./3.));
                    float r=mix(.25,.99,pow(rand(),4.))*maxr;
                    float ang=rand()*acos(-1.)*2.; // This angle is used for the 'stroke lines' in the circles.
                    float d=length(p2);
                    p2*=mat2(cos(ang),sin(ang),-sin(ang),cos(ang));
                    cc=mix(cc,vec3(a)*1.5,pow(rand(),16.));
                    if(rand()>-floor(time*2.)/2./10.)
                    {
                        // Shade in the circle, and an outline of the circle.
                        c=mix(c,cc,mix(.1,.4,rand())*3.*pow(a,.8)*mix(.8,1.,cos(p2.x*1200.)*.5+.5)*clamp((r-d)/mix(.001,.004,rand()),0.,1.));
                        c=mix(c,cc/2.,mix(.14,.3,pow(rand(),16.))/4.*clamp(1.-abs(r-d)/.002,0.,1.));
                    }
                }
            }

    }

    // Apply some darkening based on edge detection, for something like a pencil sketch.
    vec2 e=vec2(1e-3,0.);
    vec2 p2=p+(valnoise(p*18.)-.5)*.01;
    float c0=dot(vec3(1./3.),samp(p2).rgb);
    float c1=dot(vec3(1./3.),samp(p2+e.xy).rgb);
    float c2=dot(vec3(1./3.),samp(p2+e.yx*1.8).rgb);

    c*=vec3(mix(.1,1.,1.-clamp(max(abs(c2-c0),abs(c1-c0))*4.,0.,.13)));

    // Final output.
    c=(c-.5)*1.1+.5;
    fragColor.rgb=sqrt(c*mix(.9,1.,valnoise(t.xy*400.)))*1.28;

}