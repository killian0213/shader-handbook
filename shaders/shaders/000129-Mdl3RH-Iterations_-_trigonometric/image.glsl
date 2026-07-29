// Image (image) — Iterations - trigonometric by iq
// https://www.shadertoy.com/view/Mdl3RH

// Copyright Inigo Quilez, 2013 - https://iquilezles.org/
// I am the sole copyright owner of this Work. You cannot
// host, display, distribute or share this Work neither as
// is or altered, in any form including physical and
// digital. You cannot use this Work in any commercial or
// non-commercial product, website or project. You cannot
// sell this Work and you cannot mint an NFTs of it. You
// cannot use this Work to train AI models. I share this
// Work for educational purposes, you can link to it as
// an URL, proper attribution and unmodified screenshot,
// as part of your educational material. If these
// conditions are too restrictive please contact me.

// More information here:
//
// https://iquilezles.org/articles/popcorns/
//
//
//
// Other "Iterations" shaders:
//
// "trigonometric"   : https://www.shadertoy.com/view/Mdl3RH
// "trigonometric 2" : https://www.shadertoy.com/view/Wss3zB
// "circles"         : https://www.shadertoy.com/view/MdVGWR
// "coral"           : https://www.shadertoy.com/view/4sXGDN
// "guts"            : https://www.shadertoy.com/view/MssGW4
// "inversion"       : https://www.shadertoy.com/view/XdXGDS
// "inversion 2"     : https://www.shadertoy.com/view/4t3SzN
// "shiny"           : https://www.shadertoy.com/view/MslXz8
// "worms"           : https://www.shadertoy.com/view/ldl3W4
// "stripes"         : https://www.shadertoy.com/view/wlsfRn

#define AA 2

vec2 iterate( in vec2 p, in vec4 t )
{
    return p - 0.05*cos(t.xz + p.x*p.y + cos(t.yw+1.5*3.1415927*p.yx)+p.yx*p.yx );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float time = iTime*6.283185/60.0;
    
    vec4 t = time*vec4( 1.0, -1.0, 1.0, -1.0 ) + vec4(0.0,2.0,3.0,1.0);

    vec3 tot = vec3(0.0);
    
    #if AA>1
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (-iResolution.xy + 2.0*(fragCoord+o))/iResolution.y;
        #else    
        vec2 p = (-iResolution.xy + 2.0*fragCoord)/iResolution.y;
        #endif

        p *= 1.5;	

        vec2 z = p;
        vec3 s = vec3(0.0);
        for( int i=0; i<100; i++ ) 
        {
            z = iterate( z, t );

            float d = dot( z-p, z-p ); 
            s.x += 1.0/(0.1+d);
            s.y += sin(atan( p.x-z.x, p.y-z.y ));
            s.z += exp(-0.2*d );
        }
        s /= 100.0;

        vec3 col = 0.5 + 0.5*cos( vec3(0.0,0.4,0.8) + 2.5 + s.z*6.2831 );

        col *= 0.5 + 0.5*s.y;
        col *= s.x;
        col *= 0.94+0.06*sin(10.0*length(z));

        vec3 nor = normalize( vec3( dFdx(s.x), 0.02, dFdy(s.x) ) );
        float dif = dot( nor, vec3(0.7,0.1,0.7) );
        col -= 0.05*vec3(dif);

        col *= 3.2/(3.0+col);
        
	    tot += col;
    #if AA>1
    }
    tot /= float(AA*AA);
    #endif


	vec2 q = fragCoord / iResolution.xy;
	tot *= 0.3 + 0.7*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.2 );
	
	fragColor = vec4( tot, 1.0 );
}
