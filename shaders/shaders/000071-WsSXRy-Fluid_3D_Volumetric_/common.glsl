// Common (common) — Fluid 3D Volumetric* by wyatt
// https://www.shadertoy.com/view/WsSXRy

// 3D utilities 
#define N 7.
vec2 R;
//  [ [0,R/N]; [0,N*N]  ] < -- > [0,R]
vec2 d2 (vec3 U) {
    U = clamp(U,vec3(1),vec3(R/N,N*N));
	return U.xy+vec2(mod(U.z,N),floor(U.z/N))*R/N;
}
vec3 d3 (vec2 u) {
    vec2 o = floor(u/R*N);
	return vec3(mod(u,R/N),o.x+o.y*N);
}
vec4 s3d (sampler2D T,vec3 U) {
    vec3 U0 = vec3 (U.xy,floor(U.z)),
         U1 = vec3 (U.xy, ceil(U.z));
    vec4 o = mix(
        texture(T,d2(U0)/R),
        texture(T,d2(U1)/R),
        fract(U.z)
    );
    if (U.x<1.||U.y<1.||U.z<1.) o.xyz*=0.;
    return o;
}
vec4 s3d1 (sampler2D T, vec3 U) {
    U=U-s3d(T,U).xyz;
    vec4 s = s3d(T,U);
    return s;
}
float dist (vec3 U, vec4 A) {
	return length(U-A.xyz)-A.w;
}