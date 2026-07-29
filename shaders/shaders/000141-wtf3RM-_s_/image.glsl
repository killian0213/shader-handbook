// Image (image) — ᴇ  s  ᴄ  ʜ  ᴇ  ʀ  ᴡ  ᴀ  ᴠ  ᴇ by tdhooper
// https://www.shadertoy.com/view/wtf3RM

void mainImage(out vec4 fragColor, vec2 fragCoord) {
    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    fragColor = texture(iChannel0, uv);
}
