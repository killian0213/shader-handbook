// Image (image) — Molecular Dance by wyatt
// https://www.shadertoy.com/view/WdB3WG

// Caustic Drawing and red and blue dot drawing
#define N 2
vec2 R;
float ln (vec3 p, vec3 a, vec3 b) {return length(p-a-(b-a)*dot(p-a,b-a)/dot(b-a,b-a));}
vec4 C (vec2 U) {return texture(iChannel2,U/R);}
vec4 B (vec2 U) {return texture(iChannel1,U/R);}
vec4 D (vec2 U) {return texture(iChannel3,U/R);}
vec4 A (vec2 U) {return texture(iChannel0,U/R);}
float dI (vec2 U, vec3 me, vec3 light, float mu) {
    vec3 r = vec3(U,100);
    vec3 n = normalize(vec3(D(r.xy).zw,mu));
    vec3 li = reflect((r-light),n);
    float len = ln(me,r,li);
    return 5.e-1*exp(-len);
}
float I (vec2 U, vec3 me, vec3 light, float mu) {
    float intensity = 0.;
    for (int x = -N; x <= N; x++)
        for (int y = -N; y <= N; y++){
            float i = dI(U+vec2(x,y),me,light,10.*mu);
            intensity += i*i;
        }
        return intensity;
}
void mainImage( out vec4 Q, in vec2 U)
{
    R = iResolution.xy;
    vec3 light = vec3(0.5*R,1e5);
    vec3 me    = vec3(U,0);
	vec4 a = A(U);
    vec4 c = C(U);
    float l = I(U,me,light,1.);
    float r = smoothstep(2.+0.05*abs(a.w),.5,length(U-a.xy));
    Q = l+r*vec4(abs(sign(a.w)),-sign(a.w),-sign(a.w),1);
}