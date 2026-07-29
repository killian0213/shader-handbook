// Image (image) — Random Number Generator Library by paniq
// https://www.shadertoy.com/view/ssGXDd

// see Common tab for implementation

//////////////////////////////////////////////////////////

float qh(ivec2 fc, int a) {
    if (fc.x / 8 == a)
        return 1.0;
    return 0.0;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;
    ivec2 fc = ivec2(fragCoord);

    vec3 col = vec3(0.0);
    
    if (fc.y > 0) {
        col += texelFetch(iChannel0, fc, 0).rgb;
    }

    // demonstrate gaussian
    vec4 dist = texelFetch(iChannel0, ivec2(fc.x, 0), 0);
    if ((dist.x / dist.w)*0.75 > uv.y) {
        col += vec3(1.0);
    }
    
    // demonstrate sampling 4 unique values from N elements
    int N = 16;
    int a = iFrame % N;
    Random rng = seed(seed(iFrame), fc.y/4);
    if ((fc.y > 100) && (fc.y < 120)) {
        ivec3 k = sample_k_3(rng, N, a);
        col += vec3(0.5) * qh(fc, a);
        col += vec3(1.0,0.0,0.0) * qh(fc, k.x);
        col += vec3(0.0,1.0,0.0) * qh(fc, k.y);
        col += vec3(0.0,0.0,1.0) * qh(fc, k.z);
    }
    
    // put some noise on our noise so we can randomize while we randomize
    rng = seed(seed(fragCoord), iTime);
    fragColor = vec4(clamp(col,vec3(0.0),vec3(1.0)) * range(rng, vec3(0.6), vec3(1.0)),1.0);
}


