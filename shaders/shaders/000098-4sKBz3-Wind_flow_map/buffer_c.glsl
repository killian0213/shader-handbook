// Buf C (buffer) — Wind flow map by davidar
// https://www.shadertoy.com/view/4sKBz3

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord/iResolution.xy;
    vec2 v = 2. * texture(iChannel3, 0.03*uv).xy - 1.;
    float r = 0.96 * texture(iChannel1, uv).x;
    if (texture(iChannel0, uv).x > 0.) r = 1.;
    fragColor.x = r;
}