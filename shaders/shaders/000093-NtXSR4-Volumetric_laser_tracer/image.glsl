// Image (image) — Volumetric laser tracer by michael0884
// https://www.shadertoy.com/view/NtXSR4

vec3 tone(vec3 c)
{
    return tanh(pow(c,vec3(0.5)));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 acc = texture(iChannel0, fragCoord/iResolution.xy);
    fragColor = vec4(tone(8.5*acc.xyz/acc.w), 1.0);
}