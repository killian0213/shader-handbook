// Buffer B (buffer) — Unstable Universe by julianlumia
// https://www.shadertoy.com/view/wtlfz8

// Dof code from: 42yeah, https://shadertoy.com/view/wsXBRf

// Random hash function
vec2 rand2d(vec2 uv) {
    return fract(sin(vec2(
        dot(uv, vec2(215.1616, 82.1225)),
        dot(uv, vec2(12.345, 856.125))
    )) * 41234.45) * 2.0 - 1.0;
}

// Calculate CoC: https://developer.download.nvidia.com/books/HTML/gpugems/gpugems_ch23.html
float getCoC(float depth, float focalPlane) {
    float focalLength = .08;
    float aperture = min(1.0, focalPlane * focalPlane);
    return abs(aperture * (focalLength * (focalPlane - depth)) /
        (depth * (focalPlane - focalLength)));
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    
    // Sample original texture data at uv
    vec4 texData = texture(iChannel0, uv);
    
    // Get its depth
    float depth = texData.w;
    
    // Focal plane at 3.9 (the camera is looking at the center from ~4.0)
    float focalPlane = sin(iTime)+4.4;
    
    // Calculate CoC, see above
    float coc = getCoC(depth, focalPlane);
    
    // Sample count
    const int taps = 32;
    
    // Golden ratio: https://www.youtube.com/watch?v=sj8Sg8qnjOg
    float golden = 3.141592 * (3.0 - sqrt(5.0));
    
    // Color & total weight
    vec3 color = vec3(0.0);
    float tot = 0.0;
    
    for (int i = 0; i < taps; i++) {
        // Radius slowly increases as i increases, all the way up to coc
        float radius = coc * sqrt(float(i)) / sqrt(float(taps));
        
        // Golden ratio sample offset
        float theta = float(i) * golden;
        vec2 tapUV = uv + vec2(sin(theta), cos(theta)) * radius;
        
        // Sample the bit over there
        vec4 tapped = texture(iChannel0, tapUV);
        float tappedDepth = tapped.w;

        if (tappedDepth > 0.0) {
            // Use CoC over there as weight
            float tappedCoC = getCoC(tappedDepth, focalPlane);
            float weight = max(0.001, tappedCoC);
            
            // Contribute to final color
            color += tapped.rgb * weight;
            // And final weight sum
            tot += weight;
        }
    }
    // And normalize the final color by final weight sum
    color /= tot;
    fragColor = vec4(color, 1.0);
}
