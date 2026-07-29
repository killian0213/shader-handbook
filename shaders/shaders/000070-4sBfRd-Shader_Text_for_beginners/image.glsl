// Image (image) — Shader Text for beginners by PrzemyslawZaworski
// https://www.shadertoy.com/view/4sBfRd

//thanks to Fabrice Neyret: https://www.shadertoy.com/view/llySRh
//and thanks to otaviogood for font texture
#define C(c) U.x-=.5; O+= char(U,64+c)

vec4 char(vec2 p, int c) 
{
    if (p.x<.0|| p.x>1. || p.y<0.|| p.y>1.) return vec4(0,0,0,1e5);
	return textureGrad( iChannel0, p/16. + fract( vec2(c, 15-c/16) / 16. ), dFdx(p/16.),dFdy(p/16.) );
}

void mainImage( out vec4 O, vec2 uv )
{
    O = vec4(0.0);
    uv /= iResolution.y;
    vec2 position = vec2(.5);
    float FontSize = 8.;
    vec2 U = ( uv - position)*64.0/FontSize;
    C(8);C(5);C(12);C(12);C(15);C(-32);C(23);C(15);C(18);C(12);C(4);C(-31);
    O = O.xxxx;
}


//line 12 -> x,y coordinates of text, counted from left down corner
//line 13 -> higher value = greater font size
//line 15 -> Every argument is another char