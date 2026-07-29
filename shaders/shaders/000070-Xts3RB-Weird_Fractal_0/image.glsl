// Image (image) — Weird Fractal 0 by aiekick
// https://www.shadertoy.com/view/Xts3RB

//based on shader from coyote => https://www.shadertoy.com/view/ltfGzS

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 p=vec4(fragCoord,0.,1.)/iResolution.x-.5,r=p-p,q=r;p.y+=.25;
    q.zw-=iTime*0.1+1.;
    
    for (float i=1.; i>0.; i-=.01) {

        float d=0.,s=1.;

        for (int j = 0; j < 6; j++)
            r=max(r=abs(mod(q*s+1.,2.)-1.),r.yzxw),
            d=max(d,(.3-length(r*0.95)*.3)/s),
            s*=3.;//-r.x*0.1;

        q+=p*d;
        
        fragColor = p-p+i;

        if(d<1e-5) break;
    }
}
