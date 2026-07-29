// Image (image) — Everything's A Caustic by wyatt
// https://www.shadertoy.com/view/WdBGDm

vec2 R;
vec4 A (vec2 U) {return texture(iChannel0,U/R);}
vec4 B (vec2 U) {return texture(iChannel1,U/R);}
vec4 C (vec2 U) {return texture(iChannel2,U/R);}
void mainImage( out vec4 Q, in vec2 U)
{
    R = iResolution.xy;
    vec2 M = iMouse.z>0.?iMouse.xy:0.5*R;
    vec2 r = 2.*(U-M)/R.y;
    r = r/sqrt(length(r));
    Q = vec4(0);
    for (float i = 1.; i < 10.; i++) {
        vec4 c = C(U-i*r);
        Q += c*c*exp(-.2*i);
    }
    Q = mix(C(U),.8*Q*exp(-1.5*length(r)),.5);
}