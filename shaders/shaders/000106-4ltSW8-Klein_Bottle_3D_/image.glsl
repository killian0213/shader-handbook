// Image (image) — Klein Bottle (3D) by lara
// https://www.shadertoy.com/view/4ltSW8

#define S 256   // Steps
#define P 0.001 // Precision
#define R 2.    // Marching substeps
#define D 15.   // Max distance
#define M 0.    // # of extra samples

#define T  iTime
#define PI 3.1415926

struct Ray { vec3 o, d; };
struct Camera { vec3 p, t; };
struct Hit { vec3 p; float t, d; };

Ray _ray;
Camera _cam;

float _d, _dsky;
bool _ignoreBottle = false;

mat2 rot(float a)
{
    float c=cos(a),s=sin(a);
    return mat2(c,-s,s,c);
}

vec2 hash22(vec2 p)
{
    return vec2(
        fract(sin(dot(p, vec2(50159.91193,49681.51239))) * 73943.1699),
        fract(sin(dot(p, vec2(90821.40973,2287.622010))) * 557.965570)
    );
}

float scene(vec3 p)
{
    _dsky = abs(length(p)-D+8.)-P;
    
    if (_ignoreBottle) { return _d = _dsky; }
    
    // thickness
    float t = 0.02;
    float d = 1e10;
    
    p.y += .5;
    p.xy *= rot(PI/2.);

    vec3  q = p + vec3(1.-cos((1.-p.y)/3.*PI),0,0);
    float y = pow(sin((1.-p.y)/3.*PI/2.),2.);
     
    float tube_hollow = max(max(abs(length(q.xz)-0.5+0.25*y)-t,q.y-1.0),-q.y-2.0);
    float tube_solid  = max(max(length(q.xz)-0.5+0.25*y,q.y-1.0),-q.y-2.0);
    
    // opening (half XZ torus)
    q = p - vec3(0,1,0);
    d = min(d,max(abs(length(vec2(length(q.xz)-1.0,q.y))-0.5)-t,-q.y));
    
    // body (stretched XZ torus)
    q = p;
    d = min(d,max(max(max(abs(length(q.xz)-1.5+1.25*y),q.y-1.0),-q.y-2.0)-t,-tube_solid));
    
    // tube (stretched XZ cylinder)
    d = min(d,tube_hollow);
    
    // handle (half XY torus)
    q = p + vec3(1,2,0);
    d = min(d,max(abs(length(vec2(length(q.xy)-1.0,q.z))-0.25)-t,q.y));
    
    // sky
    d = min(d,_dsky);
    
    return _d = d;
}

vec3 getNormal(vec3 p)
{
	vec2 e = vec2(P,0);
    
	return normalize(vec3(
		scene(p+e.xyy)-scene(p-e.xyy),
		scene(p+e.yxy)-scene(p-e.yxy),
		scene(p+e.yyx)-scene(p-e.yyx)
	));
}

Hit march(Ray r)
{
    float t = 0.0, d;

    for(int i = 0; i < S; i++)
    {
        d = scene(r.o+r.d*t);
        t += d/R;
        
        if (d < P || t > D) { break; }
    }
    
    return Hit(r.o+r.d*t, t, d);
}

Ray lookAt(Camera cam, vec2 uv)
{
    vec3 d = normalize(cam.t-cam.p);
    vec3 r = normalize(cross(d, vec3(0,1,0)));
    vec3 u = cross(r, d);

    return Ray(cam.p,normalize(r*uv.x + u*uv.y + d));
}

vec3 getColor(Hit h)
{
    if (_d > P     ) { return vec3(0); }
    if (_d == _dsky) { return texture(iChannel0,getNormal(h.p)).rgb; }

    vec4 col   = vec4(0);
    vec3 light = _cam.p;

    Hit _h = h;

    for(int i = 0; i < 10; i++)
    {
        if (i == 2) { h = _h; }

        vec3 n = getNormal(h.p);

        float diff = max(dot(normalize(light-h.p),n),0.0);
        float spec = pow(max(dot(reflect(normalize(h.p-light),n),normalize(_cam.p-h.p)),0.0),100.);

        vec4 c = vec4(vec3(.8,.9,1)*diff+spec,.15);
        
        if (i < 2 && _d == _dsky) { c = texture(iChannel0,n); }

        // fresnel
        float r = 1.12;
        float f = r + (1. - r)*(1. - dot(normalize(h.p-_cam.p),n))*5.;
        c.rgb = mix(c.rgb,vec3(0),f);

        col.rgb = col.rgb*(1.-c.a) + c.rgb*c.a;
        col.w = clamp(col.w+c.a,0.,1.);

        if (i > 1)
        { _ray.d = normalize(refract(h.p-_cam.p,n,1.5)); }
        else
        { _ray.d = normalize(reflect(h.p-_cam.p,n)); }

        _ray.o = h.p + _ray.d*.1;

        h = march(_ray);
        
        if (h.d > P) { break; }
    }

    _ray.d = normalize(_h.p-_cam.p);
    _ray.o = _h.p;
    
	_ignoreBottle = true;
    h = march(_ray);
    _ignoreBottle = false;

    return mix(texture(iChannel0,getNormal(h.p)).rgb,col.rgb,col.a);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (2.0*fragCoord.xy-iResolution.xy)/iResolution.yy;
    vec2 uvm = (2.0*iMouse.xy-iResolution.xy)/iResolution.yy;
    
    if (iMouse.y < 10. && iMouse.x < 10.) { uvm = vec2(-T*.2,0); }
    
    _cam = Camera(vec3(0,0,4), vec3(0,0,0));
    _cam.p.yz *= rot(-uvm.y*PI);
    _cam.p.xz *= rot(uvm.x*PI);
    
    _ray = lookAt(_cam,uv);
    
    vec3 col = getColor(march(_ray));

    for (float i = 0.0; i < M; i++)
    {            
        _ray = lookAt(_cam,uv+hash22(uv*i)/iResolution.xy*2.);
        col += getColor(march(_ray));
    }

    float f = 1.-length((2.0*fragCoord.xy-iResolution.xy)/iResolution.xy)*0.5;
    fragColor = vec4(col/(M+1.)*f,1);
}