// Sound (sound) — Path Racers by friol
// https://www.shadertoy.com/view/3s2BzV

//
// bytebeat
//

#define PI 3.141592
#define TAU PI*2.0


float notes[12];


//
//
//

float modfix(float phase) {
    return mod(phase, TAU);
}

float sinf(float t, float freq) {
	return sin(modfix(TAU * t * freq));
}

float kick(float t) 
{
    return clamp(1.25 * sinf(t, 120. * exp(-t * 5.0)) * exp(-t * 5.), -1.0, 1.0) * smoothstep(0.001, 0.003, t);
}

//
// saw
//

float sawpitch(float p) {
	return pow(1.059460646483, p) * 440.0;
}

float saw(float phase) 
{
    float s = 0.0;
    for (int k=1; k < 17; k++) {
        s += (sin(TAU*float(k)*phase) / float(k));
    }
    return -(1.0/PI)*s;
}

vec2 sawSynth(float t,vec3 notes)
{
    // good triads: 0,2,7 0,3,7 0,3,2
    float s = 0.0;
    float semitones[3];
    semitones[0] = notes.x;
    semitones[1] = notes.y;
    semitones[2] = notes.z;
    
    for (int i=0;i<3;i++) 
    {
        float f = sawpitch(semitones[i]);
        
        for (int u=0;u<3;u++) {
            float fu = float(u);
            float new_f = f + fu*sin(fu);
    		s += saw(t * new_f)*0.11111111111111;
        }
    }
    
    return vec2(
        s*clamp((1.0+cos(t))/2.0,0.25,0.75),
        s*clamp((1.0+sin(t))/2.0,0.25,0.75)
    );
}

// synthie

float pulse( float morph, float pulse, float phase )
{
	float a, b;
    if( pulse < 0.5 )
        a = morph * pulse * 0.5;
    else
        a = morph * ( 1.0 - pulse ) / 2.0;
    if( phase < pulse )
    {
        if( phase < a )
        {
            b = phase / a - 1.0;
            return 1.0 - b * b;
        }
        if( phase < pulse - a )
            return 1.0;
        b = ( phase - pulse + a ) / a;
        return 1.0 - b * b;
    }
    if( phase < pulse + a )
    {
        b = ( phase - pulse ) / a - 1.0;
        return b * b - 1.0;
    }
    if( phase <= 1.0 - a )
        return -1.0;
    b = ( phase - 1.0 + a ) / a;
    return b * b - 1.0;
}

vec2 synthie(float time,float note1,float note2)
{
	float y=time*globalTempo/240.0;
    float a=16.0;
    float s=1.0;
    float b=16.0;
    float bi=floor(b*y);
    float w=b*y-bi;
    float sqe=pow(min(1.0,min(s-s*w,a*w)),2.0)*(3.0-mod(bi,3.0));
    float x=time*note1;
    float x2=time*note2;
    
    float wave=
        pulse(0.75, 0.75, fract(x))+pulse(0.9+sin(y*2.0/16.0)*0.1-sqe*0.1, 0.5+0.45*sin(y*16.0), fract(x))+
        pulse(0.75, 0.75, fract(x2))+pulse(0.9+sin(y*2.0/16.0)*0.1-sqe*0.1, 0.5+0.45*sin(y*16.0), fract(x2));
        
    
    return ((1.0+0.5*sin(time))/2.0)*vec2(
        (wave*sqe*0.07)*clamp((1.0+sin(time))/2.,0.25,0.75),
        (wave*sqe*0.07)*clamp((1.0+cos(time))/2.,0.25,0.75)
    );
}

// snare

vec2 sine(float time, float freq) {
    return vec2(sin(time * freq * 3.1415 * 2.));
}

vec2 noise(float a, float b) {
    return vec2(2. * (0.5 - fract(sin(dot(vec2(a, b) ,vec2(12.9898,78.213))) * 42758.5453)));
}

vec2 exp_noise(float time, float b, float q) {
    return vec2(noise(time, b) * exp(-time * q));
}

vec2 exp_sine(float time, float freq, float q) {
    return vec2(sine(time, freq)) * exp(-time * q);
}

vec2 snare(float time) {
    return exp_noise(time, 1., 20.) * 0.3 + exp_sine(time, 200. * exp(-time), 50.) * 0.7;
}

vec2 tom(float time) {
    return exp_sine(time, 60. * exp(-time), 25.);
}

vec2 finalSnare(float time,float panning)
{
    return 0.9 * vec2(
        (tom(fract(time)) + snare(fract(time))).x*panning,
        (tom(fract(time)) + snare(fract(time))).y*(1.0-panning)
        );
}

