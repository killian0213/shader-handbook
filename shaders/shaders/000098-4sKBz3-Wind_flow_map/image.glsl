// Image (image) — Wind flow map by davidar
// https://www.shadertoy.com/view/4sKBz3

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    float r = texture(iChannel0, fragCoord/iResolution.xy).x;
    r = 0.9 - 0.8 * r;
    fragColor = vec4(vec3(r), 1);
}