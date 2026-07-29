// Buffer C (buffer) — grass field with blades by MonterMan
// https://www.shadertoy.com/view/dd2cWh

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = texelFetch(iChannel0, ivec2(fragCoord), 0);
}