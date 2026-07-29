// Buffer D (buffer) — Futuristic 3D circle by jaszunio15
// https://www.shadertoy.com/view/WsG3D3

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = blur(iChannel0, fragCoord, iResolution.xy);
}