// Buffer A (buffer) — Trilinear Isosurface Explorer by oneshade
// https://www.shadertoy.com/view/3tyfzV

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = vec4(0.0, 0.0, 0.0, 0.0);
    ivec2 iFragCoord = ivec2(fragCoord);
    if (iFrame == 0) {
        if (iFragCoord.x == 0) fragColor.x = 0.0;
        if (iFragCoord.x == 1) fragColor.x = -1.25;
        if (iFragCoord.x == 2) fragColor.x = 0.5;
        if (iFragCoord.x == 3) fragColor.x = 0.0;
        if (iFragCoord.x == 4) fragColor.x = -0.75;
        if (iFragCoord.x == 5) fragColor.x = 0.0;
        if (iFragCoord.x == 6) fragColor.x = 0.0;
        if (iFragCoord.x == 7) fragColor.x = 2.0;
    }

    if (iFrame > 0 && iFragCoord.y == 0 && iFragCoord.x < 8) {
        fragColor = texelFetch(iChannel0, iFragCoord, 0);
        vec2 mouse = (iMouse.xy - 0.5 * iResolution.xy) / iResolution.y;

        // Slider state
        vec2 slider = sliders[iFragCoord.x];
        vec2 sliderEnds = slider.x + vec2(-0.5, 0.5) * sliderLen;
        vec2 curPos = vec2(mix(sliderEnds.x, sliderEnds.y, (fragColor.x - sliderMin) / (sliderMax - sliderMin)), slider.y);

        // Update the slider if it is within the selection radius
        if (iMouse.z > 0.0 && length(mouse - curPos) < selectRadius) {
            fragColor.x = mix(sliderMin, sliderMax, clamp((mouse.x - sliderEnds.x) / sliderLen, 0.0, 1.0));
        }
    }
}