// Buffer A (buffer) — Cartoon ride by iapafoto
// https://www.shadertoy.com/view/wtXBR4


void mainImage(out vec4 fragColor, in vec2 fragCoord){
    fragColor = render(fragCoord.xy, iTime, iResolution.xy, iChannel0);
}

