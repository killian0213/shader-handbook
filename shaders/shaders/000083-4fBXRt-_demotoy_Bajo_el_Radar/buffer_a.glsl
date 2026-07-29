// Buffer A (buffer) — [demotoy] Bajo el Radar by Kali
// https://www.shadertoy.com/view/4fBXRt

#define PI 3.14159
#define resolution iResolution.xy
#define mouse 1.
#define time iTime
#define vTexCoord (gl_FragCoord.xy/iResolution.xy)

float det=.01;
vec3 shipos;
vec3 advship;

float dot2( in vec2 v ) { return dot(v,v); }
float dot2( in vec3 v ) { return dot(v,v); }
float ndot( in vec2 a, in vec2 b ) { return a.x*b.x - a.y*b.y; }

mat3 lookat(vec3 dir) {
	dir=normalize(dir);vec3 rt=normalize(cross(dir,vec3(0.,1.,0.)));
    return mat3(rt,cross(rt,dir),dir);
}

vec3 path(float t) {
    vec3 p = vec3(sin(t*.01+cos(t*.02))*20., 20.*smoothstep(-.5,.5,sin(t*.01)), t);
    p.xy*=smoothstep(12.,15.,time);
    p.xy*=smoothstep(43.,38.,time)+.2;
    return p;
}

float hash(vec2 p)
{
    p=floor(p*1000.);
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float rnd(float p)
{
    p*=1234.;
    p = fract(p * .1031);
    p *= p + 33.33;
    return fract(2.*p*p);
}

mat2 rot(float a)
{
    float s=sin(a),c=cos(a);
    return mat2(c,s,-s,c);
}

float sdCappedCone( vec3 p, float h, float r1, float r2 )
{
  vec2 q = vec2( length(p.xz), p.y );
  vec2 k1 = vec2(r2,h);
  vec2 k2 = vec2(r2-r1,2.0*h);
  vec2 ca = vec2(q.x-min(q.x,(q.y<0.0)?r1:r2), abs(q.y)-h);
  vec2 cb = q - k1 + k2*clamp( dot(k1-q,k2)/dot2(k2), 0.0, 1.0 );
  float s = (cb.x<0.0 && ca.y<0.0) ? -1.0 : 1.0;
  return s*sqrt( min(dot2(ca),dot2(cb)) );
}

float sdRoundedCylinder( vec3 p, float ra, float rb, float h )
{
  vec2 d = vec2( length(p.xz)-2.0*ra+rb, abs(p.y) - h );
  return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rb;
}

float sdHexPrism( vec3 p, vec2 h )
{
  const vec3 k = vec3(-0.8660254, 0.5, 0.57735);
  p = abs(p);
  p.xy -= 2.0*min(dot(k.xy, p.xy), 0.0)*k.xy;
  vec2 d = vec2(
       length(p.xy-vec2(clamp(p.x,-k.z*h.x,k.z*h.x), h.x))*sign(p.y-h.x),
       p.z-h.y );
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdVerticalCapsule( vec3 p, float h, float r )
{
  p.y -= clamp( p.y, 0.0, h );
  return length( p ) - r;
}

float opSmoothUnion( float d1, float d2, float k )
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}

float opSmoothSubtraction( float d1, float d2, float k )
{
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h);
}

vec3 fcol;
float l;
float fractal(vec2 p) {
    float m=100.; 
    l=100.;
    vec2 c=vec2(100.);
    p*=.35;
    p.y*=.7;
    p.y-=.5;
    p.x=abs(p.x);
    for (int i=0; i<5; i++) {
    	p=abs(p+.75)-abs(p-.75)-p;
        p+=vec2(0.,2.);
        p=p*2.5/clamp(dot(p,p),.2,1.)-1.5;
        l=min(l,min(abs(p.x),abs(p.y)));
        m=min(m,abs(p.x));
        c=min(c,abs(p));
    }
    l=exp(-10.*l);
    fcol=l*vec3(c.y,length(p)*.03,c.x)*abs(.5-fract(p.y*.1-time))*20.;
    return l;
}

