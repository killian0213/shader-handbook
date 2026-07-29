// Buffer B (buffer) — Reintegration visualization by michael0884
// https://www.shadertoy.com/view/WlSfWD

void mainImage( out vec4 U, in vec2 pos )
{
    R = iResolution.xy; time = iTime; Mouse = iMouse;
    ivec2 p = ivec2(pos);
        
    vec4 data = texel(ch0, pos); 
    
    particle P = getParticle(data, pos);
    
    if(iFrame%2 == 0)
    if(P.M.x != 0.) //not vacuum
    {
        //Simulation(ch0, P, pos);
    }

    U = saveParticle(P, pos);
}