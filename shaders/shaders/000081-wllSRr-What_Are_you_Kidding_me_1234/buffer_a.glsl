// Buffer A (buffer) — What! Are you Kidding me? 1234 by wyatt
// https://www.shadertoy.com/view/wllSRr

void mainImage( out vec4 Q, in vec2 U )
{
    Q = A(U);
    Q += B(U);
    if (iFrame < 1) Q = sin(.01*length(U-0.5*R)*vec4(1,2,3,4));
	if(iMouse.z>0.&&length(U-iMouse.xy)<24.||(length(U-0.5*R)<2.&&iFrame<2)) Q = sin(iTime*vec4(1,2,3,4));
}