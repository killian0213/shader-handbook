// Buffer D (buffer) — Screen Space Horizon GI by Mathis
// https://www.shadertoy.com/view/dsGBzW

//Copy G-Buffer

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0,fragCoord*IRES);
}