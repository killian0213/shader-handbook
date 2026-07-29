// Buffer C (buffer) — Molecular Dance by wyatt
// https://www.shadertoy.com/view/WdB3WG

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
        Q += c*sqrt(FORCE_RANGE)/FORCE_RANGE*exp(-i*i*0.5/FORCE_RANGE);
 	}
 vec4 
        n = C(U+vec2(0,1)),
        e = C(U+vec2(1,0)),
        s = C(U+vec2(0,-1)),
        w = C(U+vec2(-1,0));
 	Q = C(U) + 0.5*(Q-C(U));
 	if (iMouse.z > 0.) Q.xy += vec2(10.)*exp(-vec2(.01,.05)*length(U-iMouse.xy));
}
