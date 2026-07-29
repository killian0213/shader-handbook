// Image (image) — Biological Particles by wyatt
// https://www.shadertoy.com/view/3tBGzh

/*

	Fluid dynamics controls velocity field.
	Particles translate with the velocity field.
	Particles reproduce as they move. 
	Particles diffuse  4  hormones. 
	Diffusion is mediated by a 2 pass multi-scale gaussian blur.
	Particles experience a force from each hormone.
	The force is proportional to their own hormone signature. 
	Each hormone diffuses with a different radius. 
	Each initial particle has its own hormone signature.
	Then they battle it out! 

*/
void mainImage( out vec4 Q, in vec2 U)
{
    vec4 b = B(U);
    vec4 h = (hash(b.w));
    Q = smoothstep(2.,0.,length(b.xy-U))*(.5+2.*h);
	//Q = abs(D(U));
}