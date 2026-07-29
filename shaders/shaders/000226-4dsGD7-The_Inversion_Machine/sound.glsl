// Sound (sound) — The Inversion Machine by Kali
// https://www.shadertoy.com/view/4dsGD7

float rand(vec2 co){
	return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}


vec2 mainSound( in int samp,float time)
{
	float ti=time;
    vec2 s=vec2(0.);
    float t=mod(time,10.)-5.;
    float tb=mod(time,.3);
	float x=t*.1;
	//fractal sound
    for (int i=0;i<23;i++) {
    	x=1.3/abs(x)-1.; 	   
    }
    s+=x*2.;
	//noise
	ti*=5.;
    s+=vec2(rand(vec2(ti,1234.258-ti*2.568))*sin(time*100.),0.)*4.;
	ti*=2.;
    s+=vec2(0.,rand(vec2(ti,1234.258-time*2.568))*sin(time*100.))*4.;
	ti*=.02;
    //pulse
	s*=.2;
	tb-=x*.0003;
    s+=vec2(sin(time),cos(time))*sin(tb*tb*4000.)*exp(-15.*tb)*20.;
	s+=(1.-mod(time*(2000.+sin(t*t)*100.)+x*.2,2.))*.7;
    //starting noise
	s*=clamp(time*.2,0.,1.);
    s=mix(s,vec2(rand(vec2(ti*1.5,1234.258-ti*2.568))-.3)*10.,clamp(1.-time*.5,0.,1.));
    return vec2(s)*.5*clamp(60.-time,0.,1.);
}