// Buffer B (buffer) — Lava blaster by michael0884
// https://www.shadertoy.com/view/WdtXzs

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

const vec2 damp = vec2(0.000,0.01);
const vec2 ampl = vec2(0.1,1.);

void mainImage( out vec4 u, in vec2 pos )
{
    vec4 prev_u = SAMPLE(iChannel1, pos, size);
   
  
    vec3 density = pdensity(pos);
     //exponential rolling average
      u.xyz =  0.5*density;
    float div = B(pos+vec2(1,0)).x-B(pos-vec2(1,0)).x+B(pos+vec2(0,1)).y-B(pos-vec2(0,1)).y;
    u.zw = (1.-0.001)*0.25*(B(pos+vec2(0,1))+B(pos+vec2(1,0))+B(pos-vec2(0,1))+B(pos-vec2(1,0))).zw;
    u.zw += ampl*vec2(div,density.z);
}