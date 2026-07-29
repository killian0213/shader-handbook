// Image (image) — Genuary 2025 #1 by Kali
// https://www.shadertoy.com/view/X3KyRz

#define so texture(iChannel0,vec2(.5,.3)).r

mat2 rot(float a) {
    a=radians(a);
    float s=sin(a), c=cos(a);
    return mat2(c,s,-s,c);
}


vec3 fractal(vec2 p) {
    float a=smoothstep(-.1,.1,sin(iTime*.5));
    p*=rot(90.*a);  
    vec2 p2=p;
    p*=.5+asin(.9*sin(iTime*.2))*.3;
    p.y-=a;
    p.x+=iTime*.3+so*.1;
    p=fract(p*.5);
    float m=1000.;
    float it=0.;
    for (int i=0; i<10; i++) {
        p=abs(p)/clamp(abs(p.x*p.y),.25,2.)-1.;
        float l=abs(p.x);
        m=min(m,l);
        if (m==l) {
            it=float(i);
        }

    }
    float f=smoothstep(.015,.01,m*.5);
    f*=step(p2.y*.5+p2.x+it*.1-.3,.0);
    vec3 col=normalize(vec3(1.,.0,.5));
    col.rg*=rot(length(p2+it*.5)*200.);
    col=normalize(col+.5)+step(.5,fract(p2.y*100.));
    return col*(f*.9+.1)*(1.+so*5.);
}


void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy - .5;
    uv.x*=iResolution.x/iResolution.y;
    uv*=1.+so*.5;

    int aa = 5; 
    float f=max(abs(uv.x),abs(uv.y));
    vec2 pixelSize = 10. / iResolution.xy / float(aa) * f;
    vec3 col = vec3(0.0); 

    for (int i = -aa; i <= aa; i++)
    {
        for (int j = -aa; j <= aa; j++)
        {
            vec2 offset = vec2(float(i), float(j)) * pixelSize;
            col += fractal(uv + offset); 
        }
    }

    float totalSamples = float((aa * 2 + 1) * (aa * 2 + 1)); 
    col /= totalSamples;
    col*=exp(-1.*f);

    fragColor = vec4(col, 1.0);
}
