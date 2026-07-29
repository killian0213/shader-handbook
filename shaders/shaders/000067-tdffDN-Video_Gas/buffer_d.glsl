// Buffer D (buffer) — Video Gas by michael0884
// https://www.shadertoy.com/view/tdffDN

void mainImage( out vec4 fragColor, in vec2 p )
{
    fragColor = texture(ch0, p/size);
}