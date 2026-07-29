// Image (image) — Water Caustics w/ OpenSimplex2S by KdotJPG
// https://www.shadertoy.com/view/wlc3zr

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    
    // Normalized pixel coordinates (from 0 to 1 on largest axis)
    vec2 uv = fragCoord / max(iResolution.x, iResolution.y) * 8.0;
    
    // Initial input point
    vec3 X = vec3(uv, mod(iTime, 578.0) * 0.8660254037844386);
    
    // Evaluate noise once
    vec4 noiseResult = os2NoiseWithDerivatives_ImproveXY(X);
    
    // Evaluate noise again with the derivative warping the domain
    // Might be able to approximate this by fitting to a curve instead
    noiseResult = os2NoiseWithDerivatives_ImproveXY(X - noiseResult.xyz / 16.0);
    float value = noiseResult.w;
    
    /* You can sort of imitate the effect by fitting a curve instead of calling noise again.
       Not quite as good, and not sure of speed differences.
       Could probably experiment with non-trig curves too.
    float p = asin(noiseResult.w);
    float derivMag = length(noiseResult.xyz);
    float sinScale = derivMag / cos(p);
    float value = sin(p - sinScale * derivMag / 20.0);*/

    // Time varying pixel color
    vec3 col = vec3(.431, .8, 1.0) * (0.5 + 0.5 * value);

    // Output to screen
    fragColor = vec4(col, 1.0);
}