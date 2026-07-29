// Buffer A (buffer) — TV Scene, wall of TV by morimea
// https://www.shadertoy.com/view/4fffR7




// mix of two+1 my shaders - texture
// https://www.shadertoy.com/view/sldGDf
// https://www.shadertoy.com/view/DlByW1
// https://www.shadertoy.com/view/4tKczz


// this shader reveal new AMD bug
// https://gitlab.freedesktop.org/mesa/mesa/-/issues/11683
// https://github.com/danilw/GPU-my-list-of-bugs
 

void mainImage_col2( out vec4 fragColor, in vec2 fragCoord );
void mainImage_col1( out vec4 fragColor, in vec2 fragCoord );
void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    mainImage_col1(fragColor, fragCoord);
    float ta = fragColor.r;
    mainImage_col2(fragColor, fragCoord);
    fragColor.a = ta;
}




// modified https://www.shadertoy.com/view/DlByW1
//-----------------------------

// Created by Danil (2023+) https://cohost.org/arugl

// License - CC0 or use as you wish

// self https://www.shadertoy.com/view/DlByW1


#define local_iTime (iTime*2.25)


// using FabriceNeyret2 runes (simplified version) 
// https://www.shadertoy.com/view/4ltyDM

//--------------------------------------

// --- glyphs simplified from "runes" by otaviogood. 
// https://shadertoy.com/view/MsXSRn - original is CC0

float line(vec2 p, vec2 a,vec2 b) {
    p -= a, b -= a;
	float h = clamp(dot(p, b) / dot(b, b), 0., 1.);
	return length(p - b * h);
}
/*
vec2 hash22(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}

float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}*/

float Rune(vec2 U, vec2 seed, float px)
{
	float d = 1e5;
    float h = hash12(seed.xy*33.);
    int rn = int(h*h*h*6.);
    for (int i = 0; i < 1+rn; i++)
    {
        vec4 pos = vec4(hash22(seed).xy,hash22(seed+1.).xy );
        seed += 2.;
        pos = fract(pos * 128.);
        if (i == 0) pos.y = .0;
        if (i == 1) pos.x = .999;
        if (i == 2) pos.x = .0;
        if (i == 3) pos.y = .999;
        vec4 snaps = vec4(2, 3, 2, 3);
        pos = ( floor(pos * snaps) + .5) / snaps;	
        d = min(d, line(U, pos.xy, pos.zw + .001) );
    }
	return 1.-smoothstep(40./360.-px,40./360.,d);
}
//--------------------------------------







// right top

//--------------------------------------
// from my old shader https://www.shadertoy.com/view/4lKyDd
// updated Fabrice version





void mainImage_col3(out vec4 fragColor, in vec2 fragCoord);
void mainImage_lt( out vec4 fragColor, in vec2 fragCoord, float ts);
void mainImage_rt(out vec4 O,vec2 u){
    //mainImage_lt(O, u, 235.);
    mainImage_col3(O, u);

}




/*
void mainImage_rt(out vec4 O,vec2 u){
    O=vec4(0.);
    vec2 T =  1./vec2(62.5,31.),
         R = iResolution.xy,
         U = (u -.5*R) / R.y,
         p = mod( U-T/2., T) - T/2.,
         r = R / R.y, c=r/T;
    float t = local_iTime*4.+14.;
    int x = int(c),
        i = int( t*8. + 3.5*( cos(t/1.5) - cos(t) ) ) % ( x*int(c.y) );
    r = vec2( i%x, i/x ) - ceil( (r/2. + vec2(U.x,-U.y) ) / T );
    r.y>0. || r.y==0. && r.x>0.
       ? O += 1. - ( .98 < fract(1e4*sin(dot(ceil(U/T-.5),vec2(591,154))))
                        ? p = abs(p), max( max(p.x,p.y)-.0051, min(p.x,p.y) )
                        : length(p+T*vec2(0.,.25)) - .001
                   ) / .003
       : O;
}*/
//--------------------------------------





// left bot

//--------------------------------------

