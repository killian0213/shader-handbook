// Buffer B (buffer) — Communication and Grouping by wyatt
// https://www.shadertoy.com/view/wtSSDm


void mainImage( out vec4 Q, in vec2 U )
{
   Q = vec4(0);
    
    for (int i = -I; i <= I; i++) {
        vec2 u = U+vec2(i,0);
        vec4 a = A(u);
    	Q += (exp(-O*float(i*i)))*smoothstep(1.5,1.,length(u-a.xy));
    }
}