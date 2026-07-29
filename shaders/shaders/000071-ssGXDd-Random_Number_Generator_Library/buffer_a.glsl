// Buffer A (buffer) — Random Number Generator Library by paniq
// https://www.shadertoy.com/view/ssGXDd

ivec2 topixel(vec2 uv) {
    uv.x /= (iResolution.x/iResolution.y);
    uv = (uv*0.5+0.5);
    return ivec2(uv * iResolution.xy);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    ivec2 fc = ivec2(fragCoord);
    vec4 src = vec4(0.0); 
    if (iFrame > 0) {
        src = texelFetch(iChannel0, fc, 0);
    } else {
        src.x = 0.0;
    }
    Random rng_base = seed(seed(fragCoord), iFrame);
    if (fc.y == 0) {
        Random rng = rng_base;// make a copy
        // bin a gaussian distribution
        float q = 1.0/iResolution.y;
        for (int i = 0; i < 256; ++i) {
            float n = gaussian(rng, 0.5, 0.2);
            //float n = triangular(rng, 0.0, 1.0, 0.25);
            int x = int(n * iResolution.x + 0.5);
            if (x == fc.x) {
                src.x += 1.0;
            }       
        }
        src.w += 1.0;
    } else {
        Random rng = rng_base;// make a copy
        src.rgb *= 0.983333;
        for (int i = 0; i < 64; ++i) {
            ivec2 p;
            p = topixel(uniform_circle_area(rng)*0.25 + vec2(-1.5,1.0-0.3));
            if (p == fc) { src.rgb += vec3(1.0,0.25,0.5); }
            p = topixel(uniform_hexagon_area(rng)*0.25 + vec2(-0.75,1.0-0.3));
            if (p == fc) { src.rgb += vec3(1.0,0.75,0.25); }
            vec3 w = uniform_triangle_area(rng);
            p = topixel(w.x*vec2(0.0,0.0)+w.y*vec2(0.57735*0.5,0.5)+w.z*vec2(0.57735,0.0) + vec2(-0.57735*0.5,0.45));
            if (p == fc) { src.rgb += vec3(0.25,0.75,1.0); }
            p = topixel(uniform_sphere_area(rng).xy*0.25 + vec2(0.75,1.0-0.3));
            //p = topixel(uniform_sphere_volume(rng).xy*0.25 + vec2(0.75,1.0-0.3));
            if (p == fc) { src.rgb += vec3(0.25,1.0,0.5); }            
            vec4 u = uniform_simplex_volume(rng);
            vec2 uc = u.x*vec2(-1.0,-1.0)+u.y*vec2(0.8,-0.8)+u.z*vec2(-0.8,0.8)+u.w*vec2(1.0,1.0);
            p = topixel(uc*0.25 + vec2(1.5,0.7));
            if (p == fc) { src.rgb += vec3(0.5,0.25,1.0); }
        }
    }
    fragColor = src;
}