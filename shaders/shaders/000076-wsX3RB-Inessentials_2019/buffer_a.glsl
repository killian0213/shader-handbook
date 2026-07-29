// Buffer A (buffer) — Inessentials 2019 by adx
// https://www.shadertoy.com/view/wsX3RB

// This shader would look broken without the font texture
// so we wait for it to get loaded before doing anything else

#define WAIT_FOR_TEXTURE 1

bool is_loaded(sampler2D tex) {
    return textureSize(tex, 0).x > 1;
}

////////////////////////////////////////////////////////////////

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    if (any(greaterThan(fragCoord, vec2(1))))
        discard;

#if WAIT_FOR_TEXTURE
    if (!is_loaded(iChannel1)) {
        fragColor = vec4(-1);
        return;
    }
#endif
    
    fragColor = (iFrame == 0) ? vec4(-1) : texelFetch(iChannel0, ivec2(fragCoord), 0);
    if (fragColor.x < 0.)
        fragColor = vec4(iTime);
}