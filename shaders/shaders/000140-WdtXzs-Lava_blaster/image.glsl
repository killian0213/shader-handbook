// Image (image) — Lava blaster by michael0884
// https://www.shadertoy.com/view/WdtXzs

// Fork of "Vorofluid" by michael0884. https://shadertoy.com/view/3sdXRX
// 2019-11-01 23:20:11

// Fork of "Voronoi vortex particle fluid" by michael0884. https://shadertoy.com/view/WdcXzS
// 2019-10-30 21:27:02
const int KEY_UP = 38;
const int KEY_DOWN  = 40;

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

void mainImage( out vec4 fragColor, in vec2 pos )
{
   vec3 density = pdensity(pos);
   vec4 blur = SAMPLE(iChannel1, pos, size);
    float vorticity = B(pos+vec2(1,0)).y-B(pos-vec2(1,0)).y-B(pos+vec2(0,1)).x+B(pos-vec2(0,1)).x;
   //fragColor = vec4(SAMPLE(iChannel2, pos, size).xyz  + 0.8*vec3(0.4,0.6,0.9)*vorticity,1.0);
    if(texelFetch( iChannel2, ivec2(KEY_UP,2), 0 ).x > 0.5)
    {
        fragColor = vec4(2.*density.z*(7.*abs(density.xyy)+vec3(0.2, 0.1, 0.1)),1.0);
        fragColor = vec4(10.*abs(density.xyy) + 30.*vec3(0,0,abs(blur.z)),1.0);
    }
    else
    {
     	float l1 = 490.*abs(vorticity);
        float l2 = 1.-l1;
        fragColor = vec4(vec3(1.,0.3,0.1)*l1 + 0.*vec3(0.1,0.1,0.1)*l2,1.0);
    }  
}

