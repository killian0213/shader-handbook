// Sound (sound) — Everything's A Caustic by wyatt
// https://www.shadertoy.com/view/WdBGDm

#define pi2 6.2831
#define m_c 261.625565
#define pw 1.05946309436
vec3 hash31(float p) // Dave Hoskins
{
   vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
   p3 += dot(p3, p3.yzx+19.19);
   return fract((p3.xxy+p3.yzz)*p3.zyx); 
}
float X (
    	 float time,
    	 float phase,
    	 float octave, 
         float note, 
         float attack,
         float sustain,
         float release,
         float nl
        ) {
    float phi = phase*pi2;
    float w = m_c*pi2*exp2(octave)*pow(pw,note);
    float envelope = smoothstep(0.,attack,time-phase)*smoothstep(release,0.,time-phase-attack-sustain);
    return (cos(w*time-phi+50.*cos(0.001*nl*w*time))+cos(0.25*w*time-phi+30.*cos(0.002*nl*w*time)))*envelope;
}

vec2 mainSound( in int samp, float t )
{
    float a = 0.;
    #define N 15.
   for (float i = 0.; i < N; i++) {
    t += 0.01;
    float time = 0.;
    float note = 0.;
    float root = 0.;
    float octave = 1.;
    vec3 h;
    float d=1.;
    time = floor(t);
    h = hash31(time);
    root = floor(h.x*12.)-12.;
    h = hash31(time+i);
    if (h.x>0.4) {
        d *= 0.5;
    	time = floor(t);
        h = hash31(2.*time+i*100.);
        if (h.x>0.6) {
            d *= 0.5;
            time = floor(t*2.)/2.;
            h = hash31(20.*time+i*120.);
        }
    }
    note = 2.*floor(h.z*6.)-4.;
    
    
    
    a += 0.5*X (t,time,octave,root+note,0.01*d,0.9*d,0.1*d,0.2*h.x);
        
   }
    
    return vec2(a)/N;
}