void mainImage_lb( out vec4 fragColor, in vec2 fragCoord)
{

    vec2 res=iResolution.xy/iResolution.xy;
    vec2 uv=fragCoord/iResolution.xy-0.5*res;
    
    float px = 1.5/iResolution.y;
    vec4 c=vec4(0.);
    
    float sc = 25.;
    vec2 tuv = (uv+res*0.5)*sc;
    vec2 lid = floor(tuv);
    vec2 alid = floor(res*sc);
    vec2 olid = lid;
    tuv = fract(tuv)-0.5;
    
    float t = (local_iTime*5.+178.)*0.1+22.51;
    float x = step(tuv.y+0.35,0.)*step(0.,abs(tuv.x+0.5)-0.15);
    x*=step(fract(t*9.85+(lid.x-lid.y+alid.y*2.)*0.33),(olid.y<0.5?0.65:0.25)-0.15*sin(lid.x*5.35));
    float ttl = t + .4*(cos(t/1.5) - cos(t));
    lid.y=-lid.y+2.*alid.y;
    lid.y+=floor(ttl);
    ttl = fract(ttl);
    float s = 0.;
    float r = smoothstep(0.,px*sc,length(tuv)-0.35);
    float vid = mod(lid.y,12.);
    if(vid>0.5){
        vec2 lp = tuv;
        s = 1.-max(smoothstep(0.,px*sc,min(abs(lp.y)*1.75, abs(-abs(lp.y)+abs(lp.x*1.5)))-0.065),r);
        bool ra = cos(lid.x*0.15)>-0.75;
        bool rb = !ra&&cos(lid.x*1.5)>-0.95&&floor(mod(lid.y,4.))!=0.;
        bool rc = ra&&cos(lid.x*0.22)<-0.05&&cos(lid.x*4.80)>-0.0&&sin(lid.y*0.57+lid.x*0.33)<-0.05;
        float h = hash12(lid.xy*33.);
        ra=ra&&(vid>=mod(lid.x+1.,15.)*4.||mod(lid.x-15.,30.)>4.)&&floor(mod(lid.y,4.))==1.+floor(mod(lid.y,12.)/4.);
        vec2 tid = lid;
        if(rb){
            tid.y = floor(mod(tid.y/1.65,3.))+10.*floor((tid.y/3.));
            bool rb1 = cos(lid.x*1.5)>0.75;
            if(rb1){
                tid.y += 33.*(1.-abs(sign(floor(mod(lid.y,4.))-2.)));
            }
        }
        bool rg = ra||rb||rc;
        s = (lid.x>1.&&lid.x<13.)?s*step(lid.x-1.,vid):((lid.x>0.&&lid.x<14.)?
            (1.-r)*step(abs(lp.x)-0.065,0.)+step(sign(lid.x-5.)*lp.x-0.065,0.)*step(abs(lp.x)-0.065*3.,0.)*step(abs(abs(lp.y)-0.5+0.065*2.)-0.065,0.):
            (rg?Rune(lp+0.5, tid, 1./200.*sc):0.));
        if(olid.y==1.&&lid.x>13.&&rg){float tdx=(alid.x+13.)*smoothstep(0.,.8,ttl);s=mix(x*(step(olid.x-3.,max(13.,tdx))),s,step(olid.x,tdx));}
        else if(olid.y==0.){float tx=floor(14.*smoothstep(.4+0.15*sin(lid.y*2.33),.6,ttl*ttl));s=lid.x==tx?x:(lid.x<14.?s*step(lid.x,tx):0.);}
    }else{
        s = 1.-max(smoothstep(0.,px*sc,abs(abs(tuv.y)+tuv.x)-0.065),r);
        if(olid.y<0.5)s*=step(0.55,ttl);
        vec2 tid = lid;
        tid.y=tid.y*step((sin(tid.x*0.15)+2.*cos(tid.x*0.75)),0.);
        bool ra = step(tid.x,8.)>0.5;
        bool rb = step(10.,tid.x)*step(tid.x,12.+mod(lid.y,7.))>0.5;
        bool rg = ra||rb;
        s=lid.x>0.5?(rg?Rune(tuv+0.5, tid, 1./200.*sc):0.):s;
        if(olid.y<0.5){float ttl=rg||ttl<0.65?smoothstep(.3,.65,ttl*ttl):((alid.x-2.)/alid.x);float ts=step(olid.x,alid.x*ttl);s=(s*ts+step(0.01,ttl)*x*(1.-ts)*step(olid.x-1.,alid.x*ttl));}
    }
    s*=step(72.,lid.y);
    c=vec4(clamp(s,0.,0.88));
    
    fragColor = vec4(c.rgb,1.0);
}
//--------------------------------------




//left top

//--------------------------------------
// Rune reused from above

