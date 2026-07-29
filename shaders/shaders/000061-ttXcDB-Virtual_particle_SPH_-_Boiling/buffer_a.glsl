// Buffer A (buffer) — Virtual particle SPH - Boiling by michael0884
// https://www.shadertoy.com/view/ttXcDB

#define mass 1.

void mainImage( out vec4 U, in vec2 pos )
{
    R = iResolution.xy; time = iTime; Mouse = iMouse;
    ivec2 p = ivec2(pos);
        
    //particle velocity, mass and grid distributed density
    vec2 F = vec2(0.);
    
    vec4 data = texel(ch0, pos); 
    
    particle P;// = getParticle(data, pos);
       
    Reintegration(ch0, P, pos);
   
    //initial condition
    if(iFrame < 1)
    {
        //random
        vec3 rand = hash32(pos);
        if(rand.z < 0.3) 
        {
            P.X = pos;
            P.V = 0.5*(rand.xy-0.5) + vec2(0., 0.);
            P.M = vec2(mass, 0.);
        }
        else
        {
            P.X = pos;
            P.V = vec2(0.);
            P.M = vec2(0.);
        }
    }
    
    U = saveParticle(P, pos);
}