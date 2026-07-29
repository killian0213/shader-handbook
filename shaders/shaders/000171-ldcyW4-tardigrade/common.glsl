// Common (common) — tardigrade by zguerrero
// https://www.shadertoy.com/view/ldcyW4

vec4 BlurPass(vec2 fragCoords, vec2 resolution, float sampleDistance, sampler2D tex)
{     
    vec2 uv = fragCoords/resolution;
    float v = smoothstep(0.15, 0.5, length(uv - vec2(0.5)));
    vec4 t = vec4(0.0);
    float itter = 0.0;
    
    for(float i = -2.0; i <= 2.0; i++)
    {
        for(float j = -2.0; i <= 2.0; i++)
        {
			t += texture(tex, uv + (vec2(i, j) / resolution) * sampleDistance * v);
            itter += 1.0;
        } 
    }
    
    return t / itter;
}