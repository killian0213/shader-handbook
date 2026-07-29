// Buffer C (buffer) — Physarum Circular by michael0884
// https://www.shadertoy.com/view/wtKGW1

void mainImage( out vec4 Q, in vec2 p )
{
    Q = texel(ch1, p);
    
    Q = 0.85*Q + 0.15*texel(ch0, p); 
    if(iFrame < 1) Q =vec4(0);
}