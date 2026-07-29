// Image (image) — Smoothsteps by iq
// https://www.shadertoy.com/view/st2BRd

// The MIT License
// Copyright © 2022 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// Nine different smoothsteps, as described at
// https://iquilezles.org/articles/smoothsteps/
//
//         ┎──────────────────────┰─────────────────────┰────────────────┒
// Top:    ┃ Cubic Polynomial     ┃ Quartic Polynomial  ┃ Polynomial     ┃
//         ┠──────────────────────╂─────────────────────╂────────────────┨
// Middle: ┃ Quadratic Rational   ┃ Cubic Rational      ┃ Rational       ┃
//         ┠──────────────────────╂─────────────────────╂────────────────┨
// Bottom: ┃ Piecewise Polynomial ┃ Piecewise Quadratic ┃ Trigonometric  ┃
//         ┖──────────────────────┸─────────────────────┸────────────────┚
//
// Blue:   smoothstep
// Gren:   inverse smoothstep
// Yellow: first derivative
// Red:    second derivative


// return smoothstep (.x), its inverse (.y) and its derivative (.z)
vec3 my_smoothstep( float x, int id )
{
    // Cubic Polynomial
    if( id==0 )
    {
        return vec3( // smoothstep
                     x*x*(3.0-2.0*x),
                     // inverse
                     0.5-sin(asin(1.0-2.0*x)/3.0),
                     // derivative
                     6.0*x*(1.0-x));
    }
    
    // Quartic Polynomial (note it's not symmetric)
    if( id==1 )
    {
        return vec3( // smoothstep
                     x*x*(2.0-x*x),
                     // inverse
                     sqrt(1.0-sqrt(1.0-x)),
                     // derivative
                     4.0*x*(1.0-x*x));
    }
    
    // Quintic Polynomial
    if( id==2 )
    {
        return vec3( // smoothstep
                     x*x*x*(x*(x*6.0-15.0)+10.0),
                     // inverse
                     -1.0, // no closed form
                     // derivative
                     30.0*x*x*(x*(x-2.0)+1.0));
    }
    
    // Quadratic Rational
    if( id==3 )
    {
        float d = 2.0*x*(x-1.0)+1.0;
        return vec3( // smoothstep
                     x*x/d,
                     // inverse
                     (x-sqrt(x*(1.0-x)))/(2.0*x-1.0),
                     // derivative
                     2.0*x*(1.0-x)/(d*d));
    }
    
    // Cubic Rational
    if( id==4 )
    {
        float d = 3.0*x*(x-1.0)+1.0;
        return vec3( // smoothstep
                     x*x*x/d,
                     // inverse
                     pow(x,1.0/3.0)/(pow(x,1.0/3.0)+pow(1.0-x,1.0/3.0)),
                     // derivative
                     3.0*x*x*(x*(x-2.0)+1.0)/(d*d) );
    }
    
    // General Rational, see https://www.shadertoy.com/view/WtSGWw
    if( id==5 )
    {
        const float k = 4.0;    // can be adjusted
        float a = pow(    x,k);
        float b = pow(1.0-x,k);
        return vec3( // smoothstep
                     a/(a+b),
                     // inverse
                     pow(x,1.0/k)/(pow(x,1.0/k)+pow(1.0-x,1.0/k)),
                     // derivative
                     -k*b*pow(x,k-1.0)/(x-1.0)/(a+b)/(a+b));
    }
    
    // Piecewise Polynomial
    if( id==6 )
    {
        const float k = 4.0;    // can be adjusted
        return (x<0.5) ? 
            vec3( // smoothstep
                  0.5*pow(2.0*x,k),
                  // inverse
                  0.5*pow(2.0*x,1.0/k),
                  // derivative
                  k*pow(2.0*x,k-1.0)) :
            vec3( // smoothstep
                  1.0-0.5*pow(2.0*(1.0-x),k),
                  // inverse
                  1.0-0.5*pow(2.0*(1.0-x),1.0/k),
                  // derivative
                  k*pow(2.0*(1.0-x),k-1.0));
    }

    // Piecewise Quadratic
    if( id==7 )
    {
        return (x<0.5) ? 
            vec3( // smoothstep
                  2.0*x*x,
                  // inverse
                  sqrt(0.5*x),
                  // derivative
                  4.0*x) :
            vec3( // smoothstep
                  2.0*x*(2.0-x)-1.0,
                  // inverse
                  1.0-sqrt(0.5-0.5*x),
                  // derivative
                  4.0-4.0*x);
    }
      
    // Trigonometric
    if( id==8 )
    {
        const float kPi = 3.1415927;
        return vec3( // smoothstep
                     0.5-0.5*cos(x*kPi),
                     // inverse
                     acos(1.0-2.0*x)/kPi,
                     // derivative
                     0.5*kPi*sin(x*kPi));
    }
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{	
    // coord
    vec2  p = fragCoord/iResolution.xy;
    float px = 4.0/iResolution.y;

    // tiling
    ivec2 id2 = ivec2( p*3.0 ); id2.y=2-id2.y;
    int id = id2.y*3 + id2.x;
    p = fract( p*3.0 );
    p.x *= 2.0;
    
    // render
    vec3 col = vec3(0.0);
    
    const float b1 = 0.04;
    const float b2 = 0.02;
    vec2 pa = (p-vec2(    b1,b1))/vec2(1.0-b1-b2,1.0-b1-b1);
    vec2 pb = (p-vec2(1.0+b2,b1))/vec2(1.0-b1-b2,1.0-b1-b1);

    if( max(abs(pa.x-0.5),abs(pa.y-0.5))<0.5 )
    {
        const float e = 0.005;
        pa.x = 0.5*e + pa.x*(1.0-e); // remap to prevent out of range

        col = vec3(0.15+0.02*sin(63.0*pa.x)*sin(63.0*pa.y));

        // identity
        {
        float di = abs(pa.y-pa.x);
        col = mix( col, vec3(0.5,0.5,0.5), 1.0-smoothstep( 0.005, 0.005+px, di ) );
        }

        // smoothstep and inverse
        {
        vec2 f = my_smoothstep( pa.x, id ).xy;
        vec2 df = ( 1.0*my_smoothstep(pa.x+0.5*e, id).xy-
                    1.0*my_smoothstep(pa.x-0.5*e, id).xy)/e;
        vec2 di = abs(pa.y-f)/sqrt(1.0+df*df);
        col = mix( col, vec3(0.0,0.6,0.3), 1.0-smoothstep( 0.005, 0.005+px, di.y ) );
        col = mix( col, vec3(0.0,0.8,1.0), 1.0-smoothstep( 0.005, 0.005+px, di.x ) );
        }
    }
    else if( max(abs(pb.x-0.5),abs(pb.y-0.5))<0.5 )
    {
        const float e = 0.005;
        pb.x = e + pb.x*(1.0-2.0*e); // remap to prevent out of range

        col = vec3(0.2);
        vec3   f  = my_smoothstep(pb.x, id);

        float  y  = f.x;
        float dy1 = f.z; // derivative
        float dy2 = (+1.0*my_smoothstep(pb.x+0.5*e, id).z
                     -1.0*my_smoothstep(pb.x-0.5*e, id).z)/e; // second derivative
        float dy3 = (+1.0*my_smoothstep(pb.x+1.0*e, id).z
                     -2.0*my_smoothstep(pb.x+0.0*e, id).z
                     +1.0*my_smoothstep(pb.x-1.0*e, id).z)/(e*e); // third derivative
        // axis
        {
        float di = abs(pb.y-0.5);
        col = mix( col, vec3(0.5,0.5,0.5), 1.0-smoothstep( 0.005, 0.005+px, di ) );
        }

        // y''(x) * 0.02
        if( !((id==6 || id==7) && abs(pb.x-0.5)<0.005) ) // hack to hide y'' discontinuities
        {
        float  f = 0.02*dy2 + 0.5;
        float df = 0.02*dy3;
        float di = abs(pb.y-f)/sqrt(1.0+df*df);
        col = mix( col, vec3(0.9,0.3,0.0), 1.0-smoothstep( 0.005, 0.005+px, di ) );
        }

        // y'(x) * 0.1
        {
        float  f = 0.1*dy1 + 0.5;
        float df = 0.1*dy2;
        float di = abs(pb.y-f)/sqrt(1.0+df*df);
        col = mix( col, vec3(1.0,0.7,0.0), 1.0-smoothstep( 0.005, 0.005+px, di ) );
        }
    }
    
    fragColor = vec4( col, 1.0 );
}