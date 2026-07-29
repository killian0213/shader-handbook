// Buffer A (buffer) — Fluid physics by lomateron
// https://www.shadertoy.com/view/wdsGWS

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 t = vec4(EMPTY);
    if(iFrame == 0)//fill 2D space with balls or EMPTY
    {
        t = rand(fragCoord.xy)*vec4(2.,2.,.02,.02)-vec4(1.,1.,.01,.01);
        if(fract(sin(dot(fragCoord.xy,vec2(12.989,78.233)))*43758.5453)<.9)
        {t = vec4(EMPTY);}
    }
    vec2 r = 1./iResolution.xy;
    vec2 a = floor(fragCoord.xy*.5)*2.-2.;
    float id = dot(floor(fract(fragCoord.xy*.5)*2.),vec2(1.,2.))+1.;
    float id2 = 0.;
    for(float i = .5; i < 6.; ++i)
    {
        for(float j = .5; j < 6.; ++j)
    	{
            vec2 m = vec2(j,i);
            vec4 t2 = texture(iChannel0,(a+m)*r).xyzw;
            if(t2.x == EMPTY){continue;}
            t2.xy += 2.*(floor(m*.5)-1.);
            if(t2.x < 1. && t2.x >=-1. &&
               t2.y < 1. && t2.y >=-1. ){++id2;}
            if(abs(id2-id)<.1)//this means if id2 == id break
            {
                fragColor = t2;
                return;
            }
        }
    }
    fragColor = t;
}