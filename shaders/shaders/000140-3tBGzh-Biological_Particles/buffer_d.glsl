// Buffer D (buffer) — Biological Particles by wyatt
// https://www.shadertoy.com/view/3tBGzh

// BLUR PASS 2
void mainImage( out vec4 Q, in vec2 U )
{
    Q = 0.5*D(U);
    for (float i = -I; i <= I; i++) {
        vec4 c = C(U+vec2(0,i));
    	Q += c*M*exp(-O*i*i);
    }
    if(iFrame<1) Q = vec4(0);
}