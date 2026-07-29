// Image (image) — Deform - holes by iq
// https://www.shadertoy.com/view/4sXGzn

// Copyright Inigo Quilez, 2013 - https://iquilezles.org/
// I am the sole copyright owner of this Work.
// You cannot host, display, distribute or share this Work in any form,
// including physical and digital. You cannot use this Work in any
// commercial or non-commercial product, website or project. You cannot
// sell this Work and you cannot mint an NFTs of it.
// I share this Work for educational purposes, and you can link to it,
// through an URL, proper attribution and unmodified screenshot, as part
// of your educational material. If these conditions are too restrictive
// please contact me and we'll definitely work it out.

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
  vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;
  vec2 m = (2.0*iMouse.xy-iResolution.xy)/iResolution.y;

  float a1 = atan(p.y-m.y,p.x-m.x); float r1 = length(p-m);
  float a2 = atan(p.y+m.y,p.x+m.x); float r2 = length(p+m);

  vec2 uv = vec2( 0.2*(r1-r2) + 0.2*iTime,
                  asin(sin(a1-a2))/3.1415927 );
  vec3 col = texture( iChannel0, 0.125*uv ).zyx;

  float w = exp2(-18.0*r1*r1) + exp2(-18.0*r2*r2);
  w += 0.25*smoothstep( 0.93,1.0,sin(128.0*uv.x));
  w += 0.25*smoothstep( 0.93,1.0,sin(128.0*uv.y));
	
  fragColor = vec4(col+w,1.0);
}
