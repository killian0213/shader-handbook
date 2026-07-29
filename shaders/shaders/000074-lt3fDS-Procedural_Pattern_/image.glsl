// Image (image) — Procedural Pattern  by ollj
// https://www.shadertoy.com/view/lt3fDS


//---------------------------------------------------------
// Shader: 2dProceduralPattern.glsl  by gPlatl
//
// A collection of 2d procedural pattern types.
// Press mouse button and select pattern in x direction & zoom in y direction.
//
//   v1.0  2017-02-22  initial release
//   v1.1  2017-02-24  changed mod(x,1.) => fract(x)
//   v1.2  2017-03-15  pattern menu added
//   v1.3  2017-04-11  sine pattern added
//   v1.4  2017-04-30  brick wall pattern added
//   v1.5  2017-05-07  GearPattern added
//   v1.6  2017-05-30  HexagonalTruchetPattern added
//   v1.7  2017-06-10  QCirclePattern added
//   v1.8  2017-08-05  StarPattern added
//   v1.9  2017-09-02  Basketwork Pattern added
//   v1.10 2018-07-14  Diamond Pattern added
//   v1.11 2018-09-15  RosettePattern added
//   v1.12 2018-10-11  Wallpaper70sPattern added
//   v1.13 2018-10-11  MinimalWeavePattern added
//
// tags:   procedural, pattern, 2d, basic, texture, collection
// note:   procedural pattern routines will return values from 0.0 .. 1.0
//
// references:
//   Procedural Patterns          http://slideplayer.com/slide/6400090/
//   Antialiasing Proc. Textures  http://www.yaldex.com/open-gl/ch17lev1sec4.html
//---------------------------------------------------------

#define patternCount 23.0

#define PI 3.141592

bool ANIMATE = true;   // false if mousePressed

#define pi acos(-1.)
#define dd(a) dot(a,a)
#define sat(a) clamp(a,0.,1.)
#define aA(z) (z/min(iResolution.x,iResolution.y))


float mi(vec2 a){return min(a.x,a.y);}
float mi(vec3 a){return min(a.x,mi(a.yz));}
float ma(vec2 a){return max(a.x,a.y);}
float mu(vec2 a){return a.x*a.y;}
float ad(vec2 a){return a.x+a.y;}
float su(vec2 a){return a.x-a.y;}
float sq2(float a){return a*a;}


//i think gears are a VERY special thing, too complex for this SIMPLE patter ncollection
//gears must be seperate collection because
//- gears logically overlap, on a lattice this means: https://www.shadertoy.com/results?query=halfspace
//- polar coordinates invite complex transdorms, including sphere inversion
//- gears (due to polar complex numbers) quickly extend into 3d and 4d)
float GearPattern(in vec2 uv     // coordinates
                 ,in float wn    // vertical wheel count
                 ,in int tn      // tooth count
                 ,in float time) // rotation time
{float g = (step(1.0, uv.x * wn) - 0.5) * time;
  uv = fract(uv * wn) - 0.5;
  float r = clamp(0.48, 0.4, 0.45 + 0.12*sin(atan(uv.x,uv.y) * float(tn) + g));
  return smoothstep(r, r + 0.01, 1.1*length(uv));}

float CheckerSignMuFract(vec2 u){return sign(mu(.5-fract(u)));}


//sat(sin()) or mu(sin()) is pretty lame/inconsistent for patterns
float CheckerSatMuSin(vec2 u){return sat(88.*mu(sin(u*8.)));}//rounded white checkerboard
float Checker1ByMuSin(vec2 u){return 1./mu(sin(u));}
float TartanKaro(  vec2 u){return .5*ad(sat(10.*sin(u)));}
float TartanSquare(vec2 u){return 4.*mu(sat(10.*sin(u)));}

float SquareHolePattern(vec2 u
){u.x=mu(sin(u*2.))
 ;return smoothstep(.1,.0, sq2(u.x)*2.5);}

float Grid( vec2 u){
 ;//return ad(abs(fract(u)-.5))//initially was mu(), without -.5 offset, but thats just too trivial
 ;return mi(abs(fract(u)-.5))//, and BrickPattern() without shift
 ;}

