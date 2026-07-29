// Image (image) — Strange Attractor Party by leon
// https://www.shadertoy.com/view/lXySWt


// Strange Attractor Party
// based on "Particles Party" https://shadertoy.com/view/mssXDf
// 2024-07-10 Leon Denise

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 color = vec3(0);
    
    // coordinates
    vec2 uv = fragCoord/iResolution.xy;
    vec3 blu = texture(iChannel1, fragCoord/1024.).rgb;
    vec2 aspect = vec2(iResolution.y/iResolution.x, 1.);
    
    // background
    vec3 background = vec3(.25);
    float vignette = smoothstep(-.5,.5,length(uv-.5)+blu.z*.1);
    background *= vignette;
    
    // drawing data
    vec4 data = texture(iChannel0, uv);
    float shade = data.r;
    float id = data.g;
    
    // particles data
    vec3 position = texelFetch(iChannel0, ivec2(id, 1.), 0).xyz;
    vec3 previous = texelFetch(iChannel0, ivec2(id, 2.), 0).xyz;
    float velocity = distance(position, previous);
    
    // coloring
    vec3 tint = .5+.5*cos(vec3(1,2,3)*5. + velocity*10.+3.);
    velocity = smoothstep(.0,.1,velocity-.2);
    color = vec3(.5);
    color *= mod(id, 2.);
    color = mix(color, tint, velocity);
    
    // lighting
    vec3 un = vec3(0.005*aspect, 0);
    #define T(un) texture(iChannel0, uv+un).r
    vec3 normal = normalize(vec3(T(un.xz)-T(-un.xz),T(un.zy)-T(-un.zy), .5));
    float d = dot(normal, normalize(vec3(0,-1,-1)))*.5+.5;
    color += pow(d, 1.5);
    
    // background
    float alpha = smoothstep(.0,.1,shade);
    alpha *= smoothstep(4.,10.,fragCoord.y);
    color = mix(background, color, alpha);
    
    /*
    uv.y = 1.-uv.y;
    uv *= 1./aspect*4.;
    if (uv.x < 1. && uv.y < 1.)
    {
        uv.x = floor(uv.x*20.) + floor(uv.y*20.) * 20.;
        uv.y = 1.;
        color = ((texelFetch(iChannel0, ivec2(uv.x, 0.), 0).rgb/4.));
    }
    */
    

    fragColor = vec4(color, 1.);
}