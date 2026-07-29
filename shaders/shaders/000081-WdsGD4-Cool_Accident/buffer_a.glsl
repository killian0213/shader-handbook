// Buffer A (buffer) — Cool Accident by wyatt
// https://www.shadertoy.com/view/WdsGD4

vec2 R;
vec4 t (vec2 U) {
	return texture(iChannel0,U/R);
}
vec2 dp (vec2 U) {
	return vec2(dFdx(t(U).z),dFdy(t(U).z));
}
vec4 T (vec2 U) {
	U -= t(U).xy + dp(U);
	U -= t(U).xy + dp(U);
    return t(U);
}
void mainImage( out vec4 C, in vec2 U )
{
   R = iResolution.xy;
   
   vec4 me = T(U),
        n = T(U+vec2(0,1)),
        e = T(U+vec2(1,0)),
        s = T(U-vec2(0,1)),
        w = T(U-vec2(1,0));
  
   C = me;
   C.x += 0.6*(e.z-w.z);
   C.y += 0.6*(n.z-s.z);
   C.z += 0.6*(s.y-n.y+w.x-e.x);
   C *= 0.994;
   if (length(U-0.5*R)<3.)C = vec4(0.3,0,0,1);
   if (iFrame < 1) {
       C = vec4(0,0,0,0);
   }
}