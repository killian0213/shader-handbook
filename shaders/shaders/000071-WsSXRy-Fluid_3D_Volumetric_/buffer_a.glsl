// Buffer A (buffer) — Fluid 3D Volumetric* by wyatt
// https://www.shadertoy.com/view/WsSXRy

//Fluid Velocity
#define s 0.16666666666
void X (inout vec4 Q, vec4 me, vec4 me1, vec3 o, vec3 r) {
	vec4 n = s3d1(iChannel0,o+r);
	Q  += s*vec4(
    	r*(n.w-me.w),       // pressure force
        dot(r,n.xyz-me.xyz)+n.w-me.w // pressure calculation
    );
}
void mainImage( out vec4 Q, in vec2 U )
{	R = iResolution.xy;
    vec3 o = d3(U);
    Q = s3d1(iChannel0,o);
 	vec4 me = Q, me1 = s3d1(iChannel2,o);
 	
 	X(Q,me,me1,o, vec3(1,0,0));
 	X(Q,me,me1,o, vec3(0,1,0));
 	X(Q,me,me1,o, vec3(0,0,1));
    X(Q,me,me1,o,-vec3(1,0,0));
 	X(Q,me,me1,o,-vec3(0,1,0));
 	X(Q,me,me1,o,-vec3(0,0,1));
 	
 
   if (o.x < 1. || R.x/N-o.x < 1.)Q.xyz*=0.;
   if (o.y < 1. || R.y/N-o.y < 1.)Q.xyz*=0.;
   if (o.z < .8 || N*N - o.z < 1.1)Q.xyz*=0.;
   float i = float (iFrame)/60.;
   Q.xyz = mix(Q.xyz,0.5*vec3(cos(.4*i),sin(.4*i),.5*cos(.8*i)),smoothstep(0.,-.1,length(o-0.5*vec3(R/N,N*N)) - max(2.,0.01*R.x/N)));
   if (iFrame < 1) Q = vec4(0);
}