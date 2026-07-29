// Image (image) — Path racer by XT95
// https://www.shadertoy.com/view/WtlXWS

// Created by anatole duprat - XT95/2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Post processing pass

// https://www.shadertoy.com/view/XlKSDR
// Narkowicz 2015, "ACES Filmic Tone Mapping Curve"
vec3 acesToneMapping( vec3 col )
{
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return (col * (a * col + b)) / (col * (c * col + d) + e);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 invRes = vec2(1.)/ iResolution.xy;
    vec2 uv = fragCoord * invRes;

    // post processing effects
    vec3 col = texture(iChannel0, uv).rgb;
    
    // blur godrays
    vec3 godray = vec3(0.);
    for(float x=-3.; x<=3.; x+=1.)
    for(float y=-3.; y<=3.; y+=1.) { 
    	godray += texture(iChannel1,uv*.5+vec2(x,y)*invRes).rgb;
    }
    godray = (godray/49.); 
    col += godray*.5;
    
    // vignetting
    col.rgb *= saturate(pow( uv.x * uv.y * (1.-uv.x) * (1.-uv.y)*100., .2));
    
    // tone mapping
    col = acesToneMapping( col );
    
    
    fragColor = vec4(col.rgb,1.) * smoothstep(0.,3., iTime);
}