void mainImage_lt( out vec4 fragColor, in vec2 fragCoord, float ts)
{

    vec2 res=iResolution.xy/iResolution.y;
    vec2 uv=fragCoord/iResolution.y-0.5*res;
    
    float px = 1.5/iResolution.y;
    vec4 c=vec4(0.);
    
    float sc = 25.;
    vec2 tuv = (uv+res*0.5)*sc;
    vec2 lid = floor(tuv);
    vec2 alid = floor(res*sc);
    vec2 olid = lid;
    tuv = fract(tuv)-0.5;
    
    float s = 0.;
    float r = smoothstep(0.,px*sc,length(tuv)-0.35);
    
    float t = (local_iTime+ts+178.)*0.075+0.005;
    float x = step(tuv.y+0.35,0.)*step(0.,abs(tuv.x+0.5)-0.15);
    float l = step(abs(tuv.x)-0.075,0.)*(1.-r);
    x*=step(fract(t*17.85+(lid.x-lid.y+alid.y*2.)*0.33),(olid.y<0.5?0.65:0.25)-0.15*sin(lid.x*5.35));
    
    float ttl = t + .4*(cos(t/1.5) - cos(t));
    lid.y=-lid.y+2.*alid.y;
    lid.y+=25.+26.*floor(ttl/5.);
    ttl = fract(ttl/5.);
    
    vec2 lp = tuv;
    float ra = step(lid.x,0.)*step(25.,mod(lid.y,26.));
    s = ra*(1.-max(smoothstep(0.,px*sc,abs(abs(lp.y)+lp.x)-0.065),r));
    float a = cos(lid.x*2.25+lid.y*11.33);
    float b = sin((lid.x*.025+16.*sin(lid.y*.33)));
    float rb = (1.-ra)*step(0.5,0.5+(0.5*a+0.5*b)+b*3.*sin(lid.y*.33));
    b = sin(lid.x*.25+0.6);
    ra=(1.-ra)*step(0.5,0.5+0.5*a+0.6*b)*step(lid.x,18.)*step(25.,mod(lid.y,26.));
    
    float rc=step(mod(lid.y,26.),4.)*(1.-step(4.,mod(lid.y,26.))*step(9./alid.x,abs(lid.x/alid.x-0.5)));
    rb*=(1.-rc)*step(mod(lid.y,26.),17.);
    
    rc*=step(abs(lid.x/alid.x-0.5),7./alid.x);
    
    float rd = (1.-rc)*step(abs(lid.x/alid.x-0.5),8./alid.x)*step(mod(lid.y,26.),4.);
    rc*=1.-step(abs(lid.x-alid.x*0.5)-2.*abs(mod(lid.y+6.,26.)-8.),0.);
    
    vec2 tid = lid;
    
    lp.x=mix(lp.x,-lp.x,step(tid.x-alid.x*0.5,0.));
    tid=mix(tid,vec2(abs(tid.x-alid.x*0.5),floor(tid.y/6.)),rc);
    s += mix(Rune(lp+0.5, tid, 1./200.*sc)*(rb+ra+rc),l,rd);
    
    
    ra = step(lid.x,2.);
    rb = (1.-ra)*step(lid.x,3.)+step(lid.x,25.)*step(25.,lid.x);
    rc = step(26.,lid.x);
    rd = (1.-step(mod(lid.y,26.),17.))*step(mod(lid.y,26.),24.);

    float trb = rb;
    float trd = rd;
    float tra = ra;
    float xs = step(abs(lp.x),0.45)*step(abs(lp.y),0.45)*(1.-(step(lid.x,3.)+step(25.,lid.x)));
    
    ra = step(0.03,ttl);
    float tlp = 0.4*smoothstep(0.3,0.35,ttl)+0.3*smoothstep(0.05,0.056,ttl)+0.2*smoothstep(0.1,0.13,ttl)+0.1*smoothstep(0.2,0.27,ttl);
    float tlx = smoothstep(0.37,0.995,ttl);
    s*=step(mod(lid.y+1.,26.),floor(tlp*18.));
    
    rb = step(ttl,0.03);
    rc = step(mod(lid.y,26.),23.);
    s*=max(rc,step(lid.x,floor(smoothstep(0.,0.03,ttl)*16.)));
    s+=(1.-rc)*rb*x*step(lid.x-1.,floor(smoothstep(0.,0.03,ttl)*16.))*step(floor(smoothstep(0.,0.03,ttl)*16.),lid.x-1.);
    
    rd = step(mod(lid.y+1.,26.),floor(tlp*18.)+floor(tlx*6.));
    rc = step(mod(lid.y+2.,26.),floor(tlp*18.)+floor(tlx*6.));
    
    tid = lid;
    tid.y = mix(tid.y,mix(min(4.,floor(fract(tlx*6.)*11.))/4.,1.,rc),tra);
    float os = mix(Rune(lp+0.5, tid, 1./200.*sc)*(tra+step(27.,lid.x)*step(-0.5,sin(lid.x*1.25)))*trd,l*trd,trb);
    s+=os*rd;
    s+=xs*step(lid.x-3.,mix(fract(tlx*6.)*50.,50.,rc))*rd*step(19.,mod(lid.y+1.,26.));
    s*=1.-step(mod(lid.y,26.),24.)*step(23.,mod(lid.y,26.));
    s+=ra*x*step(lid.x,0.)*step(mod(lid.y,26.),floor(tlp*18.)+floor(tlx*6.))*step(floor(tlp*18.)+floor(tlx*6.),mod(lid.y,26.));
    
    c=vec4(clamp(s,0.,0.88));
    
    fragColor = vec4(c.rgb,1.0);
}
//--------------------------------------




