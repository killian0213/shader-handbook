// Image (image) — Julia - Traps 2 by iq
// https://www.shadertoy.com/view/4dfGRn

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

// Julia - Traps 1 : https://www.shadertoy.com/view/4d23WG
// Julia - Traps 2 : https://www.shadertoy.com/view/4dfGRn

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;

    float time = 30.0 + 0.1*iTime;
    vec2 cc = 1.1*vec2( 0.5*cos(0.1*time) - 0.25*cos(0.2*time), 
	                    0.5*sin(0.1*time) - 0.25*sin(0.2*time) );

	vec4 dmin = vec4(1000.0);
    vec2 z = p;
    for( int i=0; i<64; i++ )
    {
        z = cc + vec2( z.x*z.x - z.y*z.y, 2.0*z.x*z.y );

		dmin=min(dmin, vec4(abs(0.0+z.y + 0.5*sin(z.x)), 
							abs(1.0+z.x + 0.5*sin(z.y)), 
							dot(z,z),
						    length( fract(z)-0.5) ) );
    }
    
    vec3 col = vec3( dmin.w );
	col = mix( col, vec3(1.00,0.80,0.60),     min(1.0,pow(dmin.x*0.25,0.20)) );
    col = mix( col, vec3(0.72,0.70,0.60),     min(1.0,pow(dmin.y*0.50,0.50)) );
	col = mix( col, vec3(1.00,1.00,1.00), 1.0-min(1.0,pow(dmin.z*1.00,0.15) ));

	col = 1.25*col*col;
    col = col*col*(3.0-2.0*col);
	
    p = fragCoord/iResolution.xy;
	col *= 0.5 + 0.5*pow(16.0*p.x*(1.0-p.x)*p.y*(1.0-p.y),0.15);

	fragColor = vec4(col,1.0);
}