// Image (image) — Alcatraz - Equilibrium by Virgill
// https://www.shadertoy.com/view/ls2BRG

// **************************************************************************
// Alcatraz - Equilibrium - 4K intro 
// by Jochen "Virgill" Feldkötter (jochen.feldkoetter{a}osnanet.de)
//
// 4kb executable: 	http://www.pouet.net/prod.php?which=71136
// Youtube: 		https://www.youtube.com/watch?v=T6ulp8b8eHw
// Soundtrack:		https://soundcloud.com/virgill/virgill-4klang-equilibrium
// **************************************************************************


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy ;
    vec3 tex= texture(iChannel0,uv).xyz;
	fragColor = vec4(tex,0.);
}