float dpla=100.;
float plasma(vec3 p) {
    vec3 ps=p;
    p.z-=3.;
    float d=length(p*vec3(.6,1.,1.))-.3;
    p.x=abs(p.x)-1.3+max(0.,sign(p.y-.5))*.5;
    p.y=abs(p.y-.5)-.3;
    p.z+=.4;
    d=min(d,length(p)-.15)-sin(time*70.)*.03;
    p.z+=1.3;
    p.xy*=rot(time*30.);
    float hel=abs(p.x);
    hel=max(hel,abs(p.y)-.1);
    hel=max(hel,abs(p.z)-1.);
    d=min(d,hel);
    dpla=d;
    return d;
}


float turbinas(vec3 p) {
    p.yz*=rot(PI/2.);
    p.x=abs(p.x)-1.3-min(0.,sign(p.z+.5))*.5;
    p.z=abs(p.z+.5)-.3;
    p.y-=1.5;    
    float d=sdRoundedCylinder(p, 0.2, .2 ,1.);
    d=max(d,-length(p.xz)+.3);
    return d;
}


float wings(vec3 p) {
    p.yz*=rot(PI/2.);
    p.z+=.2;
    p.z-=abs(p.x)*.1;
    p.y*=3.;
    p.y-=3.+abs(p.x);
    p.z+=.5;
    float d=sdHexPrism(p, vec2(3.,-.05-abs(p.x)*.03))-.2+l*.05;
    d=max(d,abs(p.x)-3.);
    p.y+=p.z*2.;
    d=min(d,max(abs(p.z+.5)-1.,max(abs(p.x)-.05,abs(p.y)-1.5)));
    return d*.5;
}


float id_fus;
float fuselaje(vec3 p) {
    float f=fractal(p.xz);
    p.yz*=rot(PI/2.);
    p.y*=.7;
    vec3 ps=p;
    p.xz*=1.+smoothstep(-3.,3.,p.y)*.5;
    p.xz*=1.+smoothstep(1.,3.,p.y);
    p.x=abs(p.x)-.4;    
    p.x+=smoothstep(-0.,-3.,p.y)*.4;
    p.z-=smoothstep(-0.,-4.,p.y)*.5;
    p.z+=smoothstep(-2.,2.,p.y)*sign(p.z)*.4;
    p.x+=smoothstep(1.5,1.,abs(p.y-1.))*.7;
    p.x*=1.-smoothstep(0.5,1.,p.z)*.5*smoothstep(2.,1.,p.y);
    float base=sdCappedCone(p, 2.2, 0.1, 2.)-.1+f*.02;
    base=max(base,-length(p.xz)+2.*smoothstep(0.,3.,p.y))*.7;
    base=max(base,p.y-2.2);
    p=ps;
    p.x*=1.+smoothstep(0.,-2.,p.y)*.3;
    p.z+=1.+p.y*.6;
    p.y+=1.3;
    float cabin=sdVerticalCapsule(p, 1., .7)+f*.01;
    cabin=max(cabin,-base);
    p=ps;
    p.x*=1.-smoothstep(-3.,3.,p.y)*.5;
    p.z+=1.+p.y*.2;
    p.z-=smoothstep(0.,3.,p.y);
    p.z+=smoothstep(.2,0.,abs(p.x))*.2;
    float turbo=sdVerticalCapsule(p, 1.5, .6)+sqrt(f)*.1;
    float d=min(base,cabin);
    d=min(d, turbo);
    if (d==base) id_fus=0.;
    if (d==turbo) id_fus=1.;
    if (d==cabin) id_fus=2.;
    return d*.5;
}

