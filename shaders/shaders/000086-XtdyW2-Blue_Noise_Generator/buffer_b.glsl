// Buffer B (buffer) — Blue Noise Generator by paniq
// https://www.shadertoy.com/view/XtdyW2


ivec2 flip(ivec2 p, uvec2 mask) {
    return ivec2(lowbias32_r(lowbias32(uvec2(p)) ^ mask));
}

float hash13(vec3 p3)
{
	p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    ivec2 sz = ivec2(iChannelResolution[0].xy);
    ivec2 p0 = ivec2(fragCoord);
    uvec2 mask = uvec2(lowbias32(uint(iFrame)));
    int M = 10 * 60;
    int F = (iFrame % M);
    float framef = float(F) / float(M);
    const float CHANCE_LIMIT = 0.618; // try to swap 62% of pixels
    if (F == 0) {
        int c = (p0.x * 61 + p0.y) % 256;
        fragColor = vec4(float(c) / 255.0, 0.0, 0.0, 1.0);
    } else {
        ivec2 p1 = flip(p0, mask);
        ivec2 pp0 = flip(p1, mask) % sz;
        p1 = p1 % sz;

        float chance0 = hash13(vec3(p0, float(iFrame)));
        float chance1 = hash13(vec3(p1, float(iFrame)));
        float chance = max(chance0, chance1);
        
        float v0 = texelFetch(iChannel0, p0, 0).r;
        float v1 = texelFetch(iChannel0, p1, 0).r;
        
        vec2 s0_x0 = quantify_error(iChannel0, p0, sz, v0, v1);
        vec2 s1_x1 = quantify_error(iChannel0, p1, sz, v1, v0);
        
        float err_s = s0_x0.x + s1_x1.x;
        float err_x = s0_x0.y + s1_x1.y;
        
        float p = v0;
        if ((chance < CHANCE_LIMIT) && (err_x < err_s)) {
            p = v1;
        }
        fragColor = vec4(p, 0.0, 0.0, 1.0);
    }
}                        
