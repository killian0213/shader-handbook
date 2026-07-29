// Image (image) — Waving particle surface by jaszunio15
// https://www.shadertoy.com/view/ttB3Rt

//Shader License: CC BY 3.0
//Author: Jan Mróz (jaszunio15)

//Bluring the D Buffer
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = blur(iChannel0, fragCoord, iResolution.xy);
}