float id;
vec3 pos;
float spaceship(vec3 p) {
    p-=shipos;
    float bou=length(p)-4.;
    if (bou>0.) return bou+.1;
    p=lookat(advship)*p;
    p.xy*=rot(advship.x);
    p.xz*=rot(-advship.x*.3);
    p.z*=.8;
    pos=p;
    id=0.;
    float fuse=fuselaje(p);
    float win=wings(p);
    float tur=turbinas(p);
    float pla=plasma(p);
    float d=opSmoothUnion(fuse,win,.2);
    if (abs(d-win)<.1) id=1.; 
    d=min(d,tur);
    d=min(d,pla);
    if (d==tur) id=2.;
    if (d==pla) id=3.;
    return d;
}

vec3 ot;
vec3 pomo;
float id2;
float mothership(vec3 po) {
    id2=0.;
    ot=vec3(100.);
    po.x-=10.;
    po.y+=40.*smoothstep(10.,0.,time);
    po.y+=10.*smoothstep(23.,25.,time);
    po.xy-=path(po.z).xy;
    if (po.y>34.) return po.y;
    vec3 pp=po;
    pomo=pp;
    po*=.1;
    po.z=abs(5.-mod(po.z,10.));
    vec4 p=vec4(po,1.5);
    float end=smoothstep(46.,41.,time);
    for (int i=0; i<6; i++) {
		p.xz = abs(p.xz+1.)-abs(p.xz-1.)-p.xz;
		p=p*2./clamp(dot(p.xyz,p.xyz),.15,1.)-vec4(end+.5,.5,1.-end,0.);
		p.xy*=rot(.8*end);
        p.yz*=rot(smoothstep(23.,27.,time)*end);
        ot=min(ot,abs(p.xyz));
    }
    float fr=max(-po.x-4.,(length(max(vec2(0.),p.yz-3.)))/p.w);
	pp.y-=0.;
    pp.x+=10.;
    pp.x=abs(pp.x)-12.;
    float tub=length(pp.xy)-.5;
    tub*=.3;
    float d=min(fr, tub);
    if (d==tub) id2=1.;
    d=min(d,max(-abs(po.x+1.)+4.,po.y+sin(po.x*.5)+cos(po.z)));
    return d/.1*.5;
}

float cual;
float de(vec3 p) {
    cual=0.;
    vec3 p1=p;
    p1.y+=5.;
    float ship=spaceship(p);
    float moth=mothership(p1);
    float d=min(ship,moth);
    if (d==moth) cual=1.;
    return d;
}

vec3 normal(vec3 p)
{
    vec2 e=vec2(0.,det);
    return normalize(vec3(de(p+e.yxx),de(p+e.xyx),de(p+e.xxy))-de(p));
}

