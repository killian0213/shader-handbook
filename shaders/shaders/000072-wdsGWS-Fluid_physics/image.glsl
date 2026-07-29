// Image (image) — Fluid physics by lomateron
// https://www.shadertoy.com/view/wdsGWS

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 r = 1./iResolution.xy;
    vec2 u = fragCoord.xy*ZOOM;
    vec4 t = vec4(fract(u)*2.-1.,0.,0.);
    vec4 s = step(vec4(0.),t)*vec4(1.,1.,0.,0.)-vec4(1.,1.,0.,0.);
         u = (floor(u)+s.xy)*2.;
         s*= 2.;
    vec4 v = vec4(.6);
    for(float i = .5; i < 4.; ++i)
    {
        for(float j = .5; j < 4.; ++j)
    	{
            vec4 m = vec4(j,i,0.,0.);
            vec4 t2 = texture(iChannel0,(u+m.xy)*r).xyzw;
            vec4 p = t-t2-s-2.*floor(m*.5);
            if(t2.x != EMPTY && dot(p.xy,p.xy)<1.)
            {
                v = t2;
            }
        }
    }
    //color the ball depending on its velocity
    fragColor = .5+.5*cos(6.28*(.5+length(v.zw)+vec4(.0,.1,.2,.0)));
}