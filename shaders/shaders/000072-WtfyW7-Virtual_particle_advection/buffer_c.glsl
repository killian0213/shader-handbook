// Buffer C (buffer) — Virtual particle advection by michael0884
// https://www.shadertoy.com/view/WtfyW7

//pressure solve

vec2 V(vec2 p)
{
    vec4 d =texel(ch0, p); 
    return d.xy;
}

float P(vec2 p)
{
    return texel(ch1, p).x;
}

void mainImage( out vec4 U, in vec2 pos )
{
    R = iResolution.xy; time = iTime;
    
    float b = border(pos);
      
    
    vec3 dx = vec3(-1., 0., 1.);
    //velocity divergence
    float div = 0.5*(V(pos + dx.zy).x - V(pos + dx.xy).x +
                     V(pos + dx.yz).y - V(pos + dx.yx).y);
    //neighbor average
    float L = 0.25*(P(pos + dx.zy) + P(pos + dx.xy) +
                    P(pos + dx.yz) + P(pos + dx.yx));
    U.x = 0.995*L + div;
  
}