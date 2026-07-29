// Image (image) — Bidirectional Laser Tracer by michael0884
// https://www.shadertoy.com/view/7tjSDh

// Fork of "Volumetric laser tracer" by michael0884. https://shadertoy.com/view/NtXSR4
// 2021-07-22 19:27:50

vec3 ColorGrade( vec3 vColor )
{
    vec3 vHue = vec3(1.0, .7, .2);
    
    vec3 vGamma = 1.0 + vHue * 0.6;
    vec3 vGain = vec3(.9) + vHue * vHue * 8.0;
    
    vColor *= 1.5;
    
    float fMaxLum = 100.0;
    vColor /= fMaxLum;
    vColor = pow( vColor, vGamma );
    vColor *= vGain;
    vColor *= fMaxLum;
    return pow(tanh(vColor), vec3(0.57));
}

vec3 tone(vec3 c)
{
    c = XYZtosRGB(c);
    return ColorGrade(c);
}
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 acc = texture(iChannel0, fragCoord/iResolution.xy);
    fragColor = vec4(tone(0.03*acc.xyz/acc.w), 1.0);
}