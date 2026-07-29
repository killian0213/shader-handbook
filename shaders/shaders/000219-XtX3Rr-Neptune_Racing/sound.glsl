// Sound (sound) — Neptune Racing by Dave_Hoskins
// https://www.shadertoy.com/view/XtX3Rr

//--------------------------------------------------------------------------
vec3 CameraPath( float t )
{
    float s = smoothstep(.0, 3.0, t);
	vec3 pos = vec3( t*30.0*s +120.0, 1.0, t* 220.* s -80.0);
	
	float a = t/4.0;
	pos.xz += vec2(1350.0 * cos(a), 350.0*sin(a));
    pos.xz += vec2(1400.0 * sin(-a*1.8), 400.0*cos(-a*4.43));

	return pos;
}

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
float rockets(float t)
{
    t  = texture(iChannel0, vec2(t*.3, t*.1731), -100.0).x-.5;
    t += texture(iChannel0, vec2(t*.2, t*.01731), -100.0).t-.5;
    return t;
}

vec2 mainSound( in int samp,float time)
{
    float gTime = (time+135.0)*.25;
    vec3 ca = CameraPath(gTime);
    vec3 ct = CameraPath(gTime+.05);
    float f = length(ct-ca)*.1;
    vec2 audio;
    audio = FBM(vec2(gTime*120.0, gTime*1200.0)) * 5.0 * f;
    audio += FBM(vec2(gTime*200.0* f, gTime*200.0)) * 4.5;
    audio *= .1;
    
    float g = mod(f*gTime, 8.0);
    //audio *= g < 4.0 ? 1.0:0.0;
    return audio * smoothstep(.0, 2.0, time) * smoothstep(180.0, 170.0, time);
}