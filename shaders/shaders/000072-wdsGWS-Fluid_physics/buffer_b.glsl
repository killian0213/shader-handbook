// Buffer B (buffer) — Fluid physics by lomateron
// https://www.shadertoy.com/view/wdsGWS

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 r = 1./iResolution.xy;
    vec2 u = fragCoord.xy;
    vec4 t = texture(iChannel0,u*r).xyzw;
         u = floor(fragCoord.xy*.5)*2.-2.;
    vec2 v = vec2(0.);
    if(iFrame == 0)//fill 2D space with balls or EMPTY
    {
        t = rand(fragCoord.xy)*vec4(2.,2.,.02,.02)-vec4(1.,1.,.01,.01);
        if(fract(sin(dot(fragCoord.xy,vec2(12.989,78.233)))*43758.5453)<.9)
        {t = vec4(EMPTY);}
    }
    if(iMouse.z>0. && length(fragCoord.xy*.5-iMouse.xy*ZOOM) < 4.)//click balls
    {
        t = rand(fragCoord.xy)*vec4(2.,2.,.02,.02)-vec4(1.,1.,.01,.01);
    }
    for(float i = .5; i < 6.; ++i)
    {
        for(float j = .5; j < 6.; ++j)
    	{
            vec4 m = vec4(j,i,0.,0.);
            vec4 t2 = texture(iChannel0,(u+m.xy)*r).xyzw;
            if(t2.x == EMPTY){continue;}
            vec4 p = t-t2+vec4(2.,2.,0.,0.)-2.*floor(m*.5);
            vec2 d = p.xy;
            float l = length(d);
            if(l > 2. || l < .0001){continue;}         //no collision
            d /= l;                    //direction force of collision normalized
            float c = (2.-l)*FRC1;     //repulsion force of collision 
            float e = dot(d,p.zw)*FRC2;//inelastic force of collision 
            v += d*(c-e);
        }
    }
    t.zw += v*FTOV;
    t.xy += t.zw*VTOP;
    fragColor = t;
}