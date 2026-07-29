// Image (image) — Fire [326] by Xor
// https://www.shadertoy.com/view/WXX3RH

/*
    "Fire" by @XorDev
    
    An attempt to create a fire effect in 280 chars.
    See my twigl example here:
    https://x.com/XorDev/status/1903168199069216954
    
    One-Pass Fire:
    https://www.shadertoy.com/view/tf2SWc
    
    Turbulent Flame:
    https://www.shadertoy.com/view/wffXDr
    
    
    FabriceNeyret2: -11
*/

//Noise Texture
#define T texture(iChannel0, p

void mainImage(out vec4 O, vec2 I)
{
    //Resolution for scaling and centering
    vec2  r = iResolution.xy,
    //Centered, aspect-correct coordinates
          p = ( I+I - r ) / r.y,
    //Vector for wave rotation
          R;
    //Expand coordinates vertically
    p *= 1. - .5 / vec2( 1./p.y  , 1. + p*p );
    
    //Time for scrolling and turbulence
    float t = iTime, 
    //Starting wave frequency (and magic rotation number)
          F = R.x = 11.;
    //Scroll upward and loop through turbulence waves
    //https://mini.gmshaders.com/p/turbulence
    for( p.y -= t ; F < 50.; F *= 1.2 )
        //Add waves and rotate
        p += .4* sin( F* dot( p, sin(++R) ) + 6.*t ) * cos(R)/F;
    
    //Sample noise for distance field
    F = T/8.).r;
    //Get approximate distance to fire source
    t = length(p+vec2(0,t+.5)) / .8 - F;
    //Add more noise for additional texturing
    F += T/4.).g;
    
    //Compute brightness with a higher falloff outside the fire
    //Tanh for tonemapping
    //https://mini.gmshaders.com/p/tonemaps
    O = tanh( F / ( .2 - .1*F 
                   + t*t * (t < 0. ? 5. : 50. )
                  ) / vec4(1,3,9,1)
            );
}

//Original [337]
/*
#define T texture(iChannel0, p

void mainImage(out vec4 O, vec2 I)
{
    //Resolution for scaling and centering
    vec2 r = iResolution.xy,
    //Centered, aspect-correct coordinates
    p = (I+I - r) / r.y,
    //Vector for wave rotation
    R;
    //Expand coordinates vertically
    p *= 1.-.5/vec2(1./p.y,1.+p*p);
    //Time for scrolling and turbulence
    float t = iTime,
    //Starting wave frequency (and magic rotation number)
    F = 11.,
    //Approximated distance to fire
    d;
    //Scroll upward
    p.y -= t;
    //Loop through turbulence waves
    //https://mini.gmshaders.com/p/turbulence
    for(R.x = F; F<50.; F*=1.2)
        //Add waves and rotate
        p += .4*sin(F*dot(p,sin(++R))+6.*t)*cos(R)/F;
    
    //Sample noise for distance field
    F = T/8.).r;
    //Get distance to fire source
    d = length(p+vec2(0,t+.5))/.8-F;
    //Add more noise for texturing
    F += T/4.).g;
    
    //Compute brightness with a higher falloff outside the fire
    //Tanh for tonemapping
    //https://mini.gmshaders.com/p/tonemaps
    O = tanh(F / (.2-.1*F + max(d/.1,-d)*abs(d)/.2) / vec4(1,3,9,1));
}
*/