//right bot

//--------------------------------------
// Rune reused from above


void mainImage_rb( out vec4 fragColor, in vec2 fragCoord )
{

    vec2 res=iResolution.xy/iResolution.xy;
    vec2 uv=fragCoord/iResolution.xy-0.5*res;
    
    float px = 1.5/iResolution.y;
    vec4 c=vec4(0.);
    
    float sc = 25.;
    vec2 tuv = (uv+res*0.5)*sc;
    vec2 lid = floor(tuv);
    vec2 alid = floor(res*sc);
    vec2 olid = lid;
    tuv = fract(tuv)-0.5;
    
    float s = 0.;
    float r = smoothstep(0.,px*sc,length(tuv)-0.35);
    
    float t = (local_iTime*3.5+178.)*0.24+22.51;
    float x = step(tuv.y+0.35,0.)*step(0.,abs(tuv.x+0.5)-0.15);
    x*=step(fract(t*4.85+(lid.x-lid.y+alid.y*2.)*0.33),(olid.y<0.5?0.65:0.25)-0.15*sin(lid.x*5.35));
    float ttl = t + .4*(cos(t/1.5) - cos(t));
    lid.y=-lid.y+2.*alid.y;
    lid.y+=floor(ttl);
    ttl = fract(ttl);
    
    float l = (1.-r)*step(abs(tuv.x)-0.065,0.)+step(sign(lid.x-1.)*tuv.x-0.065,0.)*step(abs(tuv.x)-0.065*3.,0.)*step(abs(abs(tuv.y)-0.5+0.065*2.)-0.065,0.);
    
    float ra = (step(lid.x,0.)+step(3.,lid.x)*step(lid.x,3.));
    float rb = (step(1.,lid.x)*step(lid.x,3.));
    float rc = step(1.,olid.y);
    
    s=l*ra;
    
    vec2 tid = lid;
    tid.y = mix(tid.y,mod(tid.y*5.,20.),rb);
    s+=Rune(tuv+0.5, tid, 1./200.*sc)*(1.-ra)*step((tid.x+30.*(0.5+0.5*sin(tid.y*2.33))),alid.x);
    
    s*=step(72.,lid.y)*rc*max(step(2.,olid.y),step(lid.x,3.+alid.x*step(0.015,ttl*ttl)));
    s+=x*step(lid.x,0.)*(1.-rc);
    
    c=vec4(clamp(s,0.,0.88));
    
    fragColor = vec4(c.rgb,1.0);
}


//--------------------------------------



void mainImage_col1( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    ivec2 tid = ivec2(uv*2.);
    
    float m = 2.;
    /*if(iMouse.z>0.){
        m=1.;
        tid = ivec2(iMouse.xy/iResolution.xy*2.);
    }*/
    
    if(tid==ivec2(0,0)){mainImage_lb(fragColor, fract(uv*m)*iResolution.xy);}
    
    else{if(tid==ivec2(0,1)){mainImage_lt(fragColor, fract(uv*m)*iResolution.xy, 0.);}
    else{if(tid==ivec2(1,0)){mainImage_rb(fragColor, fract(uv*m)*iResolution.xy);}
    else mainImage_rt(fragColor, fract(uv*m)*iResolution.xy);}
    }
    
    fragColor.a = 1.;
    
}













// modified https://www.shadertoy.com/view/sldGDf
//-----------------------------


// Created by Danil (2021+) https://cohost.org/arugl

// License - CC0 or use as you wish



