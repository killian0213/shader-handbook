// Buffer A (buffer) — Path traced GI by loicvdb
// https://www.shadertoy.com/view/Wt3XRX

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    fragColor = texelFetch(iChannel0, ivec2(fragCoord), 0);
}