// Image (image) — Fourier - interpolation by iq
// https://www.shadertoy.com/view/4lGSDw

// The MIT License
// Copyright © 2017 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


// A set of 38 points gets interpolated by computing the DFT (Discrete Fourier Transform)
// and then its inverse, and evaluating the it at more than 38 points. This results in
// an interpolation sort of made of cosine/sine waves. Would be nice to do a regular
// Hermite spline interpolation as well to compare.
//
// More info: https://iquilezles.org/articles/fourier
//
// Original drawing (kind of), here:
// https://mir-s3-cdn-cf.behance.net/project_modules/disp/831a237863325.560b2e6f92480.png

float sdSegmentSq( in vec2 p, in vec2 a, in vec2 b )
{
	vec2 pa = p-a, ba = b-a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    vec2  d = pa - ba*h;
	return dot(d,d);
}

float sdPointSq( in vec2 p, in vec2 a )
{
    vec2 d = p - a;
	return dot(d,d);
}

vec2 cmul( vec2 a, vec2 b ) { return vec2(a.x*b.x-a.y*b.y, a.x*b.y+a.y*b.x); }

#define ZERO min(iFrame,0)

//------------------------------------------------------
// path
//------------------------------------------------------
#define NUM 38
const vec2 kPath[NUM] = vec2[NUM](
vec2(0.098,0.062), vec2(0.352,0.073), vec2(0.422,0.136), vec2(0.371,0.085),
vec2(0.449,0.140), vec2(0.352,0.187), vec2(0.379,0.202), vec2(0.398,0.202),
vec2(0.266,0.198), vec2(0.318,0.345), vec2(0.402,0.359), vec2(0.361,0.425),
vec2(0.371,0.521), vec2(0.410,0.491), vec2(0.410,0.357), vec2(0.502,0.482),
vec2(0.529,0.435), vec2(0.426,0.343), vec2(0.449,0.343), vec2(0.504,0.335),
vec2(0.664,0.355), vec2(0.748,0.208), vec2(0.738,0.277), vec2(0.787,0.308),
vec2(0.748,0.183), vec2(0.623,0.081), vec2(0.557,0.099), vec2(0.648,0.116),
vec2(0.598,0.116), vec2(0.566,0.195), vec2(0.584,0.228), vec2(0.508,0.083),
vec2(0.457,0.140), vec2(0.508,0.130), vec2(0.625,0.071), vec2(0.818,0.093),
vec2(0.951,0.066), vec2(0.547,0.081));

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 p = fragCoord/iResolution.x;
    float e = 1.0/iResolution.x;
    
    vec3 col = vec3(1.0);

    //------------------------------------------------------
    // draw path
    //------------------------------------------------------
    {
        vec2 d = vec2(1000.0);
        for( int i=0; i<(NUM-1); i++ )
        {
            vec2 a = kPath[i+0];
            vec2 b = kPath[i+1];
            d = min( d, vec2(sdSegmentSq( p,a,b ), sdPointSq(p,a) ) );
        }
        d.x = sqrt( d.x );
        d.y = sqrt( min( d.y, sdPointSq(p,kPath[NUM-1]) ) );
        //col = mix( col, vec3(0.8,0.8,0.8), 1.0-smoothstep(0.0,e,d.x) );
        col = mix( col, vec3(0.9,0.2,0.0), 1.0-smoothstep(5.0*e,6.0*e,d.y) );
    }

    //------------------------------------------------------
    // compute fourier transform of the path
    //------------------------------------------------------
    vec2 fcsX[20];
    vec2 fcsY[20];
    for( int k=ZERO; k<20; k++ )
    {
        vec2 fcx = vec2(0.0);
        vec2 fcy = vec2(0.0);
        for( int i=0; i<NUM; i++ )
        {
            float an = -6.283185*float(k)*float(i)/float(NUM);
            vec2  ex = vec2( cos(an), sin(an) );
            fcx += kPath[i].x*ex;
            fcy += kPath[i].y*ex;
        }
        fcsX[k] = fcx;
        fcsY[k] = fcy;
    }

    //------------------------------------------------------
    // inverse transform with 6x evaluation points
    //------------------------------------------------------
    {
    float ani = min( mod((12.0+iTime)/10.1,1.3), 1.0 );
    float d2 = 1e20;
    vec2 oq, fq;
    for( int i=ZERO; i<256; i++ )
    {
        float h = ani*float(i)/256.0;
        vec2 q = vec2(0.0);
        for( int k=0; k<20; k++ )
        {
            float w = (k==0||k==19)?1.0:2.0;
            float an = -6.283185*float(k)*h;
            vec2  ex = vec2( cos(an), sin(an) );
            q.x += w*dot(fcsX[k],ex)/float(NUM);
            q.y += w*dot(fcsY[k],ex)/float(NUM);
        }
        if( i==0 ) fq=q; else d2 = min( d2, sdSegmentSq( p, q, oq ) );
        oq = q;
    }
    float d = sqrt(d2);
    col = mix( col, vec3(0.1,0.1,0.2), 1.0-smoothstep(0.0*e,2.0*e,d) );
    col *= 1.0 - 0.2/(1.0+1024.0*abs(d));
    }

    //------------------------------------------------------

    col *= 1.0 - 0.3*length(fragCoord/iResolution.xy-0.5);
 
    fragColor = vec4(col,1.0);
}