// Image (image) — Bulb detail by loicvdb
// https://www.shadertoy.com/view/stc3Ws

/**
 * Volume rendering with path traced GI.
 * 
 * High quality version in Common.
 * 
 * Buffer A accumulates the GI in a voxel grid
 * Buffer B raymarches the ray and gets illumination data from the voxel grid
 * Image buffer does the postprocessing
 * 
 */

void mainImage(out vec4 o, vec2 u)
{

    #if 0
    
    // no dof
    vec3 x = texelFetch(iChannel0, ivec2(u), 0).rgb;
    
    #else
    
    // max blur radius
    float clip = 0.005 * iResolution.y;
    
    #ifdef HIGH_QUALITY
    const int res = 1;
    #else
    // half resolution sampling
    const int res = 2;
    #endif
    
    vec3 x = vec3(0);
    float sum = 0.0;
    
    int yR = int(ceil(clip / float(res)));
    
    for (int j = -yR; j <= yR; j++)
    {
        int xR = int(ceil(sqrt(clip * clip - float(j * res * j * res) / float(res))));
        
        for (int i = -xR; i <= xR; i++)
        {
            ivec2 d = ivec2(i, j) * res;
            
            ivec2 p = clamp(ivec2(u) + d, ivec2(0), ivec2(iResolution.xy) - 1);
            vec4 tex = texelFetch(iChannel0, p, 0);
            
            float a = min(0.03 * iResolution.y * abs(tex.a - 1.47) / tex.a, clip);
            float weight = smoothstep(-a - 1.0, -a, -length(vec2(d))) / (a * a + 0.001);
            
            x += tex.rgb * weight;
            sum += weight;
        }
    }
    
    x /= sum;
    
    #endif
    
    // lod bloom
    float r = floor(log2(iResolution.y) - 4.5) + 0.5;
    for (int i = 0; i < 3; i++)
    {
        x += texture(iChannel0, u / iResolution.xy, r + float(i * 2)).rgb * 0.1;
    }
    
    // vignette
    vec2 cuv = u / iResolution.xy - 0.5;
    x *= 1.0 - dot(cuv*cuv, cuv*cuv) * 4.0;
    
    // tonemapping
    x = (x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14);
    
    o = vec4(x, 1.0);
}