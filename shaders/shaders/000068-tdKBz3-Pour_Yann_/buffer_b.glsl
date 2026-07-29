// Buffer B (buffer) — Pour Yann  by wyatt
// https://www.shadertoy.com/view/tdKBz3

//Mouse
void mainImage( out vec4 C, in vec2 U )
{
    vec4 p = texture(iChannel0,U/iResolution.xy);
   	if (iMouse.z>0.) {
      if (p.z>0.) C =  vec4(iMouse.xy,p.xy);
    else C =  vec4(iMouse.xy,iMouse.xy);
   }
    else C = vec4(-iResolution.xy,-iResolution.xy);
}