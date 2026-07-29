// Buffer A (buffer) — Blueprint of the Architekt by s23b
// https://www.shadertoy.com/view/4tySDW

// the purpose of this buffer is too smooth out the sudden changes in the fft
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    float old = texture(iChannel1, uv).x;
    float new = texture(iChannel0, uv).x;
    fragColor = vec4(mix(old, new, new > old ? .4 : .04));
}