// using MIT License code
// using https://www.shadertoy.com/view/wtXfRH
// using https://www.shadertoy.com/view/ll2GD3


#define SS(x, y, z) smoothstep(x, y, z)
#define MD(a) mat2(cos(a), -sin(a), sin(a), cos(a))


// divx is number of lines on background
//#define divx floor(iResolution.y/15.)

const float divx = 25.;
#define polar_line_scale (2./divx)

const float zoom_nise = 5.;


// Common code moved for Cineshader support
//-------------Common code

// using MIT License code
// using https://www.shadertoy.com/view/wtXfRH
// using https://www.shadertoy.com/view/ll2GD3

mat3 rotx(float a){float s = sin(a);float c = cos(a);return mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, c, s), vec3(0.0, -s, c));  }
mat3 roty(float a){float s = sin(a);float c = cos(a);return mat3(vec3(c, 0.0, s), vec3(0.0, 1.0, 0.0), vec3(-s, 0.0, c));}
mat3 rotz(float a){float s = sin(a);float c = cos(a);return mat3(vec3(c, s, 0.0), vec3(-s, c, 0.0), vec3(0.0, 0.0, 1.0 ));}

float linearstep(float begin, float end, float t) {
    return clamp((t - begin) / (end - begin), 0.0, 1.0);
}

float fbm( in vec2 p )
{
    p*=0.25;
    float s = 0.5;
    float f = 0.0;
    for( int i=0; i<4; i++ )
    {
        f += s*noise(p);
        s *= 0.8;
        p = 2.01*mat2(0.8,0.6,-0.6,0.8)*p;
    }
    return 0.5+0.5*f;
}

vec2 ToPolar(vec2 v)
{
    return vec2(atan(v.y, v.x)/3.1415926, length(v));
}

// fwidth removed because AMD bug
// bug https://www.shadertoy.com/view/MfsBz8
// https://gitlab.freedesktop.org/mesa/mesa/-/issues/11683
vec3 fcos( vec3 x )
{
return cos(x);
/*
    vec3 w = fwidth(x);
    return cos(x) * smoothstep(3.14*2.0,0.0,w);
*/
}


vec3 getColor( in float t )
{
    vec3 col = vec3(0.3,0.4,0.5);
    col += 0.12*fcos(6.28318*t*  1.0+vec3(0.0,0.8,1.1));
    col += 0.11*fcos(6.28318*t*  3.1+vec3(0.3,0.4,0.1));
    col += 0.10*fcos(6.28318*t*  5.1+vec3(0.1,0.7,1.1));
    col += 0.10*fcos(6.28318*t* 17.1+vec3(0.2,0.6,0.7));
    col += 0.10*fcos(6.28318*t* 31.1+vec3(0.1,0.6,0.7));
    col += 0.10*fcos(6.28318*t* 65.1+vec3(0.0,0.5,0.8));
    col += 0.10*fcos(6.28318*t*115.1+vec3(0.1,0.4,0.7));
    col += 0.10*fcos(6.28318*t*265.1+vec3(1.1,1.4,2.7));
    return col;
}


vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

//----------end of Common

vec3 get_noise(vec2 p,float timer){
    vec2 res = iResolution.xy/iResolution.y;
    vec2 shiftx= res*0.5*1.25+.5*(0.5+0.5*vec2(sin(0.01*timer*0.0851),cos(0.01*timer*0.0851)));
    vec2 shiftx2= res*0.5*2.+.5*(0.5+0.5*vec2(sin(timer*0.0851),cos(timer*0.0851)));
    vec2 tp = p + shiftx;
    float atx = (atan(tp.x+0.0001*(1.-abs(sign(tp.x))),tp.y)/3.141592653)*.5+fract(timer*0.0125);
    vec2 puv = ToPolar(tp);
    puv.y+=atx;
    puv.x*=0.5;
    vec2 tuv = puv*divx;
    float idx = mod(floor(tuv.y),divx)+200.;
    puv.y=fract(puv.y);
    puv.x=abs(fract(puv.x/divx)-0.5)*divx; // mirror seamless noise
    puv.x+=-.5*timer*(0.075-0.0025*max((min(idx,16.)+2.*sin(idx/5.)),0.));
    return vec3(SS(0.43,0.73,fbm(((p*0.5+shiftx2)*MD(-timer*0.013951*10./zoom_nise))*zoom_nise*2.+vec2(4.+2.*idx))),SS(0.543,0.73,fbm(((p*0.5+shiftx2)*MD(timer*0.02751*10./zoom_nise))*zoom_nise*1.4+vec2(4.+2.*idx))),fbm(vec2(4.+2.*idx)*puv*zoom_nise/100.));
}

