// Buffer C (buffer) — Lichtenberg figure 4 by rory618
// https://www.shadertoy.com/view/3tfSzs

void mainImage( out vec4 O, in vec2 I )
{

    O = texture(iChannel3,I/R.xy);
	O.w += 1.;
    O += texture(iChannel2,I/R.xy);
    if(iMouse.w>.5){
        O=vec4(0.);
    }
}