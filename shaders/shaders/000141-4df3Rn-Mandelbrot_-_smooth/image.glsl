// Image (image) — Mandelbrot - smooth by iq
// https://www.shadertoy.com/view/4df3Rn

// Created by inigo quilez - iq/2013
// https://www.youtube.com/c/InigoQuilez
// https://iquilezles.org

// More information on the smooth iteration count here:
// https://iquilezles.org/articles/msetsmooth

// increase this if you have a very fast GPU
#define AA 2

float mandelbrot( in vec2 c )
{
    #if 1
    // early exit opportunities
    float c2 = dot(c, c);
    // inside M1 - https://iquilezles.org/articles/mset1bulb
    if( 256.0*c2*c2 - 96.0*c2 + 32.0*c.x - 3.0 < 0.0 ) return 0.0;
    // inside M2 - https://iquilezles.org/articles/mset2bulb
    if( 16.0*(c2+2.0*c.x+1.0) - 1.0 < 0.0 ) return 0.0;
    #endif

    // iterate and track orbit
    const float B = 256.0;
    float n = 0.0;
    vec2 z  = vec2(0.0);
    for( int i=0; i<512; i++ )
    {
        z = vec2( z.x*z.x-z.y*z.y, 2.0*z.x*z.y ) + c;
        if( dot(z,z)>(B*B) ) break;
        n += 1.0;
    }

    if( n>511.0 ) return 0.0;
    
    // smooth interation count:
    // float sn = n - log(log(length(z))/log(B))/log(2.0);
    // equivalent simplified smooth interation count:
    float sn = n - log2(log2(dot(z,z))) + 4.0;

    float al = smoothstep( -0.1, 0.0, sin(3.1415927*iTime ) );
    return mix( n, sn, al );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 col = vec3(0.0);
    
    #if AA>1
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        vec2 p = (2.0*(fragCoord+vec2(float(m),float(n))/float(AA))-iResolution.xy)/iResolution.y;
        float w = float(AA*m+n);
        float time = iTime + 0.5*(1.0/24.0)*w/float(AA*AA);
    #else    
        vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;
        float time = iTime;
    #endif
    
        // animate (rotation and zoom)
        float  ani = 0.62 + 0.38*cos(0.07*time);
        float  zoo = pow(ani,8.0);
        float  ang = 0.15*(1.0-ani)*time;
        float   co = cos(ang);
        float   si = sin(ang);
        mat2x2 rot = mat2x2(co,si,-si,co);
        vec2 c = vec2(-0.745,0.186) + zoo*rot*p;

        // get the (smooth) iteration count
        float sn = mandelbrot(c);

        // colorize with a blue-yellow color palette
        if( sn>0.0 )
        {
          float nor = 1.0+log2(1.0/zoo);
          // https://iquilezles.org/articles/palettes/
          col += 0.5+0.5*cos(0.2*sn/nor+vec3(2.7,3.2,3.7));
        }
        
    #if AA>1
    }
    col /= float(AA*AA);
    #endif

    fragColor = vec4( col, 1.0 );
}