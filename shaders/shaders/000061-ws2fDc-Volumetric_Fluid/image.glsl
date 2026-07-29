// Image (image) — Volumetric Fluid by wyatt
// https://www.shadertoy.com/view/ws2fDc

Sampler
Main
{
    vec3 mi = 0.5*vec3(R/N,N*N);
    vec3 p = vec3(0,0,-R.y/N);
    vec3 d = normalize(vec3((u-0.5*R)/R.y,1));
    if (iMouse.z>0.) {
 		p.zx *= e(6.2*iMouse.x/R.x);
		d.zx *= e(6.2*iMouse.x/R.x);
        p.yz *= e(6.2*iMouse.y/R.y);
		d.yz *= e(6.2*iMouse.y/R.y);
    } else {
		p.xz *= e(.2*iTime);
		d.xz *= e(.2*iTime);
        
		p.yz *= e(.05*iTime);
		d.yz *= e(.05*iTime);
	}
    Q = vec4(0);
    for (int i = 0; i < 100; i++) {
        vec3 o = abs(p)-mi;
        float m = length(max(o,0.));
        if (m<.01)
        { 	
            vec4 a = 25.*T(p+mi);
            float aa = length(a);
            Q += 6e-3*(1.-exp(-aa))*abs(a);
            p += d*(.1+exp(-.1*aa*aa));
           //p = mod(p+mi,R3D)-mi;
        } else p += d*m;
        
 	}
	Q = atan(Q)*.8;
}