float BrickPattern(vec2 p
){//p*=vec2 (1,2)  // scale
 ;vec2 f=floor(p)
 ;p.x-=step(f.y,2.*floor(f.y*.5))*.5// brick shift
 ;p=abs (fract (p + 0.5) - 0.5)
 ;//p=smoothstep (0.03, 0.08, p)
 ;return min(p.x,p.y)
 ;}

vec2 toTri(vec2 u){return vec2(u.x,(u.y*sqrt(3.)+u.x)*.5);}

float TrianglePattern(vec2 u){return step(su(fract(toTri(u))),0.);}//non-homogeneous doesnt smoothstep()

float RhombStar(vec2 u
){u.x=sq2(su(fract(toTri(u))))
 ;return step(.25,u.x)//this is less silly
 ;//return smoothstep(.5,.0,u.x)//rather silly (optical illusion) //doesnt mix well with above line)
 ;}

float hexBorder(vec2 u//subroutine of HexagonalGrid()
){
 ;u.x*=sqrt(3.)*2./3.
 ;u.y+= 0.5 * mod(floor(u.x), 2.0)
 ;u = abs(fract(u)-.5)
 ;return abs(max(u.x*1.5+u.y,u.y*2.)-1.)
 ;}//return smoothstep(0., gridThickness,d);

bool fuckme(vec2 a){float b=(1.-a.y)*.5// return hexagonal gridID pattern with 3 colors
 ;return a.y>1.&&(abs(b-a.x+a.y)>-b);}
bool fuckus(vec2 p){ return 1.>ma(p-p.yx)&&max(-mi(p),ma(p)-2.)<0.;}
float hexId3Hues(in vec2 p
){p =toTri(p)
 ;p = mod(p,vec2(3))
 ;     if(fuckus(p))return .0
 ;else if(fuckme(p))return .5
 ;else              return 1.
 ;}

float hexTruchet(vec2 p//https://www.shadertoy.com/view/Xdt3D8 
){float s=sqrt(3.)
 ;vec2 h=p+vec2(s,.45)*p.y/3.//hex skew
 ;vec2 f=fract(h);h=floor(h)//fractFloor
 ;float v=fract(ad(h)/3.)//+offsetFract
 ;h+=mix(vec2(step(.3,v)),step(f.yx,f),step(.6,v))//(v<.6)?(v<.3)?h:h++:h+=step(f.yx,f)
 ;p+=vec2(1,2.-sqrt(3.))*h.y*.5-h
 ;v=sign(cos(1234.*cos(h.x+9.*h.y)))//v is -1 or 1, appears a bit random
 ;vec3 a=vec3(dd(p-v*vec2(-2, 0)*.5)
             ,dd(p-v*vec2( 1, s)*.5)
             ,dd(p-v*vec2( 1,-s)*.5))
 ;v=(.5-sqrt(mi(a)))*v//all below lines are optional modifiers, each line can be commented out individually
 ;//v*=.5
 ;//v=v+.25 
 ;v=abs(v)
 ;v=1.-(1.-v*2.)
 ;float z=8.
 ;return smoothstep(aA(z),-aA(z),v-(cos(iTime)*(.5-aA(z))+.5))
 ;return v
 ;}


//vec2 cs(vec2 u){return vec2(cos(u.x),sin(u.y));}

float sinePattern(vec2 p){return sin(p.x*20.+cos(p.y*12.));}//trivial elegance, not normalized, but not noticable
float SinePatternCrissCross(vec2 p){return .5+sinePattern(p)*sinePattern(p.yx);}


//euclidean length has p=2, this allows for other p.
float lengthP(in vec2 u, in float p){return pow(pow(abs(u.x),p)+pow(abs(u.y),p),1./p);}

//cute small silly noneuclidean squared-circle, whos corners are dark.
float QCirclePattern(vec2 u){return sin(lengthP(fract(u*4./2.)*2.-1.,4.)*16.);}

float StarPattern(vec2 p//ttps://www.shadertoy.com/view/4sKXzy 
){p= abs(fract(p*1.5)-.5)//adorable stars, smoothstep() of it is nice, too.
 ;return max(ma(p),mi(p)*2.);}

