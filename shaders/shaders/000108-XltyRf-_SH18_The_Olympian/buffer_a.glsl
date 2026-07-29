// Buffer A (buffer) — [SH18] The Olympian by Klems
// https://www.shadertoy.com/view/XltyRf

// store FFT in a buffer, store playback in alpha channel
void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
   	float x = fragCoord.x/iResolution.x;
    vec2 uv = vec2(x, 0.25);
    fragColor.rgb = texture(iChannel0, uv).rgb;
    fragColor.a = iChannelTime[0];
}