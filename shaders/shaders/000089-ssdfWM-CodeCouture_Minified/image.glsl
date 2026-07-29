// Image (image) — CodeCouture Minified by BigWIngs
// https://www.shadertoy.com/view/ssdfWM

// "Code Couture (minified)" 
// a generative digital fashion initiative where we are investigating digital fashion created from algorithms. 
// by Martijn Steinrucken aka BigWings/The Art of Code - 2022
// in collaboration with Isabelle Udo and Lucas Guzman
//
// Email: countfrolic@gmail.com
// Twitter: @The_ArtOfCode
// YouTube: youtube.com/TheArtOfCodeIsCool
//
// Music: https://soundcloud.com/mysticstate/mystic-state-society-feat-astrid
//
// To see this properly with music you can also check out YouTube:
// https://youtu.be/GQxC1ySDkP8
// 
// ShaderToy SoundCloud support has been spotty in the past year or so.
// If you don't hear sound then follow these steps:
// 1) Click iChannel0
// 2) Click the SoundCloud textfield and press enter
// 3) Close the settings
// 4) Press play
// 5) Press reset
// Stuff should now be synced to the music
//
// This shader uses 2x2 supersampled anti-aliasing. If you get a slow framerate, you could turn it off by setting the int at the 
// very start to 
// int A=1;
// Theoretically, this should give a 4x speedup at the cost of some jaggies.
//
// Some Background:
// A couple of months ago Isabelle reached out to me to see if I wanted to do a collaboration in the digital fashion space.
// With more and more people spending more of their life, and expression online the rise of digital fashion is inevitable.
// I like to be at the forefront of new technologies, especially if they have to do with generative art, so I was all for 
// exploring this space together.
//
// The aim is to generate an NFT collection that goes on the blockchain so size needs to be as small as possible. 
// We managed to get it down to 6666 characters raw, and 3147 characters zipped. Not sure how much html, js and css boilerplate
// code we'll need in the end but its a good start.
// 
// The animation was made in Blender and then exported as a bunch of sines per joint which seems to make quite natural movements.
// The body was made with capsules only.
//
// To find out more about the project follow us on instagram @codecouture.studio or check the website https://codecouture.studio/ 
// for early access!

