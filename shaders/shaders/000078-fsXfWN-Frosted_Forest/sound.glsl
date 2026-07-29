// Sound (sound) — Frosted Forest by eiffie
// https://www.shadertoy.com/view/fsXfWN

#define bps 4.0 
float rnd(float t){return fract(sin(mod(t,32.123)*32.123)*41.123);} 
vec2 nofs(float n){//the song's "random" ring 
  float r=0.5+0.5*rnd(floor(n));//random volume as well 
  n=mod(n,8.0); 
  if(n<1.0)n= 0.0; 
  else if(n<2.0)n= 5.0; 
  else if(n<3.0)n= -2.0; 
  else if(n<4.0)n= 4.0; 
  else if(n<5.0)n= 7.0; 
  else if(n<6.0)n= 4.0; 
  else if(n<7.0)n= 2.0; 
  else n=0.0;
  return vec2(n,r); 
}
float scale(float note){//throws out dissonant tones 
 float n2=mod(note,12.); 
 //if((n2==1.)||(n2==6.)||(n2==8.)||(n2==10.))note=-100.;//major +3rd
 if((n2==1.)||(n2==3.)||(n2==6.)||(n2==8.)||(n2==10.))note=-100.;//major 
 //if((n2==1.)||(n2==4.)||(n2==6.)||(n2==9.)||(n2==11.))note=-100.;//minor 
 //if((n2==1.)||(n2==2.)||(n2==4.)||(n2==6.)||(n2==8.)||(n2==9.)||(n2==11.))note=-100;//pentatonic minor
 //if((n2==1.)||(n2==2.)||(n2==4.)||(n2==8.)||(n2==9.)||(n2==11.))note=-100.;//blues  
 //if((n2==1.)||(n2==2.)||(n2==5.)||(n2==6.)||(n2==8.)||(n2==10.)||(n2==11.))note=-100.;//country 
 //if((n2==1.)||(n2==4.)||(n2==7.)||(n2==10.))note=-100.;//diminished whole/half 
 //if((n2==1.)||(n2==3.)||(n2==5.)||(n2==6.)||(n2==8.)||(n2==10.)||(n2==11.))note=-100.;//pentatonic major 
 //if((n2==1.)||(n2==4.)||(n2==6.)||(n2==9.)||(n2==10.))note=-100.;//harmonic minor 
 //if((n2==1.)||(n2==4.)||(n2==6.)||(n2==8.)||(n2==10.))note=-100.;//melodic minor ascending 
 //if((n2==1.)||(n2==3.)||(n2==5.)||(n2==7.)||(n2==9.)||(n2==11.))note=-100.;//whole tone 
 //if((n2==2.)||(n2==5.)||(n2==8.)||(n2==11.))note=-100.;//diminished half/whole 
 //if((n2==1.)||(n2==3.)||(n2==6.)||(n2==8.)||(n2==11.))note=-100.;//mixolydian   
 //if((n2==1.)||(n2==4.)||(n2==6.)||(n2==8.)||(n2==11.))note=-100.;//dorian 
 //if((n2==1.)||(n2==3.)||(n2==5.)||(n2==8.)||(n2==10.))note=-100.;//lydian   
 //if((n2==2.)||(n2==4.)||(n2==6.)||(n2==9.)||(n2==11.))note=-100.;//Phrygian 
 //if((n2==2.)||(n2==3.)||(n2==6.)||(n2==9.)||(n2==11.))note=-100.;//Phrygian Major 
 //if((n2==1.)||(n2==3.)||(n2==5.)||(n2==8.)||(n2==11.))note=-100.;//locrian 
 //if((n2==2.)||(n2==4.)||(n2==7.)||(n2==9.)||(n2==11.))note=-100.;//lydian dominant 
 //if((n2==2.)||(n2==3.)||(n2==6.)||(n2==9.)||(n2==10.))note=-100.;//double harmonic 
 //if((n2==2.)||(n2==3.)||(n2==5.)||(n2==7.)||(n2==9.))note=-100.;//enigmatic 
 //if((n2==2.)||(n2==4.)||(n2==6.)||(n2==8.)||(n2==10.))note=-100.;//neapolitan  
 //if((n2==2.)||(n2==4.)||(n2==6.)||(n2==9.)||(n2==10.))note=-100.;//neapolitan minor 
 //if((n2==1.)||(n2==4.)||(n2==5.)||(n2==9.)||(n2==10.))note=-100.;//hungarian minor 
 return note; 
} 
// note number to frequency  from https://www.shadertoy.com/view/ldfSW2 
float ntof(float n){return (n>0.0)?440.0 * pow(2.0, (n - 67.0) / 12.0):0.0;} 
const float PI=3.14159; 
float Cos(float a){return cos(mod(a,PI*2.));} 
float Sin(float a){return Cos(a+PI/2.);} 
struct instr{float att,fo,vibe,vphas,phas,dtun;}; 
vec2 I(float n,float t,float bt,instr i){//note,time,bt 0-8,instrument 
 float f=ntof(scale(n));if(f<12.)return vec2(0.0);f-=bt*i.dtun;f*=t*PI*2.; 
 f=exp(-bt*i.fo)*(1.0-exp(-bt*i.att))*Sin(f+Cos(bt*i.vibe*PI/8.+i.vphas*PI/2.)*Sin(f*i.phas))*(1.0-bt*0.125); 
 n+=t;return vec2(f*Sin(n),f*Cos(n));
} 
vec2 mainSound(int samp, float time){//att,fo,vibe,vphs,phs,dtun
 instr epiano=instr(50.0,0.05,1.5,0.1,1.757,0.001);//silly fm synth instruments 
 instr sitar=instr(2.0,.2,8.0,0.0,0.51,0.0025); 
 instr bassdrum=instr(500.0,1.0,4.0,0.76,1.0,0.5); 
 instr stick=instr(500.0,.5,10.5,0.0,2.3131,1000.0); 
 instr pluckbass=instr(500.0,2.0,1.5,0.0,0.1252,0.005); 
 instr bass=instr(20.0,0.2,2.0,0.0,0.505,0.005); 
 float tim=time*bps,b0,b1,b2,t0,t1,t2;
 vec2 a=vec2(0.0);//accumulator 
 for(float i=0.;i<8.;i+=1.){//go back 8 beats and add note tails 
   b0=floor(tim);b1=floor(tim*0.5);b2=floor(tim*0.25); 
   vec2 n2=nofs(b2*0.0625)+nofs(b2*0.25)+nofs(b2);//build notes on top of notes like fbm 
   vec2 n1=n2+nofs(b1),n0=n2+nofs(b0); 
   t0=fract(tim)+i; 
   a+=I(n0.x+60.0,time,t0,sitar)*n0.y/(1.+abs(n0.x)*.25);
   if(mod(i,1.)<1.){
     a+=I(n0.x+67.0,time,t0,sitar)*n0.y/(3.+abs(n0.x+7.)*.25);
     a+=I(n0.x+72.0,time,t0,sitar)*n0.y/(3.+abs(n0.x+7.)*.25);
   }
   if(mod(i,2.)<1.){//notes that play every 2 beats 
     t1=fract(tim*0.5)*2.0+i;
     //a+=I(n1.x+67.0,time,t1,epiano)*n1.y;
     a+=I(n1.x+65.,time,t1,epiano)*n1.y*.125; 
     a+=I(n1.x+64.,time,t1,epiano)*n1.y*.125; 
     a+=I(n1.x+60.,time,t1,epiano)*n1.y*.125; 
     //a+=I(n1.x+36.0,time,t1,pluckbass)*n1.y*4.0;
     a+=I(n1.x+24.0,t1/bps+0.008*sin(t1*3.0),t1,bassdrum)*2.0;
     //a+=I(n2.x+31.0,t1/bps+0.008*sin(t1*2.0),t1,bassdrum)*2.0;
     
     if(mod(i,4.)<1.){//every 4 
       t2=fract(tim*0.25)*4.0+i;
       a+=I(n2.x+48.0,time,t2,bass)*n2.y;
       a+=I(n2.x+52.0,time,t2,bass)*n2.y;
       a+=I(n2.x+97.0,time+Sin(t2*372.0),t2,stick)*n2.y*.15;
     
      // a+=I(96.0,time,t2,stick)*n2.y*.25;
       
     } 
   } 
   tim-=1.;//go back in time to find old notes still decaying 
 } 
 return clamp(a/48.0,-1.,1.); 
}