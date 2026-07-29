// Image (image) — Wriggly by huwb
// https://www.shadertoy.com/view/ld3SW7

// Supposed to have music but may not work :/. Clicking pause/play in iChannel1 may fix it.

// Writeup: http://www.huwbowles.com/shader-breakdown-wriggly/ . UPDATE: Sorry it's dead now,
// might bring it back one day.

// Inspired by Edge of Tomorrow Mimic tech: https://www.youtube.com/watch?v=iiKeTPL6HPk .
// I love the way they generate the tentacles, it's shown in the video from 1:30 onwards.
// the video shows a cross section that is swept along the length of the tentacle to generate it.
// each circle rotates around the origin at a fixed angular rate. then collisions are resolved
// between circles. ensuring circles don't intersect will guarantee tentacles dont intersect.

// this was a challenge to do stateless and fast to raymarch against. i initially resolved hard
// collisions between circles but this could result in extremely fast pops which gives a
// slicing/skewed appearance, and it was hard to sort this statelessly without many evaluations
// for smoothing etc (and i think smoothing could result in self-intersections)

// instead I give each tentacle a smooth potential field (instead of a hard circle collision),
// and use this as a force field to separate tentacles which smooths out motion. a broken
// version of this code resulted in Inky! https://www.shadertoy.com/view/4d3SD8

// sadly there can still be fast motion of the circles which results in kinks and loss of volume
// in the tentacles. it would be possible to divide by the gradient to preserve volume but i think
// that would double the taps, ill just leave it like this for now.

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    fragColor = vec4(0.);
    
    float uvr = 2.*length(uv-.5);
    float v = pow(uvr,2.);
    v = max(v,0.05);
    vec3 bg = .15-.07*vec3(uvr);
    bg.r *= .75;
    
    // poor mans blur. not quite box, cut off the corners to reduce boxyness
    #define R 3.
    float twt = 0.;
    for( float i = -R; i <= R; i++ )
    {
        for( float j = -R; j <= R; j++ )
        {
            if( abs(i)+abs(j) > 5. ) continue; // corners not welcome
            
            vec4 s = texture( iChannel0, uv + 2.*v*vec2(i,j)/iResolution.xy );
            
            s.xyz = mix( bg, s.xyz, s.a );
		    fragColor += s;
            twt += 1.;
        }
    }
    fragColor /= twt;
    //fragColor.xyz = pow(fragColor.xyz,vec3(1.)*(1.-v/12.*vec3(1.,.1,1.)));
    
    //fragColor = texture( iChannel0, uv );
    
    fragColor *= 2.;
}