vec4 get_lines_color(vec2 p, vec3 n, float timer){
    vec2 res = iResolution.xy/iResolution.y;
    
    vec3 col= vec3(0.);
    float a = 1.;
    
    vec2 shiftx= res*0.5*1.25+.5*(0.5+0.5*vec2(sin(0.01*timer*0.0851),cos(0.01*timer*0.0851)));
    vec2 tp = p + shiftx;
    float atx = (atan(tp.x+0.0001*(1.-abs(sign(tp.x))),tp.y)/3.141592653)*(0.5)+fract(timer*0.0125);
    vec2 puv = ToPolar(tp);
    puv.y+=atx;
    puv.x*=0.5;
    vec2 tuv = puv*divx;
    float idx = mod(floor(tuv.y),divx)+1.;
    
    
    // thin lines
    float d = length(tp);
    d+=atx;
    float v = sin(3.141592653*2.*divx*0.5*d+0.5*3.141592653);
    float fv =fwidth(v);
    fv+=0.0001*(1.-abs(sign(fv)));
    d = 1.-SS(-1.,1., .3*abs(v)/fv);
    
    float d2 = 1.-SS(0., 0.473, abs(fract(tuv.y)-0.5));
    tuv.x+=3.5*timer*(0.01+divx/200.)-0.435*idx;
    
    // lines
    tuv.x=abs(fract(tuv.x/divx)-0.5)*divx;
    float ld = SS(0.1,.9,(fract(polar_line_scale*tuv.x*max(idx,1.)/10.+idx/3.)))*(1.-SS(0.98,1.,(fract(polar_line_scale*tuv.x*max(idx,1.)/10.+idx/3.))));
    
    tuv.x+=1.*timer*(0.01+divx/200.)-01.135*idx;
    ld *= 1.-SS(0.1,.9,(fract(polar_line_scale*tuv.x*max(idx,1.)/10.+idx/6.5)))*(1.-SS(0.98,1.,(fract(polar_line_scale*tuv.x*max(idx,1.)/10.+idx/6.5))));
    
    float ld2 = .1/(max(abs(fract(tuv.y)-0.5)*1.46,0.0001)+ld);
    ld = .1/((max(abs(fract(tuv.y)-0.5)*1.46,0.0001)+ld)*(2.5-(n.y+1.*max(n.y,n.z))));

    
    ld=min(ld,13.);
    ld*=SS(0.0,0.15,0.5-abs(fract(tuv.y)-0.5));
    
    // noise
    d*=n.z*n.z*2.;
    float d3=(d*n.x*n.y+d*n.y*n.y+(d2*ld2+d2*ld*n.z*n.z));
    d=(d*n.x*n.y+d*n.y*n.y+(d2*ld+d2*ld*n.z*n.z));
    
    a=clamp(d,0.,1.);
    
    
    puv.y=mix(fract(puv.y),fract(puv.y+0.5),SS(0.,0.1,abs(fract(puv.y)-0.5)));
    col = getColor( .54*length(puv.y) );
    
    col = 3.5*a*col*col+2.*(mix(col.bgr,col.grb,0.5+0.5*sin(timer*0.1))-col*0.5)*col;
    
    d3=min(d3,4.);
    d3*=(d3*n.y-(n.y*n.x*n.z));
    d3*=n.y/max(n.z+n.x,0.001);
    d3=max(d3,0.);
    vec3 col2 = .5*d3*vec3(0.3,0.7,0.98);
    col2=clamp(col2,0.,2.);
    
    col=col2*0.5*(0.5-0.5*cos((2.88*2.)))+mix(col,col2,0.45+0.45*cos((2.88*2.)));
    
    col=clamp(col,0.,1.);
    
    //col=vec3(ld);
    
    return vec4(col,a);
}

