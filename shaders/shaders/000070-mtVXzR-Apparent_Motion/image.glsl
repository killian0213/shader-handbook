// Image (image) — Apparent Motion by fenix
// https://www.shadertoy.com/view/mtVXzR

// ---------------------------------------------------------------------------------------
//	Created by fenix in 2023
//	License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
//  Inspired by:
//
//      https://www.reddit.com/r/OpticalIllusionGifs/comments/13zaowf/no_object_except_for_the_arrows_moves/
//
//  The shapes are not actually moving (just changing colors), except for the arrows!
//  And the arrows do not slide either...they only flip and rotate.
//
//  I actually have no idea why we see the apparent motion...I basically fiddled with
//  coloring the edges until it looked like it started moving. However it works, this
//  design does an amazing job magnifying it. Having the bars "move" the opposite
//  direction from the circle keeps balance, which amplifies the motion effect. The 
//  same goes for the rotation of the colors opposing in the inner circle and the
//  outer bars. It's also very helpful that the arrows alternate directions to relieve
//  the cognitive "pressure" caused by the objects appearing to move towards each other
//  but not get any closer. The arrows support the motion illusion (by priming your
//  expectations) but also act as a red herring as you try to figure out what is 
//  happening.
//
//  * press space to turn off the colors *
//
//  I did experiment with golfing this shader, but the result wasn't very short or
//  interesting and it was a lot harder to read, so I went with a mostly non-golfed
//  style. If anyone still wants to golf this I'll still post the results.
//
// ---------------------------------------------------------------------------------------

#define PI 3.14159

// from iq: https://iquilezles.org/articles/distfunctions2d/
float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float sdEquilateralTriangle( in vec2 p, in float r )
{
    const float k = sqrt(3.0);
    p.x = abs(p.x) - r;
    p.y = p.y + r/k;
    if( p.x+k*p.y>0.0 ) p = vec2(p.x-k*p.y,-k*p.x-p.y)/2.0;
    p.x -= clamp( p.x, -2.0*r, 0.0 );
    return -length(p)*sign(p.y);
}

float arrows(vec2 u, float t, float a)
{
    // control space to rotate/mirror/flip a single arrow as needed
    float s = 1.;
    if (t < 10.)
    {
        // rotating single arrow
        u *= mat2(cos(a), -sin(a), sin(a), cos(a));
    }
    else
    {     
        s = 2.; // correct for minification
        
        // four small arrows
        if (abs(u.y) < abs(u.x))
        {
            // left and right arrows
            u = abs(u.yx) * 2. - vec2(0, .15);
            u.y = mod(t, 5.) > 2.5 ? -u.y : u.y;
        }
        else
        {
            // up and down arrows
            u = abs(u) * 2. - vec2(0, .15);
            u.y = abs(t - 15.) > 2.5 ? -u.y : u.y;
        }
    }

    // draw one arrow
    float d = sdBox(u, vec2(.01, .04));
    return min(d, sdEquilateralTriangle(u - vec2(0, .05), .03)) * s;
}

float circle(vec2 p)
{
    p = abs(p);
    float d = abs(length(p) - .2) - .05; // circle shape
    float a = (trunc(atan(p.y, p.x) * 6. / PI) + .5) * PI / 6.; // angle of nearest hole
    vec2 x = vec2(cos(a), sin(a)) * .2; // closest hole center
    return max(d, .042 - length(p - x));
}

float bars(vec2 p)
{
    p = abs(p);
    float d = abs(p.x - .4) - .04; // bar shape
    return max(d, .035 - length(vec2(p.x - .4, mod(p.y, .16) - .08))); // cut the holes
}

#define keyDown(ascii)    ( texelFetch(iChannel3,ivec2(ascii,0),0).x > 0.)
#define KEY_SPACE 32

vec3 color(float x)
{
    vec3 c = sin(x * PI + vec3(0, 1, 2));
    return keyDown(KEY_SPACE) || iMouse.z > 0. ? vec3(0) : c * c;
}

vec2 map(vec2 u, float t, float a)
{
    float d, c; // distance, color
    if (length(u) < .3)
    {
        if (length(u) < .14)
        {
            d = arrows(u, t, a);
            c = u.x + u.y;
        }
        else
        {
            d = circle(u);
            c = atan(u.y, u.x) * .5 / PI;
        }
    }
    else
    {
        d = bars(u); // vertical bars
        float h = bars(u.yx); // horizontal bars
        
        if (u.x * u.y > 0. ? d > h || h < 0. : h < d && d > 0.) // overlap bars correctly
            c = u.x * sign(u.y) + PI * .5;
        else 
            c = -u.y * sign(u.x);
            
        d = min(d, h);
    }

    return vec2(smoothstep(3./iResolution.y, 0., d), c);
}

void mainImage( out vec4 O, vec2 u )
{
    u = (u - .5 * iResolution.xy) / iResolution.y;
    
    float t = mod(iTime, 20.);
    float a = min(mod((trunc(t / 2.5) + smoothstep(2., 2.5, mod(t, 2.5))) * .5, 4.), 1.5) * PI; // arrow angle

    vec2 l = t < 10. ? vec2(sin(a), cos(a)) : // light (?)
             t < 12.5 ? u * vec2(1, -1) :
             t < 15. ? u * vec2(-1, 1) :
             t < 17.5 ? u : -u;
    
    vec2 e = vec2(.002 + 1. / iResolution.y, 0);
    vec2 n = vec2(map(u + e.xy, t, a).x - map(u - e.xy, t, a).x, // normal
                  map(u + e.yx, t, a).x - map(u - e.yx, t, a).x);
    vec2 r = map(u, t, a); // density, color
    
    O.xyz = mix(vec3(.5), color(iTime * 2. + dot(n, normalize(length(u) > .3 ? -l : l)) * .25 + r.y), r.x);
    O.a = 1.;
}
