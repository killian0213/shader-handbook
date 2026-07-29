// Buffer A (buffer) — My virtual slime molds by michael0884
// https://www.shadertoy.com/view/WtBcDG


void mainImage( out vec4 U, in vec2 pos )
{
    R = iResolution.xy; time = iTime; Mouse = iMouse;
    ivec2 p = ivec2(pos);

    vec4 data = texel(ch0, pos); 
    
    particle P = getParticle(data, pos);
       
    Reintegration(ch0, P, pos);
   
    //initial condition
    if(iFrame < 1)
    {
        //random
        vec3 rand = hash32(pos);
        rand.z = distance(pos, R*0.5)/R.x;
        if(rand.z < 0.1) 
        {
            P.X = pos;
            P.V = 0.5*(rand.xy-0.5) + 0.*vec2(sin(2.*pos.x/R.x), cos(2.*pos.x/R.x));
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