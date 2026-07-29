// Buffer B (buffer) — Stellar evolution by michael0884
// https://www.shadertoy.com/view/Wl2yWm

void mainImage( out vec4 U, in vec2 pos )
{
    R = iResolution.xy; time = iTime; Mouse = iMouse;
    ivec2 p = ivec2(pos);
    
    vec4 data = texel(ch0, pos); 
    
    particle P = getParticle(data, pos); 
    
   
    if(P.M != 0.) //not vacuum
    {
        Simulation(ch0, ch1, P, pos);
    }
    
   
	/*
    if(length(P.X - R*vec2(0.2, 0.9)) < 10.) 
    {
        P.X = pos;
        P.V = 0.5*Dir(-PI*0.25 + 0.3*sin(0.3*time));
        P.M = mix(P.M, vec2(fluid_rho, 0.), 0.4);
    }*/
    
    if(length(pos - R*vec2(0.5, 0.1)) < 10.) 
    {
      // P.I = 0.2;
    }
    
    U = saveParticle(P, pos);
}