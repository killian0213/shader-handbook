// Image (image) — Golden Ratio and Spiral by iq
// https://www.shadertoy.com/view/fslyW4

// Copyright Inigo Quilez, 2022 - https://iquilezles.org/
// I am the sole copyright owner of this Work.
// You cannot host, display, distribute or share this Work neither
// as it is or altered, here on Shadertoy or anywhere else, in any
// form including physical and digital. You cannot use this Work in any
// commercial or non-commercial product, website or project. You cannot
// sell this Work and you cannot mint an NFTs of it or train a neural
// network with it without permission. I share this Work for educational
// purposes, and you can link to it, through an URL, proper attribution
// and unmodified screenshot, as part of your educational material. If
// these conditions are too restrictive please contact me and we'll
// definitely work it out.

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // pixel coordinates
    vec2  op  = (2.0*fragCoord-iResolution.xy)/iResolution.y;
    float opx = 2.0/iResolution.y;
    
    // mathematical constants
    const float kt = 6.283185307;         // tau
    const float kh = (1.0+sqrt(5.0))/2.0; // phi
    const float k2 = 4.0*log2(kh);

    // for time and color dithering
    float ran = fract(sin(fragCoord.x*7.0+17.0*fragCoord.y)*1.317);

    // motion blur loop
    vec3 tot = vec3(0.0);
    #if HW_PERFORMANCE==0
    const int kNumSamples = 6;
    #else
    const int kNumSamples = 12;
    #endif
    for( int mb=0; mb<kNumSamples; mb++ )
    {
        // aperture is half of a frame
        float time = iTime + (0.5/60.0)*(float(mb)+ran)/float(kNumSamples);

        // loop
        float ft = fract(time/1.0);
        float it = floor(time/1.0);

        // constant (exponential) zoom
        float sca = 0.5*exp2(-ft*k2);
        vec2  p  = sca*op;
        float px = sca*opx;

        // draw golden rectangles
        vec3 col = vec3(0.0);
        {
            float d = 1e20;
            float w = 1.0;
            vec2  q = p +  vec2(3,-1)/sqrt(5.0);
            for( int i=0; i<20; i++ )
            {
                // square (in L2)
                float t = max(abs(q.x),abs(q.y))-w;

                // fill
                if( t<0.0 )
                {
                    // color  (https://iquilezles.org/articles/palettes)
                    float id = float(i) + it*4.0;
                    col = vec3(0.7,0.5,0.4) + vec3(0.1,0.2,0.2)*cos(kt*id/12.0+vec3(2.0,2.5,3.0) );
                    // texture
                    col += 0.04*cos(kt*p.x*8.0/w)*cos(kt*p.y*8.0/w);
                }    

                // border (https://iquilezles.org/articles/distfunctions2d)
                d = min( d, abs(t)-0.001*w );

                // displace, rotate and scale for next iteration
                q -= w*vec2(kh,2.0-kh);
                q  = vec2(-q.y,q.x);
                w *= kh-1.0; // should be w /= kh, but luckily 1/phi = phi-1
            }
            col *= smoothstep( 0.0, 1.5*px, d-0.001*sca );
        }

        // draw spiral (https://www.shadertoy.com/view/fslyWN)
        {
            p  /= (3.0-kh); // p  /= (2.0-1.0/kh);
            px /= (3.0-kh); // px /= (2.0-1.0/kh);
            float ra = length(p);
            float an = atan(-p.x,p.y)/kt;
            float id = round( log2(ra)/k2 - an );
            if( id>-1.5 || (id>-2.5 && an>0.5-ft) )
            {
                float d = abs( ra - exp2(k2*(an+id)) );
                col = mix( col, vec3(1.0), smoothstep( 2.0*px, 0.0, d-0.005*sca ) );
            }
        }
        // accumulate
        tot += col;
    }
    // resolve
    tot /= float(kNumSamples);

    // vignetting
    tot *= 1.2-0.25*length(op);
    
    // remove color banding through dithering
    tot += (1.0/255.0)*ran;

    // output
    fragColor = vec4(tot,1.0);
}