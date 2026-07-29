// Buffer A (buffer) — Real time path tracing by loicvdb
// https://www.shadertoy.com/view/wtcXz4

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    fragColor = texelFetch(iChannel0, ivec2(fragCoord), 0);
}