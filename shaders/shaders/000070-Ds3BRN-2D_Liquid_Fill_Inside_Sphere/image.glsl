// Image (image) — 2D Liquid Fill Inside Sphere by Mirza
// https://www.shadertoy.com/view/Ds3BRN

// 2D liquid inside 'sphere' shader.

// Author: Mirza Beig

// https://twitter.com/TheMirzaBeig
// https://www.youtube.com/@MirzaBeig

// Feel free to use this however you want.
// Modify, learn from it, copy-paste, etc...

// This is the compact version of:
// > https://www.shadertoy.com/view/Ds3fRN

/*

INFO:

sdf = gradient for circle.
vB, vbA = vertical band, +animated.

fW, bW = front waves, back waves.

fA = fill animation, just a simple, constant (small) wave.
fP = fill progress, where 0.0 = center.

fV = fill value.

Set as normalized and centered (-0.5 * 2.0) mouse Y (for interactivity).
Uses mix and step in place of a bool to check if mouse button is held down.

fF, bF = front fill, back fill.

*/

#define PI 3.14

// Optional anti-aliasing, as per suggestion by u/fishy:

#define step(b, a) smoothstep(a, a - (fwidth(b) * 2.0), b)

void mainImage(out vec4 col, in vec2 uv)
{
    vec3 r=iResolution;
    uv=((2.*uv)-r.xy)/r.y;

    float
		sdf=length(uv),c=step(sdf,.85),
		
        vB=smoothstep(.1,.9,sin(uv.x+(PI*.5))-.3),
		vBA=vB*sin(iTime*4.)*.1,
        
        fW=(sin(((iTime*2.)+uv.x)*2.)*.05)+vBA,
		bW=(sin(((iTime*-2.)+uv.x)*2.+PI)*.05)-vBA,
		
        fA=(sin(iTime*4.)*.05)*vB,
        
        fV=mix(-.2,((iMouse.y/r.y)-.5)*2.,step(0.,iMouse.w)),
        fP=fV+(sin((iTime)*PI)*.1),
		
        fF=step(uv.y,(fA+fW)+fP)*c,
		bF=step(uv.y,(-fA+bW)+fP)*c;

    col =
		vec4((step(sdf,1.)-step(sdf,.9))+
		(fF+(clamp(bF-fF,0.,1.)*.8))+
		clamp(pow((sdf+.01)*
		((1.-(fF+bF))*c),5.),0.,1.));
}