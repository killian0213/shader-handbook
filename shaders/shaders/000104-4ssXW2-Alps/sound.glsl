// Sound (sound) — Alps by Dave_Hoskins
// https://www.shadertoy.com/view/4ssXW2


vec2 Hash( vec2 n)
{
	vec4 p = textureLod( iChannel0, n*vec2(.78271, .32837), 0.0 );
    return (p.xy + p.zw) * .5; 
}

//--------------------------------------------------------------------------
vec2 Noise( in vec2 x )
{
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    vec2 res = mix(mix( Hash(p + 0.0), Hash(p + vec2(1.0, 0.0)),f.x),
                   mix( Hash(p + vec2(0.0, 1.0) ), Hash(p + vec2(1.0, 1.0)),f.x),f.y);
    return res-.5;
}

//--------------------------------------------------------------------------
vec2 FBM( vec2 p )
{
    vec2 f;
	f  = 0.5000	 * Noise(p); p = p * 2.32;
	f += 0.2500  * Noise(p); p = p * 2.23;
	f += 0.1250  * Noise(p); p = p * 2.31;
    f += 0.0625  * Noise(p); p = p * 2.28;
    f += 0.03125 * Noise(p);
    return f;
}

//--------------------------------------------------------------------------
vec2 Wind(float n)
{
    vec2 pos = vec2(n * (162.017331), n * (132.066927));
    vec2 vol = Noise(vec2(n*23.131, -n*42.13254))*1.0 + 1.0;
    
    vec2 noise = vec2(FBM(pos*33.313))* vol.x *.5 + vec2(FBM(pos*4.519)) * vol.y;
    
	return noise;
}

//--------------------------------------------------------------------------
vec2 mainSound( in int samp,float time)
{
    vec2 audio = Wind(time*.1) * 6.0;
    return clamp(audio, -1.0, 1.0) * (smoothstep(0.0, 2.0, time) * smoothstep(180.0, 175.0, time));;
}