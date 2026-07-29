// Buffer B (buffer) — Molecular Dance by wyatt
// https://www.shadertoy.com/view/WdB3WG

// Blur pass 1
vec2 R;
vec4 A (vec2 U) {return texture(iChannel0,U/R);}
vec4 B (vec2 U) {return texture(iChannel1,U/R);}
vec4 C (vec2 U) {return texture(iChannel2,U/R);}
void mainImage( out vec4 Q, in vec2 U )
{	R = iResolution.xy;
	Q = vec4(0);
 	for (float i = -BLUR_DEPTH ; i <= BLUR_DEPTH ; i++) {
 		vec4 a = A(U+vec2(i,0));
        vec4 c = vec4(a.w,1.,0,0)*smoothstep(1.+0.05*abs(a.w),1.,length(U+vec2(i,0)-a.xy));
        Q += c*sqrt(FORCE_RANGE)/FORCE_RANGE*exp(-i*i*0.5/FORCE_RANGE);
 	}
 		
 	
}
