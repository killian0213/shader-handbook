// Image (image) — Me And My Neighborhood by wyatt
// https://www.shadertoy.com/view/WtsSz2

#define LOOKUP(COORD) texture(iChannel0,(COORD)/iResolution.xy)

void mainImage( out vec4 color, in vec2 coord )
{
   color = LOOKUP (coord).wwww;
}