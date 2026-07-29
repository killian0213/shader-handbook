// Image (image) — 20210930_CLUB-CAVE-09 by 0b5vr
// https://www.shadertoy.com/view/ss3SD8

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord/iResolution.xy;
    fragColor = texture(iChannel0, uv);
}