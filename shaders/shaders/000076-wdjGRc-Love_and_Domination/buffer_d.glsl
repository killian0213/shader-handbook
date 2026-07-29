// Buffer D (buffer) — Love and Domination by wyatt
// https://www.shadertoy.com/view/wdjGRc

// color
vec2 R;
vec4 A (vec2 U) {return texture(iChannel0,U/R);}
vec4 B (vec2 U) {return texture(iChannel1,U/R);}
vec4 C (vec2 U) {return texture(iChannel2,U/R);}
void mainImage( out vec4 Q, in vec2 U )
{	R = iResolution.xy;
 	vec4 c = C(U);
 	vec4 
        n = C(U+vec2(0,1)),
        e = C(U+vec2(1,0)),
        s = C(U+vec2(0,-1)),
        w = C(U+vec2(-1,0));
 	vec4 a = A(U);
 	float r=smoothstep(1.,0.5,length(U-a.xy));
 	vec4 f = 
        (r*float(a.w==0.))*vec4(.8,.6,.3,1)+
        (r*float(a.w==1.))*vec4(.9,.2,.4,1)+
        (r*float(a.w==2.))*vec4(.2,.7,.9,1);
 	Q = 2.*f*(0.5+0.5*(n-s+e-w));
}