// Sound (sound) — My First Shader Sound by keim
// https://www.shadertoy.com/view/MtGSWc

#define PI2 6.28

const float bpm=144.;

// envelope ----------
float rr(float t, float r) {
  return exp(-t*r);
}
float adsr(float t, vec4 e, float gt) {
  return min(t/max(.00001,e.x),max(exp(-e.y*(t-e.x)),min(e.z,e.z*exp(-e.w*(t-gt)))));
}


// wave genelators ----------
float noiz(float s){
  return fract(sin(s*78.233)*43758.5453)*2.-1.;
}

float ssin(float t, float e){
  return clamp(sin(t)*e,-1.,1.);
}

float ssaw(float t, float e){
  return clamp((mod(t/PI2,1.)*2.-1.)*e,-1.,1.);
}

float n2f(float nn){
  return pow(2.,((nn-69.)/12.))*440.*PI2;
}


// patterns ----------
#define L(i,l) float x=99.9,y=15.0*float(i)/bpm,z=0.,w=0.,u=mod(t,y*float(l));
#define D(s) if(u>float(s)*y){x=u-float(s)*y;}
#define E(s,l) if(u>float(s)*y){x=u-float(s)*y;z=float(l);}

vec2 bd(float t) {
  L(1,4)D(0)
  return vec2(0.4,0.4) * ssin(x*n2f(30.-x*5.),8.*rr(x,18.));
}

vec2 hh(float t) {
  L(1,16)E(2,60)E(3,60)E(6,10)E(10,60)E(11,60)E(14,10)
  return vec2(0.1,0.2) * noiz(x)*rr(x,z);
}

vec2 sn(float t) {
  L(1,8)D(4)
  return vec2(0.4,0.4) * noiz(x)*rr(x,12.);
}

vec2 rev(float t) {
  L(16,1)D(0)
  return vec2(0.4,x*0.4) * noiz(x)*adsr(x,vec4(2.2,5,0.2,5),2.2);
}
vec2 cym(float t) {
  L(16,4)D(0)
  return vec2(0.4,0.4) * noiz(x)*adsr(x,vec4(0,9,.5,3),.4);
}

vec2 bs(float t, float n) {
  L(1,16)E(0,33)E(2,0)E(3,33)E(4,0)E(5,33)E(6,31)E(9,33)E(11,33)E(12,33)E(14,31)
  float f=x*n2f(z+n);
  return vec2(0.2,0.2) * (ssin(f+ssin(f*11.1,2.*rr(x,32.)),3.)*rr(x,6.));
}
      
vec2 sq(float t) {
  L(2,6)E(0,69)E(1,74)E(2,76)E(3,69)E(4,74)E(5,81)
  float f=x*n2f(z);
  return abs(vec2(cos(t*1.2),sin(t*1.2)))*0.25 * ssin(f+sin(f*7.)*rr(x,16.)*(2.+sin(t)*3.2),4.)*rr(x,10.);
}

vec2 pd(float t) {
  L(2,4)E(0,69)
  float f=x*n2f(z),f2=x*n2f(z+5.),f3=x*n2f(z+7.);
  return vec2(.2,.2)*(ssaw(f,4.)+ssaw(f2,4.)+ssaw(f3,4.))*adsr(x,vec4(.04,16.,.2,4.),.3);
}


// sequence ---------
#define S(s,m) if(float(s)*240./bpm<t){o=m;}
#define LOOP(s,l) if(float(s)*240./bpm<t){t=mod(t-float(s)*240./bpm,float(l)*240./bpm);
#define LEND() }

vec2 mainSound( in int samp,float t){
  vec2 o = vec2(0,0);
  S( 0, bs(t,0.)+ pd(t) );
  S( 4, bs(t,0.)+ bd(t) + hh(t) + pd(t) );
  S( 8, bs(t,0.)+ bd(t) + sn(t) + hh(t) + pd(t) );
  S(15, bs(t,0.)+ rev(t));
  S(16, bs(t,5.)+ bd(t) + sn(t) + hh(t) + sq(t) + sq(t+75./bpm)*0.6 + cym(t));
  LOOP(20,8)
    S(0, bs(t,0.)+ bd(t) + sn(t) + hh(t) + sq(t) + sq(t+75./bpm)*0.6);
    S(4, bs(t,5.)+ bd(t) + sn(t) + hh(t) + sq(t) + sq(t+75./bpm)*0.6);
  LEND()
  return o;
}