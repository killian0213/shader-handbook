//  (sound) — Joy Division by xbe
// https://www.shadertoy.com/view/MslSD2

///////////////////////////////////////////////////////////
// XBE
// Joy Division - Disorder (more or less...)
//
// Instruments from MusicBox2 shader by ztri
//

float tempo = 0.0;
float tune  = 0.0;

vec2 tb303(vec3 k){     
    float s = abs(sin(tune*0.7)+1.0)*0.3;
 	float a = pow(1.0-k.y,0.2);   
 	float f = pow(1.0-k.y,2.0);   
    float osc = sin(k.x*4.40*tune*2.0);
    osc = pow(abs(osc),pow(2000.0,s+(f*0.8)));
  	osc = clamp(osc*1.1,-1.0,1.0)*a;    
    return vec2(osc,osc)*0.3; 
}

vec2 pad(vec3 k){
    float osc = 0.0;
    osc += smoothstep(0.0,0.4,sin(k.x*4.4*tune*8.0));
    osc += smoothstep(0.0,0.4,sin(k.x*4.4*tune*16.1));
    osc += smoothstep(0.0,0.4,sin(k.x*4.4*tune*15.9));
    osc = clamp(pow(osc,0.1),-1.0,1.0);
    osc = osc*smoothstep(1.0,0.0,k.y);  
    return vec2(pow(osc,abs(sin(tune))),pow(osc,abs(cos(tune))))*0.4; 
}

vec2 piano(vec3 k){
    float osc = 0.0;
    osc += sin(k.x*4.4*tune*4.0);
    osc = clamp(pow(abs(osc),20.0),-1.0,1.0);
    osc = osc*smoothstep(1.8,0.0,k.y);  
    return vec2(osc*sin(k.z),osc*cos(k.z*2.0))*0.5; 
}

vec2 kick(vec3 k){
    float a = pow(1.0-k.y,1.0);
    float osc = sin(pow(a,5.0)*k.x);
    return vec2(smoothstep(-0.9,0.9,osc*pow(a,2.0))); 
}

vec2 hat(vec3 k){
    float n = fract(sin(k.x * tune * 110.082) * 19871.8972);
    float a = pow(1.0-k.y,1.0);
  	float osc = clamp(n,-1.0,1.0)*pow(a,8.0+k.x*0.1);    
    return vec2(osc*osc,osc)*0.4; 
}

vec2 clap(vec3 k)
{
    float n = fract(sin(tune * 110.082 * k.x) * 19871.8972);
    float a = pow(1.0-k.y,1.0);
  	float osc = 0.;
    if (k.x>0.)
    {
        osc  = sin(n*a)*a;
        osc += (sin(a*8.4*k.x)*pow(a,8.0-k.x*0.02));
    }
    return vec2(osc,osc); 
}

vec3 pat16(float time,float p1,float p2,float p3,float p4,float p5,float p6,float p7,float p8, float p9, float p10, float p11, float p12, float p13, float p14, float p15, float p16){
    float t = mod(time,16.0);
	if(t>15.0) return vec3(p16,t-15.0,time);    
	if(t>14.0) return vec3(p15,t-14.0,time);    
	if(t>13.0) return vec3(p14,t-13.0,time);    
	if(t>12.0) return vec3(p13,t-12.0,time);    
	if(t>11.0) return vec3(p12,t-11.0,time);    
	if(t>10.0) return vec3(p11,t-10.0,time);    
	if(t>9.0)  return vec3(p10,t-9.0,time);    
	if(t>8.0)  return vec3(p9,t-8.0,time);    
    if(t>7.0)  return vec3(p8,t-7.0,time);    
	if(t>6.0)  return vec3(p7,t-6.0,time);    
	if(t>5.0)  return vec3(p6,t-5.0,time);    
	if(t>4.0)  return vec3(p5,t-4.0,time);    
	if(t>3.0)  return vec3(p4,t-3.0,time);    
	if(t>2.0)  return vec3(p3,t-2.0,time);    
	if(t>1.0)  return vec3(p2,t-1.0,time);    
	if(t>0.0)  return vec3(p1,t,time);    
	return vec3(0.0);
}