// hi-hat

vec2 hihat(float time,float panning)
{
    float tb = mod(time,(60.0/globalTempo)*0.25);
    float hihat=(fract(cos(time * 32234.523) * 134.) * exp(mod(tb, 1. / 2.0) / 2.0 * -120.)*(fract(tb) + .2));
    return vec2(hihat*panning,hihat*(1.0-panning))*.55;
}

#define hihatsss(starttime,endtime,panning) if ((time>=starttime)&&(time<endtime)) finalSound+=hihat(time,panning);

// bazzz

float adsr(float t, vec4 env, float s)
{
    float a = t/env.x;
    float d = max(s, 1.0-(t-env.x)*(1.0-s)/env.y);
    float r = (1.0 - max(0.0,t-(env.x+env.y+env.z))/env.w);
    return max(0.,min(a, r*d));
}

float sineBazz(float phase, float time, float note) 
{
    return sin (TAU*note*4.0*phase)*exp(-3.*phase);
}

void initNotes()
{
	notes[0]=16.055;
    notes[1]=17.01;
    notes[2]=18.02;
    notes[3]=19.09;
    notes[4]=20.225;
    notes[5]=21.43;
    notes[6]=22.705;
    notes[7]=24.055;
    notes[8]=25.485;
    notes[9]=27.00;
    notes[10]=28.605;
    notes[11]=30.305;
}

vec2 mainSound( in int samp, float time )
{
    vec2 finalSound=vec2(0.0);
    
    initNotes();

    if (time>=(60.0/globalTempo)*32.)
    {
        if ((time>=(60.0/globalTempo)*31.5)&&(time<(60.0/globalTempo)*120.0))
        {
            finalSound += kick(mod(time,60.0/globalTempo))*0.5;
        }

        const int numSteps=16;
        int notearr[16];
        notearr[0]=0;notearr[1]=3;notearr[2]=0;notearr[3]=6;
        notearr[4]=0;notearr[5]=0;notearr[6]=0;notearr[7]=0;
        notearr[8]=0;notearr[9]=3;notearr[10]=0;notearr[11]=5;
        notearr[12]=6;notearr[13]=1;notearr[14]=0;notearr[15]=5;

        float note=notes[notearr[int(mod((floor(time/(60.0/globalTempo))),16.0))]];
        float b = sineBazz(mod (time, (60.0/globalTempo)*0.25), time,note);

        b = adsr(b, vec4(1.1, .1, 1.9, 1.0), 1.0)*(.9+.5*abs(sin(time)));
        b *= b*b;
        finalSound+=b*0.15;

        hihatsss((60.0/globalTempo)*32.,(60.0/globalTempo)*36.0,0.30);
        hihatsss((60.0/globalTempo)*40.,(60.0/globalTempo)*44.0,0.30);
        hihatsss((60.0/globalTempo)*48.,(60.0/globalTempo)*52.0,0.30);
        hihatsss((60.0/globalTempo)*56.,(60.0/globalTempo)*60.0,0.30);
        hihatsss((60.0/globalTempo)*64.0,(60.0/globalTempo)*96.0,0.30);
        
		if (time>(60.0/globalTempo)*96.0) finalSound+=sawSynth(mod(time-(60.0/globalTempo)*96.0,32.0*(60.0/globalTempo)),vec3(12.+7.8))*0.02;
    }

    if (
        (time>=(60.0/globalTempo)*32.) &&
        (time<(60.0/globalTempo)*96.0)
       )
    {
        finalSound+=finalSnare(fract(mod((time+0.45),2.0*60.0/globalTempo)),0.65)*0.6;
        if (time>=(60.0/globalTempo)*64.) finalSound+=finalSnare(fract(mod((time+.55),4.*60.0/globalTempo)),0.35)*0.6;
    }

    // open all
    if (time>=(60.0/globalTempo)*126.)
    {
        finalSound += kick(mod(time,60.0/globalTempo))*0.5;
        hihatsss((60.0/globalTempo)*120.0,(60.0/globalTempo)*256.0,0.30);
        finalSound+=finalSnare(fract(mod((time+0.45),2.0*60.0/globalTempo)),0.65)*0.6;
		finalSound+=finalSnare(fract(mod((time+.55),4.*60.0/globalTempo)),0.35)*0.6;
    }
    
    time=mod(time,(60.0/globalTempo)*32.0);
    if (time<(60.0/globalTempo)*16.0) finalSound+=synthie(time,notes[0]*16.0,notes[3]*18.0)*0.4;
    else finalSound+=synthie(time,notes[3]*12.0,notes[8]*12.0)*0.4;

    
    return finalSound*1.2;
}
