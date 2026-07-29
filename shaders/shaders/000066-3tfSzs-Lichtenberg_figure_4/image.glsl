// Image (image) — Lichtenberg figure 4 by rory618
// https://www.shadertoy.com/view/3tfSzs

void mainImage( out vec4 O, in vec2 I )
{
	O = texture(iChannel2,I/R.xy);
    O = 1.-O/O.w*2.;
}