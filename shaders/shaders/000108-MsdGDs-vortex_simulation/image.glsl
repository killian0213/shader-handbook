// Image (image) — vortex simulation by FabriceNeyret2
// https://www.shadertoy.com/view/MsdGDs

// now deprecated: see huge one + interaction here: https://www.shadertoy.com/view/wXcXDM

// inspired from http://evasion.imag.fr/~Fabrice.Neyret/demos/JS/Vort.html


void mainImage( out vec4 O,  vec2 U )
{
	O = texture(iChannel0,U/iResolution.xy);   
}