vec3 march(vec3 from, vec3 dir) 
{
    vec3 skycol=vec3(.1,.3,.5)*smoothstep(.5,-.2,dir.y)*1.3;    
    vec3 tdir=dir;
    if (time<17.||time>39.) {
        float j=smoothstep(11.,7.,time)+.1+smoothstep(15.,17.,time)*.2+step(47.,time)-smoothstep(47.,53.,time)*1.2;
        float tt=(step(46.,time)*fract(time*2.*step(52.,time)))*480000.;
        float ty=smoothstep(13.,17.,time)*.1;
        skycol+=pow(max(dot(tdir, normalize(vec3(.3*j,0.15-ty,-1.))),0.),500000.-tt);
        skycol+=pow(max(dot(tdir, normalize(vec3(-.25*j,0.15-ty,-1.))),0.),500000.-tt);
        skycol+=pow(max(dot(tdir, normalize(vec3(-.1*j,0.2-ty,-1.))),0.),500000.-tt);
    }
    vec3 shipcol=vec3(.6,0.,0.);
    vec3 plasmacol=vec3(1.5,1.,.5)*.9;
    vec3 mothcol=vec3(.2,.4,.6);
    float td=0.,d=.01,maxdist=300.,g=0.;
    vec3 p=from,col=skycol;
    for (int i=0; i<500; i++)
    {
        p+=dir*d;
        d=de(p);
        if (d<det || td>maxdist) break;
        td+=d;
        g+=exp(-15.*dpla)*.1;
    }
    vec3 ldir=normalize(vec3(.3,2.,-1.));
    vec3 n=normal(p);
    vec3 ref=reflect(dir,n);

    if (d<det) 
    {
        if (cual==0.) {
            if (id==0.) {
                fcol=fcol.bgr, col+=fcol*.7;
                if(id_fus==0.||id_fus==1.) {
                    col=shipcol;
                    col+=fcol*.25;
                    col+=smoothstep(.06,.04,abs(pos.x))*.8;
                    col+=smoothstep(.06,.04,abs(abs(pos.x)-.8-pos.z*.12))*step(.4,pos.y)*.8;
                }
                if(id_fus==2.) {
                    col=vec3(.1)+fcol*.3;
                    col+=pow(max(0.,dot(ldir,ref)),50.)*skycol;
                }
            }
            if (id==1.) {
                col=shipcol+fcol*.1;
            }
            if (id==2.) {
                col=shipcol;
            }
            if (id==3.) {
                col=plasmacol;
            } else {
                col*=max(.3,dot(ldir,n));
                col+=pow(max(0.,dot(ldir,ref)),20.)*.5;
            }
        } else {
            ot=exp(-10.*ot);
            col=mothcol-(ot.rrr+ot.ggg+ot.bbb)/3.+skycol*-max(0.,-n.y);
            col.r+=ot.g*1.3;
            col.g+=ot.g*.2;
            col*=max(.2,dot(ldir,n))*.8;
            col+=pow(max(0.,dot(ldir,ref)),20.)*.5;            
            pomo.x=abs(pomo.x+10.)-10.;
            if (id2==1.) col=pow(mothcol*1.4,vec3(2.))*1.5;
            else col+=0.*exp(-3.*abs(pomo.x))*mothcol;
        }
    }
    else
    {
        td=maxdist;

    };
    if (!(cual==1.&&id2==1.)&&td!=maxdist) col=mix(col,skycol,td/maxdist);
    col+=g*plasmacol;
    return col;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float t=time*50.;
    vec2 uv = vTexCoord-.5;
    uv.x*=resolution.x/resolution.y;
    float fov=.3+smoothstep(0.,10.,time)*2.5;
    fov-=smoothstep(7.,9.,time);
    fov-=smoothstep(18.,21.,time)*step(time,21.);
    fov-=smoothstep(39.,40.,time)*.5;
    fov-=smoothstep(48.,52.,time)*.7;
    vec3 dir=normalize(vec3(uv,fov));
    vec3 from=path(t+0.);
    if (time<12.||time>39.) from=path(t+40.);
    if (time>15.&&time<19.) from=path(floor(t/250.)*250.+125.);
    if (time>31.&&time<39.) from=path(floor(t/250.)*250.+125.);
    if (time>42.5&&time<45.) from=path(floor(t/250.)*250.+125.);
    from.y+=5.+sin(time*.5-2.*step(21.,time))*7.*step(time,50.)-6.*step(50.,time);
    from.x+=6.;
    vec3 adv=path(t+20.);
    shipos=adv;
    advship=normalize(shipos-path(t+25.));
    shipos.z+=30.*smoothstep(49.,52.,time);
    shipos.y+=20.*smoothstep(49.5,52.,time);
    dir=lookat(adv-from)*dir;
    dir.xz*=rot(-.2*smoothstep(6.,8.,time)*smoothstep(12.,10.,time));
    dir.yz*=rot(-.2*smoothstep(6.,8.,time)*smoothstep(12.,10.,time));
    dir.yz*=rot(-.2*step(15.,time)*smoothstep(17.,16.,time));
    vec2 m=mouse/resolution-.5;
    vec3 col=march(from, dir);
    col=mix(col,texture(iChannel0,vTexCoord).rgb,cual==0.?.6:.4);
    fragColor = vec4(col,1.0);
}
