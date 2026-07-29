// Buffer B (buffer) — Love and Domination by wyatt
// https://www.shadertoy.com/view/wdjGRc

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
        vec4 c = a.z*smoothstep(1.,.5,length(U+vec2(i,0)-a.xy))*vec4(a.w==0.,a.w==1.,a.w==2.,0);
        Q += c*sqrt(s2)/s2*exp(-i*i*0.5/s2);
 	}
 		
 	
}
