// Image (image) — Between the billowing clouds by jolle
// https://www.shadertoy.com/view/msGGRW

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = texture(iChannel0, fragCoord*RESOLUTION/(iResolution.xy*iResolution.xy));
}
