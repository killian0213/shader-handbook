// Buffer A (buffer) — Stellar evolution by michael0884
// https://www.shadertoy.com/view/Wl2yWm


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
        if(rand.z < 1.) 
        {
            vec2 dC = pos - R*0.5;
            P.X = pos;
            P.V = 0.*(rand.xy-0.5) + 0.5*vec2(dC.y/R.x, -dC.x/R.x);
            P.M = 0.005*mass;
            P.I = 0.;
        }
        else
        {
            P.X = pos;
            P.V = vec2(0.);
            P.M = 1e-6;
            P.I = 0.;
        }
    }
    
   
    
    U = saveParticle(P, pos);
}