// Image (image) — Planets 2d animation  by morimea
// https://www.shadertoy.com/view/wt2fWw


// License - CC0 or use as you wish

float rand(float p) {
    return mod(p*7241.6465+2130.465521, 64.984131);
}

float rand2(vec2 p) {
    return fract(sin(dot(p.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float hash(in vec2 p)
{
    return fract(dot(sin(p.x * 591.32 + p.y * 154.077), cos(p.x * 391.32 + p.y * 49.077)));
}

float noise( float y, float t)
{
    vec2 fl = vec2(floor(y), floor(t));
    vec2 fr = vec2(fract(y), fract(t));
    float a = mix(hash(fl + vec2(0.0,0.0)), hash(fl + vec2(1.0,0.0)),fr.x);
    float b = mix(hash(fl + vec2(0.0,1.0)), hash(fl + vec2(1.0,1.0)),fr.x);
    return mix(a,b,fr.y);
}

float line(vec2 uv,float width, float center, float px)
{
    float b		=	(1.- smoothstep(.0, width/2.+px, (uv.y-center)))*1.;
    return b;
}

const vec3 dark=vec3(0x1a,0x13,0x21)/float(0xff);
const vec3 white=vec3(0xdc,0xe0,0xd1)/float(0xff);
const vec3 red=vec3(0xa6,0x36,0x2c)/float(0xff);
const vec3 redw=vec3(0xfd,0x8c,0x77)/float(0xff);

float circle( in vec2 uv, float r1, float r2, bool disk)
{
    float w = 2.0*fwidth(uv.x);
    float t = r1-r2;
    float r = r1;

    if(!disk)
        return smoothstep(-w/2.0, w/2.0, abs(length(uv) - r) - t/2.0);
    else
        return smoothstep(-w/3.0, w/3.0, (length(uv) - r) );

}

#define MD(a) mat2(cos(a), -sin(a), sin(a), cos(a))
float animstart=2.5;

vec3 strucb(vec2 uv, float timer) {
    float d=step(-0.14,uv.y)*step(uv.y,-0.127)*step(abs(uv.x+0.19),0.02);
    vec3 ret=vec3(0.);
    d=max(d,step(-0.14,uv.y)*(1.-circle(uv+vec2(0.225,0.14),0.02270,0.35,true)));
    d=max(d,step(-0.14,uv.y)*(1.-circle(uv+vec2(0.165,0.14),0.02970,0.35,true)));
    d=max(d,step(uv.y,-0.094)*step(-0.14,uv.y)*smoothstep(0.0031,0.0008,abs(uv.x+0.12)));
    d=max(d,step(uv.y,-0.115)*step(-0.14,uv.y)*smoothstep(0.0031,0.0008,abs(uv.x+0.1075)));
    ret=d*red;
    float tuvx=mod(uv.x,0.006)-0.003;
    d=step(-0.132,uv.y);
    d=step(abs(uv.x+0.225),0.015)*d*smoothstep(0.0031,0.0005,abs(tuvx))*(1.-circle(uv+vec2(0.225,0.143),0.021970,0.35,true));
    ret=mix(ret,redw*1.25,d);
    tuvx=mod(uv.x-0.093,0.012)-0.006;
    d=smoothstep(0.0061,0.0035,abs(tuvx))*step(abs(uv.y+0.122),0.00182);
    ret=mix(ret,white,d*step(abs(uv.x+0.165),0.0165));
    return ret*smoothstep(animstart+2.2,animstart+3.2,timer);
}

vec3 postfx(vec2 uv, vec3 col,float reg) {
    vec3 ret=col+ 1.5*reg*((rand2(uv)-.5)*.07);
    //ret = clamp(1.5*ret,0.,1.);
    return ret;
}
#define PI (4.0 * atan(1.0))
#define TWO_PI PI*2.

float animendfade(float timer) {
    return smoothstep(animstart+11.5,animstart+9.5,timer);
}

vec3 map(vec2 uv, float lt, float timer) {
    float d=(circle(uv,0.32*smoothstep(animstart-1.,animstart+0.35,timer),0.,true));

    vec3 tcol=d*dark;
    float a=1.-circle(uv,0.3542,0.35,false);
    vec2 tuv=uv;
    float af = atan(tuv.x,tuv.y);
    float r = length(tuv)*0.75;
    tuv = vec2(af/TWO_PI,r);
    a*=step(tuv.x,-PI/2.+PI*smoothstep(animstart+2.5,animstart+4.8,timer));
    vec3 ret=max(tcol,a*(1.-lt)*redw);
    ret=max(ret,lt*dark);
    ret=max(ret,(1.-lt)*(1.-d)*red)*smoothstep(animstart-1.,animstart+0.35,timer);
    float b=1.-circle(uv+vec2(0.,0.225*smoothstep(animstart,animstart-2.,timer)),0.2242,0.22,true);
    tuv=uv;
    float tuvy=mod(tuv.y,0.015)-0.0075;
    float e=1.-max(smoothstep(0.0005,0.0031,abs(tuvy)),step(0.195,tuv.y)+step(tuv.y,0.185)*step(0.165,tuv.y)+
                   step(tuv.y,0.14)*step(0.06,tuv.y)+step(tuv.y,0.03)*step(0.015,tuv.y));

    float di=smoothstep(animstart+4.5,animstart+6.5,timer);
    float di2=smoothstep(animstart+8.5,animstart+9.5,timer);
    e*=step(uv.x+1.5*uv.y*(1.-di),di-0.5);
    e*=step(di2-.5,uv.x-2.*uv.y*(1.-di2));

    e=(1.-e)*(b);
    ret=max(ret,(1.-lt)*e*white);
    float c=1.-circle(uv,0.3542,0.35,true);
    tuvy=(mod(uv.y,0.026+0.1*smoothstep(-.5,0.5,uv.y))-0.013-0.05*smoothstep(-.5,0.5,uv.y));
    e=smoothstep(0.001,0.0051,abs(tuvy));
    e=((step(uv.y,-0.109))*c*(1.-e*step(uv.y,-0.109)));
    e*=step(abs(uv.x),0.5*smoothstep(animstart+1.5,animstart+3.,timer));
    ret=max(ret,red*e);
    tuv=uv;
    tuv*=MD(3.3-sin(01.0-cos(2.0*smoothstep(animstart+4.25,animstart+5.5,timer))));
    tuv+=vec2(0.35521,0.);
    float f=1.-circle(tuv,0.0270,0.35,true);
    ret=max(ret,f*redw*(1.-lt));
    tuv=uv;
    tuv*=MD(-0.3+01.*smoothstep(animstart+2.,animstart+4.8,timer));
    tuv+=vec2(0.2242,0.);
    f=1.-circle(tuv,0.0570,0.35,true);
    ret=max(ret*(1.-(1.-lt)*f),(1.-lt)*f*dark*(1.-lt));
    ret=max(ret,strucb(uv,timer));
    f*=animendfade(timer);
    return max(dark,ret*animendfade(timer));
}

float animm(float timer) {
    return smoothstep(animstart,animstart+1.5,timer);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 res = iResolution.xy / iResolution.y;
    vec2 uv = (fragCoord.xy) / iResolution.y - res/2.0;
    float Range = 10.;
    float timer=mod(iTime,15.);
    float Line_Smooth	= animm(timer)*
                          pow(smoothstep(Range,Range-.05,2.*Range*(abs(smoothstep(.0, Range,uv.x+.5 )-.5))),.2);

    float ft=2000.;
    float fx=rand(uv.x*.0031+.0005);
    float am  =0.5000 * noise(fx, ft)
                       +0.2500 * noise(fx, ft)
                       +0.1250 * noise(fx, ft)
                       +0.0625 * noise(fx, ft);

    vec2 p=uv;
    p.y+=((cos(.5*p.x-0.15))-.975)*animm(timer);
    float lt  = line(vec2(p.x,p.y*2.+(am-.5)*.12*Line_Smooth), .005, .0, 2./iResolution.y);

    vec3 line1 =  lt*dark;

    vec3 retcol=vec3(0.);
    retcol=postfx(uv,map(uv,lt,timer),0.75);
    fragColor =vec4(retcol,1.);
}