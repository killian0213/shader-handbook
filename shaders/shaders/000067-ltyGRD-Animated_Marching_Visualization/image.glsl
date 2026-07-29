// Image (image) — Animated Marching Visualization by lara
// https://www.shadertoy.com/view/ltyGRD

#define T (iTime*.5)

#define P 0.0001 // precision
#define S 50.    // steps
#define D 3.     // distance

vec2 _p; float _d = 1e10;

float sdBox(vec2 p,vec2 s)
{
    return length(max(p=abs(p)-s,0.))+min(max(p.x,p.y),0.);
}

float sdLine(vec2 p,vec2 a,vec2 b)
{
    return length(-clamp(dot(p-=a,b-=a)/dot(b,b),0.,1.)*b+p);
}

float scene(vec2 p)
{
    return min(
        max(max(length(p-vec2(1,0))-.3,-length(p-vec2(.8,0))+.15),-abs(p.y)+.05),
        min(
            sdBox(vec2(p.x,abs(p.y))-vec2(1,.6),vec2(.3,.05)),
            sdBox(vec2(p.x,abs(p.y))-vec2(1.25,.55),vec2(.05,.05))
       )
    );
}

vec2 getNormal(vec2 p)
{    
	vec2 e = vec2(P,0);
    return normalize(vec2(scene(p+e.xy)-scene(p-e.xy),scene(p+e.yx)-scene(p-e.yx)));
}

void visualize(vec2 ro, vec2 rd, float t, float d, float i)
{
    vec2 n = getNormal(ro+rd*t);
    
    float x  = clamp(floor(T)-i,0.,1.);
    float f1 = x + (1.-x) * fract(T);
    float f2 = clamp((f1-.75)*16.,0.,1.);
    float f3 = floor(abs(cos(min(f1*8.,1.)*6.283))+.5);
    float a  = mix(atan(-n.y,-n.x),atan(rd.y,rd.x),f2);

    // ray line
    _d = min(_d,sdLine(_p,ro+rd*t,ro+rd*t+vec2(cos(a),sin(a))*d*floor(f3)));

    // step indicator
    _d = min(_d,length(_p-ro-rd*t)-.015);

    if (i == floor(T))
    {
        // circle
        _d = min(_d,abs(length(_p-ro-rd*t)-clamp(d*f3,0.,1e4)));
    }
}

vec4 march(vec2 ro, vec2 rd)
{
    float t = 0., s = float(S), d;

    for(float i = 0.; i < S; i++)
    {
        d = scene(ro+rd*t);

        if (d < P || t > D || i > floor(T))
        {
            s = float(i);
            break;
        }

		visualize(ro,rd,t,d,i);
        
        t += d;
    }
    
    return vec4(ro+rd*t,d,s);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    _p = (2.*fragCoord.xy-iResolution.xy)/iResolution.yy;
	vec2 m = (2.*iMouse.xy-iResolution.xy)/iResolution.yy;
    
    if (iMouse.x < 10. && iMouse.y < 10.) m = vec2(0,.2);
    
    vec2 ro = vec2(-1,0);
    vec2 rd = normalize(m-ro);
    vec4 h  = march(ro,rd);
    
    // camera & scene
    _d = min(_d,min(min(abs(length(_p-ro)-.05),sdLine(_p,ro,ro+rd*.05)),scene(_p)));
        
    // normal arrow
    if (h.z < P)
    {
        vec2 n = getNormal(h.xy);
        vec2 t = vec2(-n.y,n.x);

        _d = min(_d,sdLine(_p,h.xy,h.xy+n*.1));
        _d = min(_d,sdLine(_p,h.xy+n*.1,h.xy+n*.1+t*.025));
        _d = min(_d,sdLine(_p,h.xy+n*.1,h.xy+n*.1-t*.025));
        _d = min(_d,sdLine(_p,h.xy+n*.1+t*.025,h.xy+n*.125));
        _d = min(_d,sdLine(_p,h.xy+n*.1-t*.025,h.xy+n*.125));
    }
    
    _d = abs(_d)-1./iResolution.y;
    
	fragColor = vec4(vec3(smoothstep(_d,_d+.005,.005)),1.0);
}