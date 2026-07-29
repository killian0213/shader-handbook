// Buffer C (buffer) — Communication and Grouping by wyatt
// https://www.shadertoy.com/view/wtSSDm


void mainImage( out vec4 Q, in vec2 U )
{
   Q = vec4(0);
    
    for (int i = -I; i <= I; i++) {
    	Q += (exp(-O*float(i*i)))*A(U+vec2(0,i));
    }
}