// Buffer C (buffer) — Biological Particles by wyatt
// https://www.shadertoy.com/view/3tBGzh

// BLUR PARTICLES PASS 1
void mainImage( out vec4 Q, in vec2 U )
{
    Q = vec4(0);
    for (float i = -I; i <= I; i++) {
        vec2 x = U+vec2(i,0);
        vec4 b = B(x);
    	Q += hash(b.w)*M*exp(-i*i*O)*smoothstep(1.,0.,length(b.xy-x));
    }
    
}