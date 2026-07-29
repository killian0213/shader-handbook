// Buffer A (buffer) — Strange Attractor Party by leon
// https://www.shadertoy.com/view/lXySWt


// Strange Attractor Party
// based on "Particles Party" https://shadertoy.com/view/mssXDf
// 2024-07-10 Leon Denise

const float count = 400.;

// https://www.dynamicmath.xyz/strange-attractors/
vec3 thomas(vec3 p, float rng)
{
    float b = 0.208186;//-0.1*rng;
    float speed = mix(0.1, 0.25, rng);
    vec3 offset = vec3(sin(p.y)-b*p.x, sin(p.z)-b*p.y, sin(p.x)-b*p.z);
    //offset = normalize(offset) * min(length(offset), .9);
    return p + speed*offset;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // coordinates
    vec2 uv = fragCoord/iResolution.xy;
    vec2 p = (2.*fragCoord-iResolution.xy)/iResolution.y;
    float id = fragCoord.x;
    
    // buffer
    vec4 frame = texture(iChannel0, uv);
    
    // first line of particles data (force field)
    if (fragCoord.y < 1. && fragCoord.x < count)
    {
        // init
        if (iFrame < 1)
        {
            // random position
            frame = vec4(hash41(id)*2.-1.)* 4.;
        }
        else
        {
            // coordinates
            vec2 aspect = vec2(iResolution.x/iResolution.y, 1.);
            
            // apply strante attractor
            frame.xyz = thomas(frame.xyz, hash11(id));
            
            // jitter
            frame.xyz += (hash41(id).xyz-.5)*.01;
            
            // extra displace
            //vec4 seed = hash41(id+196.);
            //frame.xz *= rot(-0.1*seed.x);
        }
    }
    
    // second line of data (rotate)
    else if (fragCoord.y > 0. && fragCoord.y < 2. && fragCoord.x < count)
    {
        frame = texelFetch(iChannel0, ivec2(id,0), 0);
        
        // mouse interaction
        if (iMouse.z > 0.)
        {
            // mouse control
            vec2 m = (2.*iMouse.xy-iResolution.xy)/iResolution.y;
            frame.xz *= rot(m.x);
            frame.yz *= rot(m.y);
        }
        else
        {
            // constant rotation
            frame.xz *= rot(iTime*.5);
            
            // funky rotation
            float time = iTime + frame.z * .1;
            vec2 anim = vec2(fract(time), floor(time));
            anim.x = easeInOut(anim.x);
            vec4 rng = mix(hash41(anim.y), hash41(anim.y+1.), anim.x);
            rng = rng*2.-1.;
            frame.xyz = rndrot(frame.xyz, rng);
        }
    }
    
    // third line of data (save previous state)
    else if (fragCoord.y > 1. && fragCoord.y < 3. && fragCoord.x < count)
    {
        frame = texelFetch(iChannel0, ivec2(fragCoord.x,1), 0);
    }
    
    // draw disks
    else
    {
        float matID = 0.;
        float dist = 100.;

        // blue noise scroll https://www.shadertoy.com/view/tlySzR
        ivec2 pp = ivec2(fragCoord);
        pp = (pp+(iFrame*196)*ivec2(113,127)) & 1023;
        vec3 blu = texelFetch(iChannel1,pp,0).xyz;

        // fetch particles data
        for (float i = min(0., iTime); i < count; ++i)
        {
            vec4 data = texelFetch(iChannel0, ivec2(i,1), 0);
            vec4 previous = texelFetch(iChannel0, ivec2(i,2), 0);
            data = mix(data, previous, blu.z);
            float z = data.z*2.+10.;
            vec2 pos = data.xy / z;
            float shape = length(pos-p)+z*.002-.01-.01*hash11(i);
            
            matID = shape < dist ? i : matID;
            dist = min(dist, shape);
        }

        // grayscale
        float thin = 0.02;
        frame.r = smoothstep(thin,.0,dist);
        
        // material layer
        if (dist < thin) frame.g = matID;
    }
    
    fragColor = frame;
}