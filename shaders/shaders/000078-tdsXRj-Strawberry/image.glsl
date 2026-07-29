// Image (image) — Strawberry by EvilRyu
// https://www.shadertoy.com/view/tdsXRj

// Created by EvilRyu
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.


float hash11(float p)
{
	vec2 p2 = fract(vec2(p * 5.3983, p * 5.4427));
    p2 += dot(p2.yx, p2.xy + vec2(21.5351, 14.3137));
	return fract(p2.x * p2.y * 95.4337);
}

float hash13(vec3 p)
{
    p=fract(p*vec3(5.3983,5.4472,6.9371));
    p+=dot(p.yzx,p.xyz+vec3(21.5351,14.3137,15.3219));
    return fract(p.x*p.y*p.z*95.4337);
}

float sphere(vec3 p, float r)
{
    return length(p)-r;
}

float box(vec3 p, vec3 b)
{
  	vec3 d=abs(p)-b;
  	return min(max(d.x,max(d.y,d.z)),0.0)+length(max(d,0.0));
}

float cylinder(vec3 p, vec2 h)
{    
  	vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  	return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

void basis(vec3 n, out vec3 b1, out vec3 b2) 
{
    if(n.y<-0.999999) 
    {
        b1=vec3(0,0,-1);
        b2=vec3(-1,0,0);
    } 
    else 
    {
    	float a=1./(1.+n.y);
    	float b=-n.x*n.z*a;
    	b1=vec3(1.-n.x*n.x*a,-n.x,b);
    	b2=vec3(b,-n.z,1.-n.z*n.z*a);
    }
}

void rot2d(inout vec2 p, float t)
{
    float ct=cos(t),st=sin(t);
    vec2 q=p;
	p.x=ct*q.x+st*q.y;
    p.y=-st*q.x+ct*q.y;
}

float smin(float a, float b, float k)
{
    float h=clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
    return mix(b,a,h)-k*h*(1.0-h);
}

float smax(float a, float b, float k)
{
    return smin(a,b,-k);
}

const float PI=3.14159265359;
const float PHI=1.61803398875;

// from iq: https://www.shadertoy.com/view/lllXz4
vec4 invsf(vec3 p, float n)
{
    float m=1.-1./n;
    float phi=min(atan(p.y,p.x),PI);
    float k=max(2.,floor(log(n*PI*sqrt(5.)*
                             (1.-p.z*p.z))/log(PHI+1.)));
    float Fk=pow(PHI,k)/sqrt(5.);
    vec2  F=vec2(round(Fk), round(Fk*PHI));
    vec2 ka=2.*F/n;
    vec2 kb=2.*PI*(fract((F+1.)*PHI)-(PHI-1.));    
    mat2 iB=mat2(ka.y,-ka.x, 
                    kb.y,-kb.x)/(ka.y*kb.x-ka.x*kb.y);
    
    vec2 c=floor(iB*vec2(phi, p.z-m));
    float d=0.;
    vec4 res=vec4(0);
    for(int s=0; s<4; s++) 
    {
        vec2 uv=vec2(s&1,s>>1);
        float i=dot(F,uv+c); 
        float phi=2.*PI*fract(i*PHI);
        float ct=m-2.*i/n; //costheta
        float st=sqrt(1.-ct*ct); //sintheta
        
        vec3 q=vec3(cos(phi)*st, 
                    sin(phi)*st, 
                    ct);
        float d1=dot(p,q);
        if(d1>d) 
        {
            d=d1;
            res=vec4(q,d);
        }
    }
    return res;
}

vec4 texcube(sampler2D sam, vec3 p, vec3 n)
{
    vec4 p1=textureLodOffset(sam, p.xy-vec2(.14), 1.5, ivec2(2));
    vec4 p2=textureLod(sam, p.xz, 0.);
    vec4 p3=textureLod(sam, p.yz, 1.5);
    return p1*abs(n.z)+p2*abs(n.y)+p3*abs(n.x);
}

float id=0.;

vec4 get_eye_params(vec3 p)
{
    vec3 r,f;
    vec4 fibo=invsf(normalize(p),88.3);
    vec3 q=p-fibo.xyz;
    vec3 n=normalize(fibo.xyz);
    basis(n,r,f);
    q=vec3(dot(r,q),dot(n,q),dot(f,q));
    rot2d(q.xz,hash13(fibo.xyz)*7.);
    return vec4(q,0.1+0.088*hash13(fibo.xyz+vec3(13.399,71.137,151.11)));
}

vec3 deform(vec3 p)
{
    vec3 q=p;
    q*=1.-(smoothstep(0.,1.,q.y)-smoothstep(1.,2.,q.y)*3.)*0.16;
    q*=1.-(smoothstep(0.,.45,q.y)-smoothstep(.45,.9,q.y))*0.07;
    q.xz*=(1.-smoothstep(-.6,0.2,q.y))*.2+1.;
    q.y*=0.8;
    return q;
}

vec2 polar_rep(vec2 p, float n)
{
    n=PI*0.5/n;
    float a=atan(p.y, p.x);
    float r=length(p);
    a=mod(a+n/2.0, n)-n/2.0;
    p=r*vec2(cos(a), sin(a));
    return 0.5*(p+p-vec2(1,0));
}

float leaf(vec3 p)
{
    vec3 q=p;  
    q.xz=polar_rep(q.xz,2.5);
    q.y+=0.1*sin(q.x*6.);
    vec3 q1=q;
    q.z=abs(q.z)+0.6;
    float d=cylinder(q,vec2(0.7,0.01));
    float d1=box(q1-vec3(0.,0.01,0.),vec3(0.45,0.013,0.001));
    d=smin(d,d1,0.05);
    p.x+=0.1*sin(p.y*4.0);
 	p.x-=0.05;
    d1=cylinder(p,vec2(0.04,0.7));
    d=smin(d,d1,0.3);
    return d;
}

float map(vec3 p)
{
    float lea=leaf(p.xyz-vec3(0.,1.32,0.));
    p=deform(p);
    float d0=sphere(p,1.)-0.1*texcube(iChannel0, p*0.45, normalize(p)).x;
    vec4 q=get_eye_params(p);
    float d1=sphere(q.xyz+vec3(0.,(-0.188+q.w)*.8,0.),q.w*.8);
    d0=smin(d0,d1,0.09);
    
    float a=mod(iTime*q.w*1.3,1.);
    d1=sphere(vec3(q.x,q.y-0.188+q.w*(smoothstep(0.,.1,a)-smoothstep(0.9,1.,a)),
                   abs(q.z)+q.w*0.35),
              q.w*0.7);
    d0=smax(d0,-d1,0.09);
    d1=sphere(q.xyz+vec3(0.,-0.09+q.w,0.),q.w);
    
    if(d0>d1){d0=d1;id=1.;}
    if(d0>lea){d0=lea;id=2.;}
    
    return d0;
}

vec3 get_normal(vec3 p)
{
    vec3 eps=vec3(0.001,0,0);
    return normalize(vec3(map(p+eps.xyz)-map(p-eps.xyz),
                     map(p+eps.yxz)-map(p-eps.yxz),
                     map(p+eps.yzx)-map(p-eps.yzx)));
}

#define FAR 30.0
float intersect(vec3 ro, vec3 rd)
{
    float t=0.1;
    float d=0.;
   	for(int i=0;i<96;++i)
    {
        d=map(ro+t*rd);
        if(d<0.003&&t>FAR)
        	break;
        t+=d;
    }
        
    return t;
}

float noise(vec2 x)
{
    vec2 p=floor(x);
    vec2 f=fract(x);
    f=f*f*(3.0-2.0*f);
    float n=p.x + p.y*57.0;
    return mix(mix(hash11(n+0.0), hash11(n+1.0),f.x),
               mix(hash11(n+57.0), hash11(n+58.0),f.x),f.y);
}
const mat2 m=mat2(0.8,0.6,-0.6,0.8);


float fbm(vec2 p)
{
    float f=0.0;
    f+=.5*noise(p); p=m*p*2.;
    f+=.25*noise(p); p=m*p*2.;
    f+=.125*noise(p); p=m*p*2.;
    f+=.0625*noise(p); p=m*p*2.;
    f+=.03125*noise(p);
    return f/0.984375;
}

float trace_sphere(vec3 ro, vec3 rd, vec4 sph)
{
    vec3 p=sph.xyz;
    float t=-1.0;
    vec3  ce=ro-p;
    float b=dot(rd, ce);
    float c=dot(ce, ce)-sph.w*sph.w;
    float h=b*b - c;
    if(h>0.0)
    {
        t=-b-sqrt(h);
    }
    
    return t;
}

float get_ao(vec3 p, vec3 n)
{
    float r=0.0, w=1.0, d;
    for(float i=1.; i<5.0+1.1; i++)
    {
        d=i/5.0;
        r+=w*(d-map(p+n*d));
        w*=0.5;
    }
    return 1.0-clamp(r,0.0,1.0);
}

vec3 get_material(vec3 ro, vec3 rd, vec3 p)
{
    if(id<1.)
    {
    	//return vec3(0.82,0.055,0.027)*0.4;   // real strawberry color  
        return vec3(0.984,0.352,0.551)*0.75;
    }
    else if(id>1.1)
    {
        return vec3(0.05,0.15,0.);
    }
    
	p=deform(p);
    vec4 eyes=get_eye_params(p);

    vec3 col=vec3(1.);
	vec2 uv=vec2(eyes.xz);
    float r=length(uv);
    if(r<eyes.w*.13)
    {
        col=vec3(0.01);
    }
    else if(r<eyes.w*.3)
    {
        col=mix(vec3(.9,.8,.3)*.5,vec3(.01), fbm(50.*uv));
    }
	col=mix(col,vec3(0.2,0.,0.)*fbm(50.*uv),
            smoothstep(eyes.w*.35, eyes.w*.6, r));
   
    return col;
}

float sss(vec3 p, vec3 n, float d, float i) 
{ 
    float o,v; 
    for(o=0.;i>0.;i--) 
        o+=(i*d+map(p+n*i*d))/exp2(i); 
    return o; 
}

float shadow(vec3 ro, vec3 rd)
{
    float s = 1.0,t = 0.01,h = 1.0;
    for( int i=0; i<16; i++ )
    {
        h = map(ro + rd*t);
        s = min( s, 16.*h/t );
        if( s<0.0001 ) break;
        t += clamp( h, .01, .05 );
    }
    return clamp(s,.0,1.);
}

vec3 lighting(vec3 ro, vec3 rd, vec3 n, float t, vec3 p)
{
    vec3 ld0=normalize(vec3(1,1.5,-1.7));
    
    float dif=max(0.,dot(ld0,n));
    float spe=pow(max(0.,dot(rd,reflect(ld0,n))), 24.0);
    float bac=max(0.,dot(-ld0,n));
    float amb=clamp(0.3+0.7*n.y,0.0,1.0);
    float sca=sss(p,-n,.5,10.);
    float fre=clamp(1.-dot(n,-rd),0.,1.);
    id=0.;
    float d=map(p);
    vec3 mate=get_material(ro,rd,p);
    
    float ao=get_ao(p,n);
    float sha=shadow(p,ld0);
    
    vec3 col=(4.0*dif*sha+0.5*bac+1.*amb*sha+fre*fre*fre*10.*sha)*mate*ao*ao+1.5*spe*sha;
    col+=2.*mate*sca;
    col*=0.2;
    return col;
}

vec3 tonemap(vec3 x) 
{
    const float a=2.51;
    const float b=0.03;
    const float c=2.43;
    const float d=0.59;
    const float e=0.14;
    return (x * (a * x + b)) / (x * (c * x + d) + e);
}

vec3 bg(vec2 p)
{
    vec2 po;
    po.x=atan(p.y, p.x);
    po.y=length(p)-iTime*0.4;
    float d=length(p);
    vec3 col=vec3(d,d*.5,d*.7);
    float c=pow(fbm(po*5.),5.)*(1.-(smoothstep(0.,0.01,d)-smoothstep(.4,1.,d)))
        	*max(0.,1.5-d);
    col-=vec3(c*4.,c*7.,c*3.)*.2;
    return clamp(col,0.,1.);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 q = fragCoord/iResolution.xy;
    vec2 p=q*2.0-1.;
    p.x*=iResolution.x/iResolution.y;

    vec3 ro=vec3(0,0.7,-6);
    vec3 ta=vec3(0,0,0);
     // debugging camera
    float x_rot=-iMouse.x/iResolution.x*PI*2.0;
    float y_rot=iMouse.y/iResolution.y*3.14*0.5 + PI/2.0;
    if(iMouse.z>0.||iMouse.w>0.)
    	ro=vec3(0.,0,-3)+vec3(cos(y_rot)*cos(x_rot),cos(y_rot)*cos(x_rot),cos(y_rot)*sin(x_rot))*5.;
     
    vec3 f=normalize(ta-ro);
    vec3 r=normalize(cross(vec3(0,1,0),f));
    vec3 u=normalize(cross(f,r));
    
    vec3 rd=normalize(mat3(r,u,f)*vec3(p.x,p.y,2.8));
    
    vec3 col=bg(p);
    
    float t=trace_sphere(ro,rd,vec4(0.,0.,0.,2.));
    if(t>0.&&t<1000.)
    {
        float t=intersect(ro,rd);
        if(t<FAR)
        {
            vec3 pos=ro+t*rd;
            vec3 n=get_normal(pos);
   	        col=lighting(ro, rd,n,t,pos);
    	}
    }
    
	col=tonemap(col);
    col=pow(clamp(col,0.0,1.0),vec3(0.45));
    col*=0.5+0.5*pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.7);  // vigneting
    fragColor = vec4(col,1.0);
}