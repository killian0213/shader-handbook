// Buffer B (buffer) — Fluid 3D Volumetric* by wyatt
// https://www.shadertoy.com/view/WsSXRy

// Fluid Color
void mainImage( out vec4 Q, in vec2 U )
{	R = iResolution.xy;
 	vec3 o = d3(U);
 	Q = 0.9997*s3d(iChannel1,o-s3d(iChannel0,o).xyz);
 
 	Q.xyz = mix(Q.xyz,0.5+0.5*sin(.2*iTime*vec3(1,2,3)),smoothstep(0.,-.01,length(o-0.5*vec3(R/N,N*N)) - max(2.,0.01*R.x/N)));
   
    if (iFrame < 1) Q = vec4(0);
}