float weaveSub(vec2 u,float p){return step(.2,abs(fract(u.x)))*(.65+.35*sin(p*(u.y-ceil(u.x))));}
float weave(vec2 u,float r//https://www.shadertoy.com/view/ltXcDn 
){float a=weaveSub(u,pi/r)//step(.2,abs(fract(u.x)))*(.65 +.35*sin(pi*.5*(u.y-ceil(u.x))))
 ;u=u.yx;u.y++ //flip//offset
 ;float b=weaveSub(u,pi/r) //step(.2,abs(fract(u.x)))*(.65 +.35*sin(pi*.5*(u.y-ceil(u.x))))
 ;return max (a,b);}
float weave(vec2 u){return weave(u,1.);}

float truchetTiny70s(vec2 p,float time// https://www.shadertoy.com/view/ls33DN by Shane
){p.x*=sign(cos(length(ceil(p))*time))
 ;return cos(min(length(p=fract(p)),length(--p))*44.);}


float xof(float a,float b){return float(int(a)^int(b));}//typecasting, not doing type float bitwise xor!
float anf(float a,float b){return float(int(a)&int(b));}//typecasting, not doing type float bitwise and!
float anf(int   a,float b){return float(int(a)&int(b));}//typecasting, not doing type float bitwise and!

//https://www.shadertoy.com/view/XtcBWH
float weaveInt(vec2 coord// https://www.shadertoy.com/view/XttBWn
){ivec2 uv=ivec2(floor(coord*5.))//type float as much as possible by ollj, to lerp.
 ;float a=floor(mod(iTime,7.))*4.
 ;float bg  =.0//backdrop
 ;float warp=.5//horizontal
 ;float weft=1.//vertical      
 ;vec2 f=floor(vec2(uv.xy)*.5)
 ;a=anf(uv.x^uv.y,a)
 ;vec2 h=vec2(xof(float(uv.x),f.x),xof(float(uv.y),f.y))
 ;h=fract(h/2.)*2.
 ;vec3 i=smoothstep(1.,0.,vec3(a,h.xy))//if only these booleans where floats.
 ;float d=mix(weft,bg,i.z)
 ;float e=mix(warp,bg,i.y)
 ;float c=mix(d,e,i.x)//trilin mix
 ;//c=mix(1.,0.,i.x-(i.z+i.y)*.5)//many other options feasible...
 ;return c;}//https://en.wikipedia.org/wiki/Striation         ==ridged
//likely needs a bokeh-ed soerpinsky: https://www.shadertoy.com/view/MlcfDB

float demo(vec2 u){
   ;return weaveInt(u)
   ;// return smoothstep(-.1,.1,StarPattern(u)-cos(iTime)*.5-.5)
        ;}