vec4 planet(vec3 ro, vec3 rd, float timer, out float cineshader_alpha)
{   
    vec3 lgt = vec3(-.523, .41, -.747);
    float sd= clamp(dot(lgt, rd)*0.5+0.5,0.,1.);
    float far = 400.;
    float dtp = 13.-(ro + rd*(far)).y*3.5;
    float hori = (linearstep(-1900., 0.0, dtp) - linearstep(11., 700., dtp))*1.;
    hori *= pow(abs(sd),.04);
    hori=abs(hori);
    
    vec3 col = vec3(0);
    col += pow(hori, 200.)*vec3(0.3, 0.7,  1.0)*3.;
    col += pow(hori, 25.)* vec3(0.5, 0.5,  1.0)*.5;
    col += pow(hori, 7.)* pal( timer*0.48*0.1, vec3(0.8,0.5,0.04),vec3(0.3,0.04,0.82),vec3(2.0,1.0,1.0),vec3(0.0,0.25,0.25) )*1.;
    col=clamp(col,0.,1.);
    
    float t = mod(timer,15.);
    float t2 = mod(timer+7.5,15.);
    float td = .071*dtp/far+5.1;
    float td2 = .1051*dtp/far+t*.00715+.025;
    float td3 = .1051*dtp/far+t2*.00715+.025;
    vec3 c1=getColor(td);
    vec3 c2=getColor(td2);
    vec3 c3=getColor(td3);
    c2=mix(c2,c3.bbr,abs(t-7.5)/7.5);

    c2=clamp(c2,0.0001,1.);
    
    col+=sd*hori*clamp((c1/(2.*c2)),0.0,3.)*SS(0.,50.,dtp);
    col=clamp(col,0.,1.);
    
    float a=1.;
    a=(0.15+.95*(1.-sd))*hori*(1.-SS(.0,25.,dtp));
    a=clamp(a,0.,1.);
    
    hori = mix(linearstep(-1900., 0.0, dtp), 1. - linearstep(11., 700., dtp), sd);
    cineshader_alpha=1.-pow(hori,3.5);

    return vec4(col,a);
}

vec3 cam(vec2 uv, float timer)
{
    //vec2 res = (ires.xy / ires.y);
    //vec2 im = (mouse.xy) / ires.y - res/2.0;
    timer*=0.48;
    vec2 im = vec2(cos(mod(timer,3.1415926)),-0.02+0.06*cos(timer*0.17));
    im*=3.14159263;
    im.y = -im.y;
    
    float fov = 90.;
    float aspect = 1.;
    float screenSize = (1.0 / (tan(((180.-fov)* (3.14159263 / 180.0)) / 2.0)));
    vec3 rd = normalize(vec3(uv*screenSize, 1./aspect));
    rd = (roty(-im.x) * rotx(im.y) * rotz(0.32*sin(timer*0.07))) * rd;
    return rd;
}


const mat3 ACESInputMat = mat3(
    0.59719, 0.35458, 0.04823,
    0.07600, 0.90834, 0.01566,
    0.02840, 0.13383, 0.83777
);

const mat3 ACESOutputMat = mat3(
     1.60475, -0.53108, -0.07367,
    -0.10208,  1.10813, -0.00605,
    -0.00327, -0.07276,  1.07602
);

vec3 RRTAndODTFit(vec3 v)
{
    vec3 a = v * (v + 0.0245786) - 0.000090537;
    vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
    return a / b;
}

vec3 ACESFitted(vec3 color)
{
    color = color * ACESInputMat;
    color = RRTAndODTFit(color);
    color = color * ACESOutputMat;
    color = clamp(color, 0.0, 1.0);
    return color;
}


void mainImage_col2( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = vec4(0.);
   
    vec4 ttimers = vec4(80.7,11.,289.,161.);
    vec4 ttimers2 = vec4(.865);
    vec4 ttimers3 = vec4(2.05,2.75,4.,1.75);
    
    vec2 res = iResolution.xy/iResolution.xy;
    vec2 uv = fragCoord.xy/iResolution.xy;
    int ix = int(uv.x*2.)+2*int(uv.y*2.);
    uv=fract(uv*2.)-0.5*res;
    float timer = floor(iTime*ttimers3[ix])/ttimers3[ix];
    vec3 noisev = get_noise(uv, timer*ttimers2[ix]+ttimers[ix]);

    vec4 lcol = get_lines_color(uv, noisev, timer*ttimers2[ix]+ttimers[ix]);

    //fragColor = vec4(lcol.rgba);

    vec3 ro = vec3(1.,40.,1.);
    vec3 rd = cam(uv, ttimers[ix]);
    float cineshader_alpha;
    vec4 planetc = planet(ro,rd,timer*ttimers2[ix]+ttimers[ix],cineshader_alpha);

    vec3 col = lcol.rgb*planetc.a*0.75+0.5*lcol.rgb*min(12.*planetc.a,1.)+planetc.rgb;
    col=clamp(col,0.,1.);
    
    fragColor = vec4(col*0.85+0.15*col*col,1.);
    
    // extra color correction
    fragColor.rgb = fragColor.rgb*0.15+fragColor.rgb*fragColor.rgb*0.65+(fragColor.rgb*0.7+0.3)*ACESFitted(fragColor.rgb);
    
    fragColor.rgb = fragColor.rgb*0.15+2.5*fragColor.rgb*fragColor.rgb;
    
}






