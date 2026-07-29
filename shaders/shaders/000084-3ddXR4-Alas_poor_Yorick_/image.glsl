// Image (image) — Alas, poor Yorick! by shau
// https://www.shadertoy.com/view/3ddXR4

// Created by SHAU - 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//-----------------------------------------------------

/*

    Inspired by Billelis (kind of)

    Another nice skull example on Shadertoy - Lost_Astronaut by Duvengar
    https://www.shadertoy.com/view/Mlfyz4
*/

const float GA =2.399; 

// simplified version of Dave Hoskins blur from Virgill
vec3 dof(sampler2D tex, vec2 uv, float rad) {
	vec3 acc = vec3(0);
    vec2 pixel = vec2(.002*R.y/R.x, .002), angle = vec2(0, rad);;
    rad = 1.;
	for (int j = 0; j < 80; j++) {  
        rad += 1. / rad;
	    angle *= rot(GA);
        vec4 col=texture(tex,uv+pixel*(rad-1.)*angle);
		acc+=col.xyz;
	}
	return acc/80.;
}

void mainImage(out vec4 C, vec2 U) {
    
    vec2 uv = U / R;
	vec3 pc = vec4(dof(iChannel0, uv, texture(iChannel0, uv).w), 1.).xyz;
    
    C = vec4(pc, 1.);
}