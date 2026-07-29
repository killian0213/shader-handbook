// Buffer B (buffer) — Physarum Circular by michael0884
// https://www.shadertoy.com/view/wtKGW1

//depositing and diffusing the pheromone trails 

void mainImage( out vec4 Q, in vec2 p )
{
    Q = texel(ch1, p);
   
    //diffusion equation
    Q += dt*Laplace(ch1, p);
    
    vec4 particle = texel(ch0, p);
    float distr = gauss(p - particle.xy, prad);
    
    //pheromone depositing
    Q += dt*distr;
        
    //pheromone decay
    Q += -dt*decay*Q;
    
    if(iFrame < 1) Q = vec4(0);
}