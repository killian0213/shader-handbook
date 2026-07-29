// Buf A (buffer) — Wind flow map by davidar
// https://www.shadertoy.com/view/4sKBz3

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord/iResolution.xy;
    vec2 p = texture(iChannel0, uv).xy;
    if(p == vec2(0)) {
        if (hash13(vec3(fragCoord, iFrame)) > 2e-4) return;
        p = fragCoord + hash21(float(iFrame)) - 0.5;
    }
    vec2 v = 2. * texture(iChannel3, 0.03*uv).xy - 1.;
    fragColor.xy = p + v;
}