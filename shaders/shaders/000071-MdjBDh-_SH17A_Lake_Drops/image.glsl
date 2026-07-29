// Image (image) — [SH17A] Lake Drops by fizzer
// https://www.shadertoy.com/view/MdjBDh

void mainImage(out vec4 o,vec2 c)
{
	vec2 u=c/iResolution.x*2.-1.,a=u-u;
    u/=(u.y+=.8)-1.;
    for(float i=0.;i++<65.;c=u-cos(vec2(919.,154.)*i)*4.+2.,a+=c/dot(c,c)*sin(20.*clamp(length(c)-mod(i*.12+iTime,3.),-.157,.157)))
		o=texture(iChannel0,vec3(a-u*6.,5.))*.7+texture(iChannel1,u)*.4;
}