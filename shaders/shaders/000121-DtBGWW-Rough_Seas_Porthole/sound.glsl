// Sound (sound) — Rough Seas Porthole by Dave_Hoskins
// https://www.shadertoy.com/view/DtBGWW



// Rough Seas 🌊, by Dave Hoskins.

// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// By David Hoskins, 2022.



float fader(float edge0, float edge1, float x)
{
    float t = (x - edge0) / (edge1 - edge0);
    return  clamp(exp((t-.9825)*3.)-.0525, 0.0, 1.0);
}

vec2 hash21(float p)
{
	vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
	p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}

/*
#define UI0 1597334673U
#define UI1 3812015801U
#define UI2 uvec2(UI0, UI1)
#define UI3 uvec3(UI0, UI1, 2798796415U)
#define UI4 uvec4(UI3, 1979697957U)
#define UIF (1.0 / float(0xffffffffU))
vec2 ihash21(float p)
{
	uvec2 n = uint(int(p)) * UI2;
	n = (n.x ^ n.y) * UI2;
	return vec2(n) * UIF;
}
*/

vec2 noise2D(in float p)
{
	float f = fract(p);
    p = floor(p);
    f = f * f * (3.0 - 2.0 * f);
    vec2 res = mix(hash21(p), hash21(p + 1.0), f);
    return res-.5;
}


vec2 mainSound( int samp, float time )
{
    vec2 v, aud;
    float t = time;
    
    
    // Add vary volumes of different frequencies...
    // Magic numbers again, sorry folks...
    v = noise2D(t*.6)*.5+.5;
    v = v*v*3.0;
    aud = noise2D(t*320.+sin(t*.1)*100.) * v;
    
    v = noise2D(t*.3)*.8+.2;
    v = v*v*3.0;
    aud += noise2D(t*600.)*v;

    v = noise2D(-t*.3)*.8;
    aud += noise2D(t*1300.)*v;

    v = noise2D(-t*.5)*.6;
    aud += noise2D(t*2200.)*v;


    v = (noise2D(-t*.4)+noise2D(-t*.3))*.3;
    aud += noise2D(t*4400.)*v;

    v = (noise2D(t*.7) +noise2D(t*.22))*.25;
    v = v*v*4.0;
    aud += noise2D(t*7500.)*v;
    
    v = (noise2D(t*.4) +noise2D(t*.3))*.25;
    v = v*v*4.0;
    aud += noise2D(t*10000.)*v;
    


    aud = clamp(aud*.9, -1.0, 1.0);// Clamp it properly
    aud = 1.5*aud-.5*aud*aud*aud; // Loudness
    aud *= fader(.0, 3.0,time) * fader(180.0, 170.0,time); // Fade in and out.
    
    return aud;
}