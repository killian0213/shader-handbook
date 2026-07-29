// Image (image) — Frosted Forest by eiffie
// https://www.shadertoy.com/view/fsXfWN

//Frosted Forest by eiffie

#define time iTime
#define size iResolution

float pixelSize,focalDistance,aperture,fudgeFactor=1.,shadowCone=0.5;
//Beestie based on marius's strandbeest leg https://www.shadertoy.com/view/ltG3z1
//which is based on...
// Visualizing Theo Jansen's Strandbeest basic leg linkage
// http://www.strandbeest.com/
// See http://www.strandbeest.com/beests_leg.php for names & values.

// distance from point p to line segment ab
vec2 seg(vec2 a, vec2 b, vec2 p){
  vec2 pa=p-a,ba=b-a;
  float t=dot(pa,ba)/dot(ba,ba);
  float d=length(pa-ba*clamp(t,0.0,1.0));
  return vec2(d,max(d,0.5-abs(t-0.5)));
}
// intersect point between two 2d circles (x,y,r)
vec2 intersect(vec3 c0, vec3 c1) {
    vec2 dxy = vec2(c1.xy - c0.xy);
    float d = length(dxy);
    float a = (c0.z*c0.z - c1.z*c1.z + d*d)/(2.*d);
    vec2 p2 = c0.xy + (a / d)*dxy;
    float h = sqrt(c0.z*c0.z - a*a);
    vec2 rxy = vec2(-dxy.y, dxy.x) * (h/d);
    return p2 + rxy;
}
float iZ,iY;
float DEB(vec3 p0){
  const float a = .38,b = .415,c = .393,d = .401,e = .558,f = .394,g = .367;
  const float h = .657,i = .49,j = .50,k = .619,l = .078,m = .15;
  float sx=1.0,dB=max(abs(p0.x)-2.0,abs(p0.z)-3.75);
  if(p0.x<0.0){sx=-1.0;p0.z-=0.5;}
  float t=(-time*1.5+(sin(-time*0.1)+2.0)*floor(mod(p0.z,10.))+1.57*sx)*sx;
  float x=sx*p0.x-0.2;
  vec2 crank = vec2(0, 0);         
  vec2 axle = crank - vec2(a, -l);
  vec2 pedal = crank + vec2(m*cos(t), -m*sin(t));
  vec2 uv=vec2(-x,-p0.y);
  // draw "frame"
  vec2 ds = seg(vec2(0, l), axle, uv);
  ds = min(ds, seg(vec2(0, l), crank, uv));
  ds = min(ds, seg(pedal, crank, uv));
  // compute linkage points
  vec2 P1 = intersect(vec3(pedal, j), vec3(axle, b));  // bej
  vec2 P2 = intersect(vec3(axle, c), vec3(pedal, k));  // cgik
  vec2 P3 = intersect(vec3(P1, e), vec3(axle, d));  // edf
  vec2 P4 = intersect(vec3(P3, f), vec3(P2, g)); // fgh
  vec2 P5 = intersect(vec3(P4, h), vec3(P2, i));  // hi
  ds = min(ds, seg(P1, axle, uv));
  ds = min(ds, seg(P3, axle, uv));
  ds = min(ds, seg(P1, P3, uv));
  ds = min(ds, seg(P2, P4, uv));
  ds = min(ds, seg(P2, P5, uv));
  ds = min(ds, seg(P4, P5, uv));
  ds = min(ds, seg(pedal, P1, uv));
  ds = min(ds, seg(pedal, P2, uv));
  ds = min(ds, seg(P2, axle, uv));
  ds = min(ds, seg(P3, P4, uv));
  float z=abs(fract(p0.z)-0.5)-0.2;
  float d2=max(ds.y,z);
  float d3=min(length(uv),length(uv-axle));
  float d1=sqrt(ds.x*ds.x+z*z);
  d1=min(min(min(d1,min(d2,d3))-0.01,(1.2-fract(p0.z))*iZ),abs(p0.x)+0.2);
  return max(d1,abs(p0.z)-3.75);
}
float reed(vec3 p){return max(length(p.xz)-.02+p.y*.02,abs(p.y-.5)-.5);}
float DE(vec3 p0){
  const float zd=30.;
  float x=-zd*1.5+iTime*.25;
  vec3 p=p0+vec3(x,sin(p0.x+2.*sin(p0.z))*.08-.95,-zd-3.);
  float db=max(abs(p.y)-1.,max(abs(p.x)-2.,abs(p.z)-3.75));
  if(db<.2)db=DEB(p);
  p=p0;
  float rnd=1.5+sin(floor(p.x*.5)+floor(p.z*.5));
  float dy=.2*clamp(p.y+.4,0.,1.);
  p+=sin(p.zxy+2.*sin(p.yzx))*dy;
  
  float dg=min(p.y,db),d=10.,dr=1.;
  bool tree=p.x<-x || abs(p.z-zd-3.)>2.75;
  p.xz=mod(p.xz,2.)-1.;
  p.xz=abs(p.xz);
  p.xz-=p.y*p.y*.3;
  if(!tree){p*=2.;dr*=2.;rnd=-1.;}
  d=reed(p)/dr;
  
  for(int i=0;i<3;i++){if(float(i)>rnd)continue;
    p.y-=.42;
    p*=2.;dr*=2.;
    p.xz=abs(vec2(p.x+p.z,p.x-p.z))*.707;
    p.xz-=p.y*p.y*.3;
    d=min(d,reed(p)/dr);
  }
  
  return min(db,min(dg*2.,d*(1.-.5*dy)/iY));
}