void mainImage(out vec4 fragColor,vec2 fragCoord
){
  float aspect = iResolution.y / iResolution.x;
  vec2 mpos = iMouse.xy / iResolution.y;
  vec2 uv = fragCoord.xy / iResolution.y - vec2(0.5);

  float time = iTime
 ;ANIMATE = iMouse.z < 1.0
 ;// get pattern
 ;int pType = int( mpos.x * patternCount * aspect)
 ;if (uv.y<-0.4//menu view
 ){pType = int(fragCoord.xy/iResolution.y*patternCount*aspect);
  uv *= 28.
 ;}else{
  ;uv *= (0.2 + mpos.y) * 10.0
  ;if (ANIMATE   // rotate and scale position
  ){float ra = time*0.12
   ;float cost = cos(ra)
   ;float sint = sin(ra)
   ;uv = vec2(cost*uv.x + sint*uv.y, sint*uv.x - cost*uv.y)
   ;uv *= (1.2+0.3*sin(0.5*time))   // scale
  ;}}
 ;//pType=999
 ;float p // = HexagonalGrid(uv, 0.5, 0.1);
 ;p=demo(uv)
 ;if      (pType == 0) p = hexBorder (uv*1.25)
 ;else if (pType == 1) p = hexBorder(uv*1.25) //HexagonalGrid2() is just BAD, skewed and discontinuous
 ;else if (pType == 2) p = hexId3Hues(uv*2.0)
 ;else if (pType == 3) p = hexTruchet (uv*3.)
 ;else if (pType == 4) p = CheckerSignMuFract(uv)
 ;else if (pType == 5) p = Checker1ByMuSin(uv*8.0)
 ;else if (pType == 6) p = TrianglePattern(uv)
 ;else if (pType == 7) p = RhombStar(uv)
 ;else if (pType == 8) p = TartanKaro(uv)
 ;else if (pType == 9) p = TartanSquare(uv)
 ;else if (pType ==10) p = SquareHolePattern(uv)  
 ;else if (pType ==11) p = sinePattern(uv)
 ;else if (pType ==12) p = Grid(uv)
 ;else if (pType ==13) p = BrickPattern(uv)
 //;else if (pType ==13) p = BrickPattern2(uv)//is just a much worse variant of BrickPattern()
 ;else if (pType ==14) p = GearPattern(uv, 1.5, 12, iTime * 6.5)
 ;else if (pType ==15) p = QCirclePattern(uv)
 ;else if (pType ==16) p = StarPattern(uv)
 ;else if (pType ==17) p = weave(uv)
 ;else if (pType ==18) p = weave(uv,2.)
 ;else if (pType ==19) p = weave(uv,3.)
 ;else if (pType ==20) p = weave(uv,4.)
 //;else if (pType ==19) p = DiamondPattern(uv)    //is just a distorted grid()
 //;else if (pType ==20) p = triRosettePattern(uv) //disqualified, for looping a wallpaper-group:
 ;else if (pType ==21) p = truchetTiny70s(uv, iTime*0.1)
 ;else if (pType ==22) p = weaveInt(uv)
 ;else                 p = demo(uv)
 ;vec4 color1 = vec4 (0.2+0.2*sin(time)
                     ,0.2+0.2*sin(time*0.789)
                     ,0.2+0.2*sin(time*0.665), 1.0)
 ;vec4 color2 = vec4 (0.9)
 ;//fragColor = mix(color1, color2, p)
 ;fragColor = vec4(p)
 ;}


//disqualified, for looping a wallpaper-group: https://en.wikipedia.org/wiki/Wallpaper_group
//i haver standards, and looping trough a kifs is WAY below that.
#define DumbEnoughToLoopAWallpaperGroup(U) .004/abs(length(mod(U,d+d)-d)-d.x)
float triRosettePattern(vec2 p//https://www.shadertoy.com/view/4lGyz3
){vec2 d=vec2(sqrt(3.),3)/3.
 ;vec4 O=vec4(0)
 ;for(; O.a++ < 4.; O += DumbEnoughToLoopAWallpaperGroup(p) +DumbEnoughToLoopAWallpaperGroup(p += d*.5))p.x+=d.x
 ;return O.x;}


//---------------------------------------------------------
// return antialiased hexagonal grid color
//---------------------------------------------------------
/* //this one is just lazy and bad!
float HexagonalGrid2 (in vec2 position)
{
  vec2 pos = position ;
  pos.x *= 1.1;
  pos.y += 0.5 * mod(floor(pos.x), 2.0);
  pos = abs(fract(pos) - 0.5);
  float d = abs(max(pos.x*2.5 + pos.y, pos.y*3.0) - 1.0);
  return smoothstep(0.30, .1, d);
;}
*/

/*
// return brick wall pattern
float BrickPattern2(in vec2 p){//brickpattern2 is just a the dumb cousin of BrickPattern()
    const float vSize = 0.30;
  const float hSize = 0.05;
  p.y *= 2.5;    // scale y
  if(mod(p.y, 2.0) < 1.0) p.x += 0.5;
  p = p - floor(p);
  if((p.x+hSize) > 1.0 || (p.y < vSize)) return 1.0;
  return 0.0;
}*/

/*
float DiamondPattern(vec2 u//https://www.shadertoy.com/view/lsVczV
){u=abs(fract(u)-.5)
 ;return (ma(u));}//without distortions and cosine/smoothstep/scaling, this is just a grid()
*/