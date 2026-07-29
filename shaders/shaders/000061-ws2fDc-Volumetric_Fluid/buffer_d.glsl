// Buffer D (buffer) — Volumetric Fluid by wyatt
// https://www.shadertoy.com/view/ws2fDc

Sampler
Sampler1
Main {
	_3D;
    U -= T1(U).xyz;
    U -= T1(U).xyz;
    U -= T1(U).xyz;
    Q = T(U);
    if (length(U-vec3(0.5,.5,0.9)*R3D) < 3.) {

        Q = 0.5+0.5*sin(.1*iTime*vec4(1,2,3,4));
    }
    if (length(U-vec3(0.51,.1,.5)*R3D) < 3. ) {
    	Q = 0.5+0.5*sin(.1*iTime+vec4(4,3,2,1));
    }
    if (length(U-vec3(0.5,.9,.5)*R3D) < 3. ) {
    	Q = 0.5+0.5*sin(.1*iTime-vec4(4,3,2,1));
    }
}