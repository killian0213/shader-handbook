// Sound (sound) — Homeward by Dave_Hoskins
// https://www.shadertoy.com/view/Xllfzl

// Wind and Crow sound effects.
// Usees a formant graph to approximate the CAW sound.
// by David Hoskins.
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.


//----------------------------------------------------------------------------------------
//  1 out, 1 in ...
float shash11(float p)
{
	vec2 p2 = fract(vec2(p) * vec2(.16632,.17369));
    p2 += dot(p2.yx, p2.xy+19.19);
	return fract(p2.x * p2.y)-.5;
}
//----------------------------------------------------------------------------------------
//  2 out, 1 in...
vec2 shash21(float p)
{
	//p  = fract(p * MOD3);
    vec3 p3 = fract(vec3(p) * vec3(.16532,.17369,.15787));
    p3 += dot(p3.xyz, p3.yzx + 19.19);
   return fract(vec2(p3.x * p3.y, p3.z*p3.x))-.5;
}

//----------------------------------------------------------------------------------------
///  2 out, 2 in...
vec2 shash22(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * vec3(.16532,.17369,.15787));
    p3 += dot(p3.zxy, p3.yxz+19.19);
    return fract(vec2(p3.x * p3.y, p3.z*p3.x))-.5;
}

//----------------------------------------------------------------------------------------
//  2 out, 1 in...
vec2 Noise21(float x)
{
    float p = floor(x);
    float f = fract(x);
    f = f*f*(3.0-2.0*f);
    return  mix( shash21(p), shash21(p + 1.0), f)-.5;
    
}

//----------------------------------------------------------------------------------------
//  2 out, 1 in...
float Noise11(float x)
{
    float p = floor(x);
    float f = fract(x);
    f = f*f*(3.0-2.0*f);
    return mix( shash11(p), shash11(p + 1.0), f);

}

//----------------------------------------------------------------------------------------
//  2 out, 2 in...
vec2 Noise22(vec2 x)
{
    const vec2 add = vec2(1.0, 0.0);
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    vec2 res = mix(mix( shash22(p),          shash22(p + add.xy),f.x),
                   mix( shash22(p + add.yx), shash22(p + add.xx),f.x),f.y);
    return res;
}
#define F(p1, p2, p3, p4, p5) {d+=0.00625; f123 = ivec4(p2, p3, p4, p5);}
#define TAU  6.28318530718
#define PI TAU*.5;
//----------------------------------------------------------------------------------
float Tract(float x, float f, float bandwidth)
{
    float ret = sin(TAU * f * x) * exp(-bandwidth * 3.14159265359 * x)*(Noise11(f));
    return ret;
}
float crow(float time)
{
   	float	x = 0.0;
    time -= 1.0;
 
    float t = mod(time, 12.);
    float p = Noise11(floor(time/12.0)*33.0)*.002+.008;
    float v = smoothstep(0.,.01, t)*smoothstep(0.5,.49, t);
    x = mod(t, p + t * t * smoothstep(0.2, .5, t)*.002+t*smoothstep(0.2, .0, t)*.004);
    vec4 formants = vec4(1500.0, 1900., 2408., 3268.);
    
	float glot = 	Tract(x, formants.x, 200.0)  +
       		Tract(x, formants.y, 100.0)  * .8 +
       		Tract(x, formants.z, 90.0) * .6 +
   			Tract(x, formants.w, 90.0) * .5;
     glot *= sin(time*3.3)*.5+1.0;
	
	return glot*v*3.;
}
//----------------------------------------------------------------------------------------
// Fractal Brownian Motion...
vec2 FBM22(vec2 x)
{
    vec2 r = vec2(0.0);
    
    float a = .7;
    
    for (int i = 0; i < 8; i++)
    {
        r += Noise22(x) * a;
        a *= .5;
        x *= 2.0;
        x += 10.;
    }
     
    return r;
}

//----------------------------------------------------------------------------------------
vec2 mainSound( in int samp,float time)
{
	vec2 audio = vec2(.0);
    vec2 n1 = FBM22( vec2(time*520., time*530.) * (Noise21(time*.2+9.)*.2+1.)) * (Noise21(time*.5)+1.);
	vec2 n2 = FBM22( vec2(time*1800., time*900.) * (Noise21(time*.1)*.2+1.))  * (Noise21(time*.2)+1.);

    audio += (n1+n2)/2.0;
    
    audio+= (crow(time)+crow(time+.02)+crow(time+.04))*.2;  // ...Not very good, but it has a little style of its own...
    audio.x+= crow(time-.25)*.15;
    audio.y+= crow(time-.5)*.1;

 //   float foot = tri(time*3.);
//    audio += Noise11(time*10.0)*Noise11(time*500.0)*Noise11(time*3000.0)* smoothstep(0.6,1.,abs(foot)) * 6.;
    
    return clamp(audio, -1.0, 1.0) * smoothstep(0.0, .6, time) * smoothstep(180.0, 170.0, time);
    
}