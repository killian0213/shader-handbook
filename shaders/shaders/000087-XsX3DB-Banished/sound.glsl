// Sound (sound) — Banished by Dave_Hoskins
// https://www.shadertoy.com/view/XsX3DB

//======================================================================================================
vec2 Rain(float n)
{
    // Splattering on roof sound mixed with ambient noise.
    float vary = sin(n * .1) * .5;
    vec2 pos = vec2(n * (5.7331+vary), n * (43.66927 - vary));
    // High pass the sound by subtracting a lower mipmap...
    vec2 top = (texture( iChannel0, pos, -100.0).xy) * 2.0;
    vec2 bot = (texture( iChannel0, pos,   -5.7).xy) * 2.0;
    
	return top-bot + (texture( iChannel1, pos,   -100.0).xy-.5)* .5;
}

//======================================================================================================
vec2 Thunder(float n, float pitch, float time)
{
    vec2 top = (texture( iChannel0, vec2(n*pitch*4.88238+time, n*pitch*3.834181), -100.0).xz-.5)* 2.0;
	return top;
}

//======================================================================================================
float Noise(float n)
{
    return (texture( iChannel1, vec2(n*343.88238, n*153.834181), -100.0).x-.5)* 2.0;
}

//======================================================================================================
vec2 mainSound( in int samp,float time)
{
    vec2 audio = Rain(time) * .6;
    
    float ti  = mod(time - .4, 12.0);
	float lightning = smoothstep(1.5, 2.2, ti) * smoothstep(9.0, 2.2, ti);
    audio += Thunder(ti, lightning + .75, time) * lightning;
    
    ti = mod(time, 9.0);
	float nose = smoothstep(3.0, 3.1, ti)* smoothstep(3.2, 3.1, ti)*.6;
	nose += smoothstep(3.2, 3.3, ti)* smoothstep(3.5, 3.3, ti)*.3;
	nose += smoothstep(3.7, 3.9, ti)* smoothstep(4.4, 3.8, ti)*.7;
    float sniff = Noise(time) * nose;
  	audio += vec2(sniff);

    return clamp(audio, -1.0, 1.0) * (smoothstep(0.0, 3.0, time) * smoothstep(250.0, 240.0, time));
}