// modified https://www.shadertoy.com/view/4tKczz
//-----------------------------

#define ltimer2 (iTime*0.85)

float grid(vec2 uv, float res) {
    uv.x = mod(uv.x, res);
    float ret = smoothstep(res / 2. - res / 10., res / 2., abs(uv.x - res / 2.));
    uv.y = mod(uv.y, res);
    ret = max(ret, 0.72 * smoothstep(res / 2. - res / 5., res / 2., abs(uv.y - res / 2.)));
    return ret;
}

const float time_val = 14.; //animation time
const int layersxx = 4; //number of layers
#define mod_loc(ffx) mod(ffx,time_val)

vec2 layer(vec2 uv, float time, float zoom) {
    float vsal = 0.5 * zoom;
    float dv = mod_loc(time) + vsal;
    float circle = 1. - smoothstep(0.497 * (dv - vsal), 0.5 * (dv - vsal), length(uv + vec2(0., vsal)));
    return vec2(grid(uv / (dv / 2.), 0.1), circle);
}

float mi_o_y(vec2 uv, float zoom) {
    uv *= zoom;
    float layersx = float(layersxx);
    vec2 layerax[layersxx];
    //sorry I dont know how to make it simpler
    for (int i = 0; i < layersxx; i++) {
        layerax[clamp(i,0,layersxx-1)] = layer(uv, ltimer2 + time_val / layersx * float(i), zoom);
    }
    vec2 retl[layersxx];
    for (int i = layersxx; i >= 0; i--) {
        int itr = i + int(layersx * (mod_loc(ltimer2) / time_val));
        if (itr >= layersxx)itr = (itr - layersxx);
        retl[clamp(itr,0,layersxx-1)] = layerax[clamp(i,0,layersxx-1)];
    }
    float ret = 0.;
    for (int i = layersxx; i >= 0; i--) {
        ret = max(ret * (1. - retl[clamp(i,0,layersxx-1)].y), retl[clamp(i,0,layersxx-1)].x * retl[clamp(i,0,layersxx-1)].y);
    }
    return ret;
}

float mk(vec2 st) {
    vec2 lines = vec2(1.0, 2.0);
    float maxVlines = 4.0;
    st.y += 0.5;
    vec2 shift = vec2(mix(lines.x, maxVlines, st.y), lines.y);
    st.y += -0.5;
    st.x *= 9. / 16.;
    st.x += 0.5;
    vec2 suv = vec2((st.x * shift.x) - (shift.x * 0.5), st.y * shift.y);
    float zoom = 2.5 + 2. * (sin(1.5 * sin(ltimer2 / 10.)));
    return mi_o_y(suv, zoom * 0.56);
}

void mainImage_col3(out vec4 fragColor, in vec2 fragCoord) {
    vec2 res = iResolution.xy / iResolution.xy;
    vec2 uv = (((fragCoord.xy) / iResolution.xy) - res / 2.0);
    fragColor = vec4(abs(mk(1.035*uv*vec2(1.,.5)+vec2(0.,-0.417))));
    fragColor*=fragColor;
    fragColor*=step(length(uv)-smoothstep(0.5,1.75,iTime),0.);
    fragColor = clamp(fragColor,0.,1.);
    
    
    vec2 tuv = fragCoord.xy / iResolution.xy;
    
    float tft = iTime;
    
	float d = 0.5+0.5*noise(tuv*vec2(0.05,100.)+tft*vec2(0.5,1.5));
    d*= 0.5+0.5*noise(tuv*vec2(0.05,30.)+vec2(0.,tft*8.5));
    d*= 0.5+0.5*noise(tuv*vec2(0.05,10.5)+vec2(0.,tft*5.5));
    d *= hash12(300.*floor(tuv*100.)/100.+tft*0.1);
    d*=2.;
    float tt = abs(20.-mod(iTime*1.,40.));
    d*=1.-smoothstep(0.5-0.001-2.*smoothstep(5.,15.,tt),0.5-.5*smoothstep(5.,15.,tt),abs(tuv.y-0.5));
    
    fragColor+=d;
    
}
