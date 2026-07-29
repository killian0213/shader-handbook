// Buffer A (buffer) — Basic Color Picker by iq
// https://www.shadertoy.com/view/4cjBDc

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = picker_do( iFrame==0, iChannel0, iMouse, fragCoord, iResolution.xy );
}