// Buffer A (buffer) — Fractal Explorer by Dave_Hoskins
// https://www.shadertoy.com/view/4s3GW2

// Buffer A stores first time the mouse was clicked, for keeping relative rotations.

// by David Hoskins
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

vec2 clickStore	= vec2(4.,  0.);

float isInside( vec2 p, vec2 c ) { vec2 d = abs(p-0.5-c) - 0.5; return -max(d.x,d.y); }

float loadValue1( in vec2 re )
{
    return texture( iChannel0, (0.5+re) / iChannelResolution[0].xy, -100.0 ).x;
}

void storeValue1( in vec2 re, float va, inout vec4 fragColor, in vec2 fragCoord )
{
    fragColor = ( isInside(fragCoord, re) > 0.0 ) ? vec4(va, .0, .0, .0) : fragColor;
}
void mainImage( out vec4 fragColour, in vec2 fragCoord )
{

	fragColour = vec4(0);
    float click = 0.0;
    float oldClick = loadValue1(clickStore);
    if (iFrame == 0) oldClick = 0.0;
        
    if (iMouse.z > 0.0)
   	{
      if (oldClick == .0)
        click = 1.0;
    }
  
	storeValue1(clickStore, click,  fragColour, fragCoord);

}