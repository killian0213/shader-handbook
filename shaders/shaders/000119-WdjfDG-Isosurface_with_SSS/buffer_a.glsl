// Buffer A (buffer) — Isosurface with SSS by tmst
// https://www.shadertoy.com/view/WdjfDG

#define CUBE_SAMPLER iChannel0
#define SKY_SAMPLER iChannel2
#define KEY_SAMPLER iChannel1

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    inputOnlySSS = texelFetch(KEY_SAMPLER, ivec2(KEY_A,0), 0).x > 0.5;
    inputNoSSS = texelFetch(KEY_SAMPLER, ivec2(KEY_S,0), 0).x > 0.5;
    inputDebugNormal = texelFetch(KEY_SAMPLER, ivec2(KEY_D,0), 0).x > 0.5;
    inputDebugDepth = texelFetch(KEY_SAMPLER, ivec2(KEY_F,0), 0).x > 0.5;

    fragColor = mainRender(CUBE_SAMPLER, SKY_SAMPLER, iResolution, iMouse, fragCoord, ITIME);
}
