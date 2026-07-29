// Image (image) — Love and Domination by wyatt
// https://www.shadertoy.com/view/wdjGRc

vec2 R;
vec4 D (vec2 U) {return texture(iChannel0,U/R);}\
void mainImage( out vec4 Q, in vec2 U )
{	R = iResolution.xy;
 	vec4 
        n = D(U+vec2(0,1)),
        e = D(U+vec2(1,0)),
        s = D(U+vec2(0,-1)),
        w = D(U+vec2(-1,0));
        
 	vec4 dx = e-w;
 	vec4 dy = n-s;
 	Q = (D(U)+abs(dx) + abs(dy))/3.;     
}