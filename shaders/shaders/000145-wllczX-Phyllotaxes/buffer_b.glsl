// Buffer B (buffer) — Phyllotaxes by tdhooper
// https://www.shadertoy.com/view/wllczX

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 col = texelFetch(iChannel0, ivec2(fragCoord.xy), 0);
    #ifdef TRACE_PREVIEW
		fragColor = col * float(iFrame + 1); return;
    #endif
    #ifdef PREVIEW
		fragColor = col * float(iFrame + 1); return;
    #endif
	vec4 last = texelFetch(iChannel1, ivec2(fragCoord.xy), 0);
    fragColor = last + col;
}
