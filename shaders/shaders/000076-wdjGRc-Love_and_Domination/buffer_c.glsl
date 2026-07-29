// Buffer C (buffer) — Love and Domination by wyatt
// https://www.shadertoy.com/view/wdjGRc

// Blur pass 2
vec2 R;
vec4 A (vec2 U) {return texture(iChannel0,U/R);}
vec4 B (vec2 U) {return texture(iChannel1,U/R);}
vec4 C (vec2 U) {return texture(iChannel2,U/R);}
void mainImage( out vec4 Q, in vec2 U )
{	R = iResolution.xy;
	Q = vec4(0);
 	for (float i = -BLUR_DEPTH ; i <= BLUR_DEPTH ; i++) {
 		vec4 c = B(U+vec2(0,i));
        Q += 2.*c*sqrt(s2)/s2*exp(-i*i*0.5/s2);
 	}
 	Q = mix(Q,C(U),0.1);
 	
}
