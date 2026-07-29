// Buffer D (buffer) — Fast voronoi interpolation by michael0884
// https://www.shadertoy.com/view/ts3XWf

vec4 B(vec2 pos)
{
   return SAMPLE(iChannel1, pos, size);
}


const vec2 damp = vec2(0.000,0.01);
const vec2 ampl = vec2(0.1,1.);

float weight(float t, float log2radius, float gamma)
{
    return exp(-gamma*pow(log2radius-t,2.));
}

//mipmap blur https://www.shadertoy.com/view/WsVGWV
vec4 sample_blured(vec2 uv, float radius, float gamma)
{
    vec4 pix = vec4(0.);
    float norm = 0.001;
    //weighted integration over mipmap levels
    for(float i = 0.; i < 5.; i += 0.5)
    {
        float k = weight(i, log2(1. + radius), gamma);
        pix += k*texture(iChannel0, uv, i); 
        norm += k;
    }
    //nomalize
    return pix/norm;
}

//voronoi interpolation
vec4 voronopolation(vec2 pos, float radius)
{
    vec4 particle_param = SAMPLE(iChannel0, pos, size);
    float dist = length(mod(pos-particle_param.xy+size*0.5,size) - size*0.5);
    //blur the voronoi texture with a radius proportional to the closest particle distance
    return sample_blured(pos/size,radius*dist,0.25);
}

vec2 V(vec2 pos)
{
    return voronopolation(pos, 1.).zw;
}

void mainImage( out vec4 u, in vec2 pos )
{
    vec4 prev_u = SAMPLE(iChannel1, pos, size);
    
    vec4 particle_param = SAMPLE(iChannel0, pos, size);
    u.xy =  particle_param.zw;
    float div = V(pos+vec2(1,0)).x-V(pos-vec2(1,0)).x+V(pos+vec2(0,1)).y-V(pos-vec2(0,1)).y;
    u.zw = (1.-0.001)*0.25*(B(pos+vec2(0,1))+B(pos+vec2(1,0))+B(pos-vec2(0,1))+B(pos-vec2(1,0))).zw;
    u.zw += ampl*vec2(div,0.);
}