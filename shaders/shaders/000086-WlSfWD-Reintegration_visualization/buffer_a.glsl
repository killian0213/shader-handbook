// Buffer A (buffer) — Reintegration visualization by michael0884
// https://www.shadertoy.com/view/WlSfWD


void mainImage( out vec4 U, in vec2 pos )
{
    R = iResolution.xy; time = iTime; Mouse = iMouse;
    ivec2 p = ivec2(pos);

    vec4 data = texel(ch0, pos); 
    
    particle P;// = getParticle(data, pos);
       
    if(iFrame%2 == 0)
   		Reintegration(ch0, P, pos);
   	else
        P = getParticle(data, pos);
    //initial condition
    if(iFrame < 1)
    {
        //random
        vec3 rand = hash32(pos + vec2(0., 1.0)+0.28);
        if(rand.z < 0.6) 
        {
            P.X = pos + 0.3*(rand.yz-0.5);
            P.V = 0.65*(rand.xy-0.5) + vec2(0., 0.);
            P.M = vec2(mass, 0.);
        }
        else
        {
            P.X = pos;
            P.V = vec2(0.);
            P.M = vec2(1e-6);
        }
    }
    
    U = saveParticle(P, pos);
}