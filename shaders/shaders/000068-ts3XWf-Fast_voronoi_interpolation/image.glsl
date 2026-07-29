// Image (image) — Fast voronoi interpolation by michael0884
// https://www.shadertoy.com/view/ts3XWf

// Fork of "Lava blaster" by michael0884. https://shadertoy.com/view/WdtXzs
// 2019-11-05 21:20:41

const int KEY_UP = 38;
const int KEY_DOWN  = 40;

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
    for(float i = 0.; i < 10.; i += 0.5)
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

vec4 B(vec2 pos)
{
   return SAMPLE(iChannel1, pos, size);
}

//density and velocity
vec3 pdensity(vec2 pos)
{
   vec4 particle_param = SAMPLE(iChannel0, pos, size);
   return vec3(particle_param.zw,gauss(pos - particle_param.xy, 0.7*radius));
}

vec2 V(vec2 pos)
{
    return voronopolation(pos, 1.).zw;
}

void mainImage( out vec4 fragColor, in vec2 pos )
{
   vec3 density = pdensity(pos);
   vec2 velocity = voronopolation(pos, 1.3).zw;
   vec4 blur = SAMPLE(iChannel1, pos, size);
    float vorticity = V(pos+vec2(1,0)).y-V(pos-vec2(1,0)).y-V(pos+vec2(0,1)).x+V(pos-vec2(0,1)).x;
   //fragColor = vec4(SAMPLE(iChannel2, pos, size).xyz  + 0.8*vec3(0.4,0.6,0.9)*vorticity,1.0);
    if(texelFetch( iChannel2, ivec2(KEY_UP,2), 0 ).x < 0.5)
    {
        if(mod(iTime,3.) < 1.5)
        {
             fragColor = vec4(10.*abs(velocity.xyy) + vec3(0,0,1.)*0.5*abs(blur.z),1.0);
        }
        else
        {
            fragColor = vec4(10.*abs(density.xyy) + vec3(0,0,1.)*0.5*abs(blur.z),1.0);
        }
    }
    else
    {
     	float l1 = 490.*abs(vorticity);
        float l2 = 1.-l1;
        fragColor = vec4(vec3(1.,0.3,0.1)*l1 + 0.*vec3(0.1,0.1,0.1)*l2,1.0);
    }  
}

