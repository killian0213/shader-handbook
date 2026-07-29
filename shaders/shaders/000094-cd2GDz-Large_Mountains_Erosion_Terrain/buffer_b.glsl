// Buffer B (buffer) — Large Mountains Erosion Terrain by Hatchling
// https://www.shadertoy.com/view/cd2GDz

float perlin(vec2 uv)
{
uv += vec2(3.1982,4.73234);
    uv /= 1.0;
    vec2 occ = vec2(0);
    float a = 1.0;
    for(int i = 0; i < 10; i++)
    {
        occ += vec2(texture(iChannel0, uv).r, 1) * a;
        uv *= 0.5;
        a *= 2.0;
    }

    float v = occ.x / occ.y;
    
    v = v * 2.0 - 1.0;
    
    v = tanh(v * 2.0);
    
    v = v * 0.5 + 0.5;
    
    v *= v;
    
    return v;
       
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iChannelResolution[0].xy;
    float height = perlin(uv);
    
    fragColor = vec4(height, height, height, 1.);
    
    

}