// Buffer B (buffer) — Everything's A Caustic by wyatt
// https://www.shadertoy.com/view/WdBGDm

vec2 R;
vec4 A (vec2 U) {return texture(iChannel0,U/R);}
vec4 B (vec2 U) {return texture(iChannel1,U/R);}
void mainImage( out vec4 C, in vec2 U)
{
    R = iResolution.xy;
    float 
  		n = A(U+vec2(0,1)).z,
  		e = A(U+vec2(1,0)).z,
  		s = A(U-vec2(0,1)).z,
  		w = A(U-vec2(1,0)).z;
    #define N 2.
    for (float i = 0.; i < N; i++)
        U -= A(U).xy/N;
    C.xy = U;
    C.zw = vec2(e-w,n-s);
}