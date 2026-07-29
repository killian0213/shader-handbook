// Buffer D (buffer) — Communication and Grouping by wyatt
// https://www.shadertoy.com/view/wtSSDm


void mainImage( out vec4 Q, in vec2 U )
{
   Q = C(U);
   
   Q.w = .1*Q.x - Q.y;
   
    if (iMouse.z>0.) Q.w -= 100.*exp(-.05*length(iMouse.xy-U));
   Q.w = mix(Q.w,D(U).w,.75);
}