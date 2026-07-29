// Buffer D (buffer) — Smoke on the Water by piyushslayer
// https://www.shadertoy.com/view/Wd33Wn

/**

 This buffer uses the result from the prev fluid solver buffers and draws
 nicely colored circles on it to visualize the fluid sim velocity field.

*/

// iq's integer hash function
float hash1( uint n ) 
{
	n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 789221U) + 1376312589U;
    return float( n & uvec3(0x7fffffffU))/float(0x7fffffff);
}

// Today's hsv to rgb conversion brought to you by The Book of Shaders.
// https://thebookofshaders.com/06/
vec3 hsv2rgb( in vec3 c ){
    vec3 rgb = clamp(abs(mod(c.x * 6. + vec3(0., 4., 2.),
                             6.) - 3.) - 1., 0., 1.);
    rgb = rgb * rgb * (3. - 2. * rgb);
    return c.z * mix(vec3(1.), rgb, c.y);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    vec2 stepSize = 1./iResolution.xy;
    vec4 vel = textureLod(iChannel0, uv, 0.);
    vec4 col = textureLod(iChannel1, uv - dt * vel.xy * stepSize * 3., 0.);
    vec2 mo = iMouse.xy / iResolution.xy;
    vec4 prevMouse = texelFetch(iChannel1, ivec2(0, 0), 0).xyzw;
    
    // Draw ink splat
    if (iMouse.z > 1. && prevMouse.z > 1.)
    {
        float hue = hash1(uint(iMouse.z + iResolution.x*abs(iMouse.w) + iTime));
        vec4 rgb = vec4(hsv2rgb(vec3(hue, 1., 1.)), 1.);
        float bloom = smoothstep(-.5, .5, (length(mo - prevMouse.xy / iResolution.xy)));
    	col += bloom * 8e-4/pow(length(uv - mo.xy), 1.6) * rgb;
    }
    
    // color decay
    col = clamp(col, 0., 5.);
    col = max(col - (col * 8e-3), 0.);
    
    if (fragCoord.y < 1. && fragCoord.x < 1.)
    {
		col = iMouse;   
    }
    
    fragColor = col;
}