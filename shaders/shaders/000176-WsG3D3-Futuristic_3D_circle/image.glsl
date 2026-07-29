// Image (image) — Futuristic 3D circle by jaszunio15
// https://www.shadertoy.com/view/WsG3D3

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 col = blur(iChannel0, fragCoord, iResolution.xy);
    col = smoothstep(-0.2, 0.7, col);
    fragColor = col;
}