vec3 pat8(float time,float p1,float p2,float p3,float p4,float p5,float p6,float p7,float p8)
{
    float t = mod(time,8.0);
    if(t>7.0)  return vec3(p8,t-7.0,time);    
	if(t>6.0)  return vec3(p7,t-6.0,time);    
	if(t>5.0)  return vec3(p6,t-5.0,time);    
	if(t>4.0)  return vec3(p5,t-4.0,time);    
	if(t>3.0)  return vec3(p4,t-3.0,time);    
	if(t>2.0)  return vec3(p3,t-2.0,time);    
	if(t>1.0)  return vec3(p2,t-1.0,time);    
	if(t>0.0)  return vec3(p1,t,time);    
	return vec3(0.0);
}

#define k0 0.
#define k12 19.2
#define k1 38.4
#define k2 76.8
#define h0 0.
#define h1 32.7
#define p0 0.
// guitar
#define F10 349. / 4.4
#define A8s 233. / 4.4
//#define A8 175. / 8.
// bass
#define No	0.
#define Eb 155.6 / 4.4
#define G    98. / 4.4
#define Bb  58.3 / 4.4

vec2 Play(float time)
{  
	vec2 snd = vec2(0.);
    
    tempo = time * 4.6;
    tune  = mod(time, 8.0); // * 1.0;
    
    if (tempo < 24.0)
    {
        snd += 0.25*hat(pat8(tempo, h1,h1,h1,h1, h1,h1,h1,h1));
        snd +=     clap(pat8(tempo, k12,k12,k0,k0, k12,k0,k0,k0));
        snd += 0.5*kick(pat8(tempo, k0,k0,k1,k1, k0,k0,k1,k1));
    }
    else if ((tempo >= 24.0) && (tempo < 28.))
    {
        snd += 0.25*hat(pat8(tempo, h1,h1,h1,h1, h1,h1,h1,h1));
        snd +=     clap(pat8(tempo, k12,k12,k0,k0, k12,k0,k0,k0));
        snd += 0.5*kick(pat8(tempo, k0,k0,k1,k1, k0,k0,k1,k1));
    }
    else if ((tempo >= 28.0) && (tempo < 32.))
    {
        snd +=     clap(pat8(2.*tempo, k12,k12,k12,k12, k0,k0,k0,k0));
        snd += 0.5*kick(pat8(2.*tempo, k0,k0,k0,k0, k1,k1,k1,k1));
    }
    else
    {
        snd += 0.25*hat(pat16(tempo, h1,h1,h1,h1, h1,h1,h1,h1, h1,h1,h1,h1, h1,h1,h1,h1));
	    snd +=     clap(pat16(tempo, k0,k0,k12,k0, k0,k0,k12,k0, k0,k0,k12,k0, k0,k0,k12,k12));
        snd += 0.5*kick(pat16(tempo, k1,k1,k0,k0, k1,k1,k0,k0, k1,k1,k0,k1, k0,k1,k0,k0));
        float mt = mod(tempo, 32.);
        if (mt < 16.)
		    snd += tb303(pat16(mt, Eb,No,Eb,Eb, Eb,Eb,Eb,Eb, G,No,G,G, No,G,G,G));
        else
		    snd += tb303(pat16(mt, Bb,No,Bb,Bb, Bb,Bb,Bb,Bb, G,No,G,G, No,G,G,G));
        if (tempo>96.)
		    snd += 0.5*pad(pat16(tempo, F10,No,A8s,No, F10,No,A8s,No, F10,A8s,No,F10, No,No,A8s,No));
    }
    return snd * smoothstep(0.0,0.5,time) * smoothstep(60.0,59.0,time);
}

vec2 mainSound( in int samp,float time)
{
	vec2 s = vec2(0.0);

    s += Play(time);
    
    return s;
}