// Image (image) — expanding prismatic smoke by morisil
// https://www.shadertoy.com/view/3dlXW8

// Fork of "static prismatic smoke" by morisil. https://shadertoy.com/view/tsXSDH
// 2019-02-26 09:33:58

// Fork of "persisted motion" by morisil. https://shadertoy.com/view/tsjGDD
// 2019-02-21 17:19:31

// Fork of "focused random bubbles" by morisil. https://shadertoy.com/view/Wdj3WR
// 2019-01-31 16:12:56

void mainImage(
    out vec4 fragColor,
    in vec2 fragCoord
) {
    fragColor = texture(iChannel0, fragCoord / iResolution.xy);
}
