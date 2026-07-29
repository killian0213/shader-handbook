// Image (image) — Sinuous by nimitz
// https://www.shadertoy.com/view/4sGSDw

// Sinuous by nimitz (twitter: @stormoid)
// https://www.shadertoy.com/view/4sGSDw
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Contact the author for other licensing options

//Code is in the other tabs:
//Buf A = Particle velocity and position handling
//Buf B = Rendering

/*
	By using the scalar value of a combined noise function as the
	angle to define a normalized vector field, we can produce a 
	divergence-free vector field as long as the angle varies smoothly
	which can then be used to create fluid-like motion for particles.

	The rest is scaling and offsetting the angles so that there 
	is a directional bias to the produced vector field. Allowing
	for directional motion without creating divergence (and therefore
	pockets of "stuck" particles)

	The rest is just fancy coloring to create a visually pleasing effect.
*/


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{    
    vec2 p = fragCoord.xy/iResolution.xy;
    vec4 c = vec4(texture(iChannel0, p).rgb, 1.0);
    fragColor = vec4(mix(c, 1.-c, smoothstep(-.3,.3,sin(p.y+iTime*.0717+3.4))));
}