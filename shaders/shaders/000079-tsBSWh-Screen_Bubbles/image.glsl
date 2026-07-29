// Image (image) — Screen Bubbles by wyatt
// https://www.shadertoy.com/view/tsBSWh

#define R iResolution.xy
float ln (vec3 p, vec3 a, vec3 b) {return length(p-a-(b-a)*dot(p-a,b-a)/dot(b-a,b-a));}
vec4 A (vec2 U) {return texture(iChannel0,U/R);}
vec4 B (vec2 U) {return texture(iChannel1,U/R);}
vec4 C (vec2 U) {return texture(iChannel2,U/R);}
void mainImage( out vec4 Q, in vec2 U)
{
    vec3 light = vec3(2.5*R,1e5);
    vec3 me    = vec3(U,0);
	vec3 r = vec3(U,100);
    vec4 a = A(U);
    vec4 b = B(U);
    float 
  		n = A(U+vec2(0,1)).z,
  		e = A(U+vec2(1,0)).z,
  		s = A(U-vec2(0,1)).z,
  		w = A(U-vec2(1,0)).z;
   	vec3 no = normalize(vec3(e-w,n-s,-2.));
    vec3 li = reflect((r-light),no);
   	float o = ln(me,r,li);
    vec2 u = U-b.xy;
    u *= mat2(cos(b.w),-sin(b.w),sin(b.w),cos(b.w));
    Q = abs(sin(10.*a.w+.3*a.z*vec4(1,2,3,4)+smoothstep(4.,3.,abs(length(U-b.xy)-b.z))));
    Q *= smoothstep(-1.,-2.,length(U-b.xy)-b.z);
    Q += exp(-2.*o);
    Q *= .8;
}