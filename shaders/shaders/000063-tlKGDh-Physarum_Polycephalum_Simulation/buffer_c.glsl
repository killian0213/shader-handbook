// Buffer C (buffer) — Physarum Polycephalum Simulation by michael0884
// https://www.shadertoy.com/view/tlKGDh

void mainImage( out vec4 Q, in vec2 p )
{
    Q = texel(ch1, p);
    
    Q = 0.9*Q + 0.1*texel(ch0, p); 
    if(iFrame < 1) Q =vec4(0);
}