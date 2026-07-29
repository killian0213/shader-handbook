// Buffer B (buffer) — Sinuous by nimitz
// https://www.shadertoy.com/view/4sGSDw

//Sinuous by nimitz (twitter: @stormoid)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Contact the author for other licensing options

//Rendering

/*
	This buffer renders each particles
	multiple times per frame to allow particles
	to move more than one pixel per frame while still
	leaving a solid trail.
*/

#define time iTime

//Anywhere under 800 "should" work fine (might slow down though)
const int numParticles = 500;

float mag(vec2 p){return dot(p,p);}

vec4 drawParticles(in vec2 p)
{
    vec4 rez = vec4(0);
    vec2 w = 1./iResolution.xy;
    
    for (int i = 0; i < numParticles; i++)
    {
        vec2 pos = texture(iChannel0, vec2(i,50.0)*w).rg;
        vec2 vel = texture(iChannel0, vec2(i,0.0)*w).rg;
        float d = mag(p - pos);
        d *= 500.;
        d = .01/(pow(d,1.0)+.001);

        //rez.rgb += d*abs(sin(vec3(2.,3.4,1.2)*(time*.01 + float(i)*.0017 + 2.5) + vec3(0.8,0.,1.2))*0.7+0.3)*0.04;
        rez.rgb += d*abs(sin(vec3(2.,3.4,1.2)*(time*.07 + float(i)*.0017 + 2.5) + vec3(0.8,0.,1.2))*0.7+0.3)*0.04;
        pos.xy += vel*0.002*0.2;
    }
    
    return rez;
}

vec3 rotx(vec3 p, float a){
    float s = sin(a), c = cos(a);
    return vec3(p.x, c*p.y - s*p.z, s*p.y + c*p.z);
}

vec3 roty(vec3 p, float a){
    float s = sin(a), c = cos(a);
    return vec3(c*p.x + s*p.z, p.y, -s*p.x + c*p.z);
}

vec3 rotz(vec3 p, float a){
    float s = sin(a), c = cos(a);
    return vec3(c*p.x - s*p.y, s*p.x + c*p.y, p.z);
}

mat2 mm2(in float a){float c = cos(a), s = sin(a);return mat2(c,s,-s,c);}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{	
    vec2 q = fragCoord.xy/iResolution.xy;
	vec2 p = fragCoord.xy/iResolution.xy-0.5;
	p.x*=iResolution.x/iResolution.y;
	vec2 mo = iMouse.xy / iResolution.xy-.5;
    mo = (mo==vec2(-.5))?mo=vec2(-0.15,0.):mo;
	mo.x *= iResolution.x/iResolution.y;
    mo*=6.14;
    
    p *= 1.1;
    
    vec4 cola = drawParticles(p)*0.05;
    
    vec4 colb = 1.-texture(iChannel1, q);
    vec4 col = cola + colb;
    
    vec4 base = 1.-vec4(1,0.98,0.9,0.9)*(1.-mag(p+vec2(-0.20,-.3))*0.1);
    
    float mdf = mod(float(iFrame),1601.);
    
    if (iFrame < 15 || mdf < 2.5) col = base;
    fragColor = 1.-col;
    
}