#define S smoothstep
#define F float
#define V vec3
#define U vec2
#define N normalize
#define R iResolution
#define I return
#define C cross
int A=2;F i=1.,r=0.,m,f[32];V y=N(V(1,1,-1)),c[48];U s(U c,F f,F e,F i){F m=e-f>=0.?1.:-1.;c.x*=m;f*=m;e*=m;c.x-=f;U y=U(cos(i),-sin(i)),
r=U(cos(i/2.),-sin(i/2.));F x=sign(i),t=e-f,s=t/i,a=dot(c+U(0,s),r);if(!(a<0.&&c.x<0.||abs(i)<.001)){c.y+=s;U z=U(atan(c.x,x*c.y),
length(c));if(dot(c,y)<0.&&z.x<abs(i))z*=x,c=U(z.x*s,z.y-s);else c*=mat2(y.x,y.y,-y.y,y.x),c.x+=t,c.y-=s;}I U(m*(c.x+f),c.y);}
F s(F c,F i,F y){F f=clamp(.5+.5*(i-c)/y,0.,1.);I mix(i,c,f)-y*f*(1.-f);}mat2 s(F i){F c=sin(i),f=cos(i);I mat2(f,-c,c,f);}
F s(V i,V m,V e,F c,F f){V y=e-m,r=i-m;F x=dot(y,r)/dot(y,y);V s=m+clamp(x,0.,1.)*y;I length(i-s)-mix(c,f,x);}V n(F y)
{I fract(sin(V(122.345,234.345,345.234)*y)*1e4);}V n(F y,F i,F c,F f,F x,F s,F e,F a,F t,F r,F v,F l,F n){F z=m+y;I V(i,c,f)*
sin(V(x,s,e)*z+V(a,t,r))+V(v,l,n);}V n(F i,F c,F f,F y,F x,F m,F s,F t,F e,F r){I n(i,c,f,y,x,m,s,t,e,r,0.,0.,0.);}void x(F y){
F i=y*38.5;int f=y==0.?0:24;c[0+f]=n(i,-.013,-.02,.016,.082,.166,.167,.791,.57,1.691,.122,1.421,.065)+n(i,-.001,-.005,.008,.163,
.082,.083,1.16,.919,1.572);c[1+f]=n(i,-.012,-.021,.02,.082,.166,.166,.595,.652,1.78,.084,1.321,.003)+n(i,-.002,-.005,.006,.164,.331,
.083,7.355,.39,1.625);c[2+f]=n(i,-.011,-.019,.022,.082,.166,.166,.578,.865,1.89,.069,1.294,-.019)+n(i,-.002,-.005,.005,.167,.331,
.083,.903,.698,1.584);c[3+f]=n(i,-.014,-.019,-.043,.083,.166,.165,1.126,.879,-.912,.034,1.032,-.018)+n(i,.008,-.005,.004,.247,.331,
.083,1.163,.605,.943);c[4+f]=n(i,-.013,-.019,-.017,.082,.166,.168,.717,.404,-1.574,.162,1.42,.057)+n(i,-9e-4,-.009,.015,.162,.082,
.083,1.052,.948,1.485)+n(i,0.,-.005,-.002,.33,.331,.249,1.064,.451,-.976);c[5+f]=n(i,.03,-.0178,.052,.083,.166,.082,-1.852,.332,
1.556,.185,1.139,.062);c[6+f]=n(i,.045,.02,.103,.083,.081,.083,-1.7,-1.75,1.446,.235,.917,.036);c[8+f]=n(i,.029,.019,.037,.082,.082,
.162,.006,-1.351,2.193,.086,.9,.043)+n(i,.004,-.014,.031,.248,.164,.083,-1.768,1.174,-1.733,0.,0.,0.);c[7+f]=n(i,.036,.021,-.04,
.082,.082,.165,-.047,-1.252,-1.093,.089,.96,.044)+n(i,.005,-.017,-.005,.167,.165,.084,-.08,1.217,.565);c[9+f]=n(i,.018,-.013,.074,
.082,.165,.084,-.089,.751,-1.78,.092,.82,.02)+n(i,.005,-.007,.033,.163,.082,.165,-1.15,1.404,1.53,0.,0.,0.);c[10+f]=n(i,-.02,
-.018,.225,.082,.079,.083,-.118,-.408,-1.647,.064,.5,-.018)+n(i,-.019,-.015,.059,.165,.25,.165,1.13,-.107,.487);c[11+f]=n(i,-.05,
-.095,-.396,.082,.083,.082,-.454,.023,1.108,.017,.098,.118)+n(i,-.018,.038,.069,.165,.166,.165,.665,-1.67,-1.273,0.,0.,0.);c[13+f]
=n(i,.031,-.017,.039,.082,.165,.164,-.138,.899,2.054,.075,.947,.03)+n(i,.004,.007,.011,.167,.083,.083,-.208,-1.12,-1.963,0.,0.,0.);
c[12+f]=n(i,.011,-.023,-.021,.245,.165,.165,1.445,.931,-.496,.02,1.265,-.04)+n(i,-.006,-.006,.002,.168,.331,.084,.655,.595,1.23,0.,
0.,0.);c[15+f]=n(i,-.013,-.019,-.031,.083,.166,.166,.898,.794,-1.037,.047,1.176,0.)+n(i,.004,-.005,.004,.247,.331,.082,1.272,.597,
1.332);c[14+f]=n(i,-.015,-.021,.016,.082,.166,.167,.775,.443,1.551,.106,1.38,.089)+n(i,-.002,.005,.007,.248,.083,.083,.857,-1.71,
1.676);}void n(){F i=0.;c[16]=n(i,.003,-.02,.015,.082,.166,.166,-1.47,.57,1.854,.011,1.678,.016)+n(i,0.,-.004,.001,.162,.331,.33,
.865,.37,.523);c[17]=n(i,.004,-.02,.015,.082,.166,.166,-1.814,.564,1.792,.012,1.599,-.016)+n(i,-.001,-.004,.0,.163,.332,.083,.662,
.34,.836);c[18]=n(i,-.007,-.02,.014,.082,.166,.166,.825,.579,1.791,.01,1.567,.036)+n(i,0.,-.005,.001,.162,.331,.083,.773,.385,1.141
);c[19]=n(i,-.014,-.02,.013,.082,.166,.166,.71,.594,1.803,.011,1.47,.064)+n(i,0.,-.005,.001,.161,.331,.083,1.321,.383,-4.553);c[21]=
n(i,-.013,-.02,.016,.082,.166,.166,.788,.581,1.827,.011,1.435,.065)+n(i,-.001,-.005,.001,.162,.331,.083,1.131,.38,1.702);c[22]=n(i,
-.012,-.02,.02,.082,.166,.166,.58,.666,1.856,.013,1.315,0.)+n(i,-.002,-.005,.002,.164,.331,.083,1.053,.388,-4.414);c[23]=n(i,.028,
-.021,-.034,.082,.166,.165,-.241,.888,-1.12,.005,1.004,-.022)+n(i,.003,-.005,.002,.165,.332,.332,-.688,.431,1.164);x(0.);x(1.);}
F n(V i,F y){int m=0,r=0;V x,e,t,a,n;F l,z,v,b,d;if(y>0.)m=24,r=16,i.x*=-1.;f[4+r]=s(i,c[0+m],c[1+m],.065,.074);f[5+r]=s(i,c[2+m],
c[3+m],.08,.045);f[6+r]=s(i,c[4+m],c[5+m],.054,.042);f[7+r]=s(i,c[5+m],c[6+m],.045,.025);v=s(i,c[8+m],c[7+m],.1,.091);f[9+r]=s(i,
c[9+m],c[10+m],.094,.05);e=N(c[9+m]-c[10+m]),t=C(V(1,0,0),e),a=mix(c[9+m],c[10+m],.6)+t*.03;b=length(i-a);f[9+r]-=S(.15,0.,b)*.02;
f[8+r]=s(i,c[10+m],c[11+m],.055,.035);e=N(c[10+m]-c[11+m]);t=C(V(1,0,0),e);n=mix(c[11+m],c[10+m],.6)+t*.03;l=length(i-n);f[8+r]-=
S(.15,0.,l)*.03;f[10+r]=s(i,c[13+m],c[12+m],.104,.055);f[11+r]=s(i,c[15+m],c[14+m]-V(0,0,.02),.08235,.0853);f[12+r]=s(s(f[10+r],f[
11+r],.1),s(f[4+r],f[5+r],.02),.01);z=s(f[6+r],f[7+r],.01);f[13+r]=s(f[8+r],s(f[9+r],v,.03),.01);d=i.y;d=s(f[13+r],f[12+r],.04);d=
s(d,z,.03*S(.05,0.,length(i-c[4+m])-.1));I d;}F s(V i,V y){y=c[16]+V(0,-1.8,0);i.x=abs(i.x);V x,r;F e=12.,t=m*.1,a,l,z,d;for(F v=0.;
v<1.;v+=1./6.)r=n(v),a=v*6.283,l=fract(r.x-t*r.y*.25),x=V(1.+sin(a),mix(.9,1.5,l),cos(a)),x+=y,z=.1*S(.5,.3,abs(l-.5)),d=s(i,x*V(0,1
,0),x,z,z),d=abs(abs(abs(d)-.01)-.03)-.01,e=s(e,d,.1);e=s(e,abs(f[14]-.01)-.01,-.02);I e;}F t(V e){F y=iTime;e.xz*=s(y);e.xy=s(e.yx,
1.2,1.8,sin(iTime*.2)*r).yx;e.xz*=s(-y);e.xz*=s(e.y*sin(iTime)*r);f[0]=s(e,c[16],c[17],.092,.065);f[1]=s(e,c[18],c[19],.053,.053);f[
2]=s(e,c[21],c[22],.077,.077);f[3]=(length((e-c[23])*V(1,1,1.7))-.14)/1.7;F x=n(e,0.),t=n(e,1.),a=mix(1e-4,.03,S(0.,.07,e.y-.97)),z=
s(x,t,a),m=s(f[0],f[1],.03);m=s(m,f[2],.01);m=s(m,z,.11);m=s(m,f[3],S(.8,1.1,e.y)*.05);if(i==1.)m+=texture(iChannel0,U(e.y*.125,.75)
).x*.02;f[14]=m;if(m<.3)f[15]=s(e,c[17]),m=min(m,f[15]);I m;}F t(V i,V y){F c=0.;for(int f=0;f<50;f++){V e=i+y*c;F m=t(e);c+=m;if(c>
12.||abs(m)<.001)break;}I c;}V d(V i){F m=t(i);U c=U(.001,0);V y=m-V(t(i-c.xyy),t(i-c.yxy),t(i-c.yyx));I N(y);}V d(U i,V y,V e,F c){
V m=N(e-y),f=N(C(V(0,1,0),m)),r=C(m,f),t=m*c,a=t+i.x*f+i.y*r;I N(a);}V d(V i,bool c){V f=mix(V(.8,.67,.69),V(.67,.72,.8),S(0.,c?.4
:.2,i.y));F m=dot(i,y),e=max(0.,1.-m);f+=min(.01/e,1.5);I V(f.x);}V h(U e){i=mod(iTime,27.4)>13.7?100.:1.;m=mod(231.*(floor(
iTime*1.24*.5*i)/i)/6.283,77.);r=S(41.1,68.5,iTime);n();V c=V(0,3,-3);c.yz*=s(-.7);c.xz*=s(iTime*6.283/40.);V x=d(e,c,V(0,1.,0),2.),
a=d(x,false),z=a;F v=t(c,x);if(v<12.){V l=c+x*v,b=d(l),o=reflect(x,b);F h=dot(b,y)*.5+.5;if(abs(f[15])<.002)z=d(o,true).x*V(1.,.3,.3
);else z=V(pow(h,.5))*.7,z+=d(o,true)*.2,z*=.6;z=mix(a,z,S(0.,mix(10.,1.,S(0.,10.,iTime)),l.y));}I z;}void mainImage(out vec4 i,
in U e){U c=(e-.5*R.xy)/R.y;V f=V(0);for(int m=min(iFrame,0);m<A;m++)for(int y=min(iFrame,0);y<A;y++){U r=U(m,y)/F(A)-.5;c=(e+r-.5*
R.xy)/R.y;f+=h(c);}f/=F(A*A);i=vec4(f,1.);}