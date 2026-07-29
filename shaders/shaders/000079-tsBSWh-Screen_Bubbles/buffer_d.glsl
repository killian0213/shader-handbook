// Buffer D (buffer) — Screen Bubbles by wyatt
// https://www.shadertoy.com/view/tsBSWh

void mainImage( out vec4 Q, in vec2 U )
{
    vec4 p = texture(iChannel2,U/iResolution.xy);
   	if (iMouse.z>0.) {
      if (p.z>0.) Q =  vec4(iMouse.xy,p.xy);
    	else Q =  vec4(iMouse.xy,iMouse.xy);
   	}else Q = vec4(-iResolution.xy,-iResolution.xy);
}