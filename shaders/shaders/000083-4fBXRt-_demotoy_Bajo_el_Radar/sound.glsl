// Sound (sound) — [demotoy] Bajo el Radar by Kali
// https://www.shadertoy.com/view/4fBXRt

#define bpm 30.
#define notes 16.
#define tick 60./bpm
#define tickcount ti*tick
#define note tick/notes
#define notecount ti*notes
#define comp notecount/notes


#define C  32.703
#define CS 34.648
#define D  36.708
#define DS 38.891
#define E  41.203
#define F  43.654
#define FS 46.249
#define G  48.999
#define GS 51.913
#define A  55.0
#define AS 58.270
#define B  61.735

float ti=0.;

float noise( float n )
{
    return fract(sin(n)*43758.5453);
}


float kick(float t, float b, float f, float o) {
	t=mod(t-o*tick/notes,b/60.);
    return (sin(.3+t*f))*exp(-5.0*t);
}

float snare(float t, float b, float f, float o) {
	t=mod(t-o*tick/notes,b/60.);
    return (sin(.1+t*f*10.)+noise(t*f))*exp(-15.0*t);
}

float hithat(float t, float b, float f, float o) {
	t=mod(t-o*tick/notes,b/60.);
    return noise(t*f)*exp(-25.0*t);
}

float bass(float t, float b, float f, float o) {
	t=mod(t-o*tick/notes,b/60.);
    return exp(-.3*max(0.,1.-t))*clamp((.5-mod(t*f,1.)),-.1,.1)*exp(-50.0*t*t)*5.;
}

float chords(float t, float b, float f, float o) {
	t+=noise(t*.21358)*.0002;
    t=mod(t-o*tick/notes,b/60.);
    float c=min(1.,sqrt(abs(t))*.5)*clamp(sin(t*f*50.+sin(t*f*50.)*10.),-.4,.4)*exp(-35.0*t*t);
    t-=.5;
	c+=min(1.,sqrt(abs(t))*.5)*clamp(sin(t*f*50.+sin(t*f*50.)*10.),-.4,.4)*exp(-35.0*t*t)*.5;
    return c*.7;

}

float lead(float t, float b, float f, float o) {
    t=mod(t-o*tick/notes,b/60.);
	t*=3.2;
	t+=noise(ti*.25)*.002;
    float c=(1.-mod(t*f*10.,2.))+(1.-mod(t*f*5.,2.));
	c=smoothstep(-.5,.5,clamp(c,-.5,.5));
    c*=max(0.5,sin(t*note*128.));
    return c*.2;

}



float bassnotes1(float n) {

	float s=0.;
    s=C*step(0.,n)*(1.-step(2.,n));
    s+=C*step(6.,n)*(1.-step(8.,n))*2.;
    s+=D*step(8.,n)*(1.-step(10.,n))*2.;
    s+=D*step(12.,n)*(1.-step(14.,n));
    s+=D*step(14.,n)*(1.-step(15.,n))*2.;
    return s;

}

float leadnotes(float n) {

	float s=0.;
    s=D*step(0.,n)*(1.-step(2.,n));
    s+=E*step(2.,n)*(1.-step(4.,n));
    s+=A*.5*step(4.,n)*(1.-step(5.,n));
    s+=G*.5*step(5.,n)*(1.-step(6.,n));
    s+=C*step(6.,n)*(1.-step(8.,n));
    s+=E*.5*step(8.,n)*(1.-step(16.,n));
    s+=D*step(16.,n)*(1.-step(18.,n));
    s+=E*step(18.,n)*(1.-step(20.,n));
    s+=A*.5*step(20.,n)*(1.-step(21.,n));
    s+=G*.5*step(21.,n)*(1.-step(22.,n));
    s+=F*.5*step(22.,n)*(1.-step(26.,n));
    s+=C*.5*step(26.,n);
    
    
    return s;

}




vec2 mainSound( in int samp,float time)
{
    
    
    float basss;
	//time+=20.;
    ti=time;
    float s=0.;
    s+=fract(time*500.)*.2*step(.5,fract(time*5.))*step(48.,time);
	float ch=0.;
     if (comp<21.) {
    	ch=chords(time,bpm,D,0.);
		ch+=chords(time,bpm,F,1.);
		ch+=chords(time,bpm,A,2.);
    } else if (comp>25.) {
        ch=chords(time,bpm,F,0.);
		ch+=chords(time,bpm,A,1.);
		ch+=chords(time,bpm,C,2.);
		ch+=chords(time,bpm,mod(comp,4.)>2.?E:D,3.);
		ch*=min(1.,(comp-25.)*.1);
    } else ch=0.;
    if (comp>5.) kick(time,bpm,100.,0.)*2.;
	if (comp>7.) s+=kick(time,bpm*4.,300.,2.);
	if (comp>2.) s+=snare(time,bpm*2.,50.,4.)*.3;
	if (comp>9.) s+=snare(time,bpm*8.,80.,2.)*.2;
	if (comp>11.) s+=snare(time,bpm*8.,50.,6.)*.2;
	if (comp>0.) s+=hithat(time,bpm,50.,0.)*.15;
	if (comp>2.) s+=hithat(time,bpm,10.,2.)*.15;
	if (comp>21.) s+=hithat(time,bpm*.5,100.,1.)*.1;
	float ll=lead(time,bpm,leadnotes(comp-23.),0.)*.5
        			+lead(time,bpm,leadnotes(comp-24.),0.)*.3;
	
    if (comp>23.) s+=ll;
    if (comp>30.) time+=noise(ti*.15)*.002;
    if (comp>21.) basss=bass(time,bpm*.5,bassnotes1(mod(notecount,16.)),0.)*.7; 
    			else basss=bass(time,bpm*.5,D,0.)*min(1.,time*time*.01)*.5;
    if (comp>4.) s+=basss;
    if (comp>7.) s+=ch;
    if (abs(floor(comp)-19.)<2.) s=basss*.5+sin(ti*ti*ti*1000.)*.05;
    if (comp>52.) s=(ll+basss+sin(sin(ti*ti*.1+1.5+noise(ti*.5)*.001)*1000.)*.1)*exp(-.4*(comp-52.));
   
    s*=min(1.,ti*.3);
    return vec2(sin(tickcount*4.),cos(tickcount*4.))*s;
}