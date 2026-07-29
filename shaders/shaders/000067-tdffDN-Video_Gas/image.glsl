// Image (image) — Video Gas by michael0884
// https://www.shadertoy.com/view/tdffDN

// Fork of "Connected particle chain image" by michael0884. https://shadertoy.com/view/3dXfDN
// 2020-04-30 15:21:35

// Fork of "Large scale flocking" by michael0884. https://shadertoy.com/view/tsScRG
// 2020-04-30 07:24:31

ivec4 get(ivec2 p)
{
    return ivec4(floor(texel(ch0, p)));
}

ivec4 getb(int id)
{
    return ivec4(floor(texel(ch2, i2xy(id))));
}

vec4 getParticle(int id)
{
    return texel(ch1, i2xy(id));
}

vec3 imageC(vec2 p)
{
    return texture(ch3, vec2(1., 1.)*p/size).xyz;
}

float particleDistance(int id, vec2 p)
{
    return distance(p, getParticle(id).xy);
}

void mainImage( out vec4 fragColor, in vec2 pos )
{
     N = ivec2(prop*iResolution.xy);
    tot_n = N.x*N.y;
    ivec4 nb = get(ivec2(pos));
 	vec4 p0 = getParticle(nb.x);
   
    fragColor = vec4(0.,0,0,1);
    for(int i = 0; i < 4; i++)
    {
       vec4 p0 = getParticle(nb[i]);
    	fragColor.xyz += 0.3*(0.85+0.25*imageC(p0.xy))
            			//*sin(vec3(1,2,3)*length(p0.zw))
            			*exp(-0.15*distance(p0.xy, pos));
    }
}