float CircleOfConfusion(float t){//calculates the radius of the circle of confusion at length t
 return max(abs(focalDistance-t)*aperture,pixelSize*(1.0+t));
}
mat3 lookat(vec3 fw){
 fw=normalize(fw);vec3 rt=normalize(cross(fw,vec3(0,1,0)));return mat3(rt,cross(rt,fw),fw);
}
float linstep(float a, float b, float t){return clamp((t-a)/(b-a),0.,1.);}// i got this from knighty and/or darkbeam
//random seed and generator
vec2 randv2;
float rand2(){// implementation derived from one found at: lumina.sourceforge.net/Tutorials/Noise.html
 randv2+=vec2(1.0,1.0);
 return fract(sin(dot(randv2 ,vec2(12.9898,78.233))) * 43758.5453);
}
vec3 bg(vec3 rd){
  float d=max(0.,rd.x+rd.y+rd.z);
  return vec3(d*d*.25)+rd*.05;
}
float FuzzyShadow(vec3 ro, vec3 rd, float lightDist, float coneGrad, float rCoC){
 float t=0.01,d=1.0,s=1.0;
 for(int i=0;i<12;i++){
  if(t>lightDist)break;
  float r=rCoC+t*coneGrad;//radius of cone
  d=DE(ro+rd*t)+r*0.66;
  s*=linstep(-r,r,d);
  t+=abs(d)*(0.8+0.2*rand2());
 }
 return clamp(s,0.0,1.0);
}
vec3 path(float t){return vec3(t+.1+cos(t*.23)*2.,.3+.1*sin(t),t);}
void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
 randv2=fract(cos((fragCoord.xy+fragCoord.yx*vec2(100.0,100.0))+vec2(time)*10.0)*1000.0);
 pixelSize=1.0/size.y;
 float tim=min(time,81.85)*0.5;//camera, lighting and object setup
 vec3 ro=path(tim); 
 vec3 rd=lookat(path(tim+.1)-ro)*normalize(vec3((2.0*gl_FragCoord.xy-size.xy)/size.y,2.0)); 
 focalDistance=1.0;iZ=1./rd.z;iY=1.+max(0.,2.*rd.y);
 aperture=0.007*focalDistance;
 vec3 rt=normalize(cross(vec3(0,1,0),rd)),up=cross(rd,rt);//just need to be perpendicular
 vec3 lightColor=vec3(1.0,0.5,0.25),L=normalize(vec3(.4,.4,.2)),bcol=bg(rd);
 vec4 col=vec4(bcol,0.);//color accumulator, .w=alpha
 float t=0.0,d=1.,h[8]=float[8](0.,0.,0.,0.,0.,0.,0.,0.);//distance traveled
 int H=0;
 for(int i=1;i<72;i++){//march loop
  if(col.w>0.9 || t>50.0)break;//bail if we hit a surface or go out of bounds
  float rCoC=CircleOfConfusion(t);//calc the radius of CoC
  d=DE(ro+rd*t);
  if(d<rCoC){h[H++]=t;}//d+=.5*rCoC*linstep(rCoC,-rCoC,d);}
  d*=0.8+0.2*rand2();//add in noise to reduce banding and create fuzz
  t+=d;
 }
 for(int i=7;i>=0;i--){if(h[i]==0.)continue;
   vec3 p=ro+rd*h[i];//back up to previos checkpoint
   float rCoC=CircleOfConfusion(t);
   float d=DE(p),Drd=DE(p+rd*rCoC),Drt=DE(p+rt*rCoC),Dup=DE(p+up*rCoC);
   vec3 N=normalize(rd*(Drd-d)+rt*(Drt-d)+up*(Dup-d));
   if(N!=N)N=-rd;//if no gradient assume facing us
   vec3 scol=vec3(0.4*(1.0+dot(N,L)+.2));//difffuse
   scol+=pow(max(0.0,dot(reflect(rd,N),L)),8.0)*lightColor;//specular lighting
   p+=N*max(0.,-d+0.001);//avoid self shadow
   scol*=FuzzyShadow(p,L,1.5,shadowCone,rCoC);//now stop the shadow march at light distance
   float alpha=(1.0-col.w)*linstep(-rCoC,rCoC,-d);//calculate the mix like cloud density
   scol=mix(scol,bcol,t/50.);
   col=mix(col,vec4(scol,min(col.w+alpha,1.)),alpha);//blend in the new color 
 }
 fragColor = vec4(col.rgb,1.0);
}