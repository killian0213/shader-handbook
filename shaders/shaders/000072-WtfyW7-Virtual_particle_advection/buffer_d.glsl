// Buffer D (buffer) — Virtual particle advection by michael0884
// https://www.shadertoy.com/view/WtfyW7

//pressure solve + gradient

vec2 V(vec2 p)
{
    vec4 d =texel(ch0, p); 
    return d.xy;
}

float sqr(float x)
{
	return x*x;
}

float P(vec2 p)
{
    return -0.08*texel(ch0, p).z+ texel(ch1, p).x;
}

void mainImage( out vec4 U, in vec2 pos )
{
    R = iResolution.xy; time = iTime;
    
    float b = border(pos);
      
    if(b > 0. || true) 
    {
        vec3 dx = vec3(-1., 0., 1.);
        //velocity divergence
        float div = 0.5*(V(pos + dx.zy).x - V(pos + dx.xy).x +
                         V(pos + dx.yz).y - V(pos + dx.yx).y);
        //neighbor average
        float L = 0.25*(P(pos + dx.zy) + P(pos + dx.xy) +
                       P(pos + dx.yz) + P(pos + dx.yx));
        U.x = 0.995*L + div;
    }  
    
    
    vec3 dx = vec3(-1., 0., 1.);
    //global force field
    vec2 pressure = 0.5*vec2(P(pos + dx.zy) - P(pos + dx.xy),
                             P(pos + dx.yz) - P(pos + dx.yx));
    U.zw = pressure;
}