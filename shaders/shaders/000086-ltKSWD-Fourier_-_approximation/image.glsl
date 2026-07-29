// Image (image) — Fourier - approximation by iq
// https://www.shadertoy.com/view/ltKSWD

// The MIT License
// Copyright © 2017 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.



// Approximating a 50 point shape by 1, 2, 3, ..., 50 Fourier coefficients, great for
// shape compression. The last coefficients are pretty small and therefore they can be 
// stored in very few bits (or completely discarded as in this example)
//
// Some related info: https://iquilezles.org/articles/fourier


float hash( float n ) 
{
    return fract( n*63.0*fract( n*0.3183099 ) );
}

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

vec2 cmul( vec2 a, vec2 b )  { return vec2( a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x ); }

//=================================================================================================
// digit drawing function by P_Malin (https://www.shadertoy.com/view/4sf3RN)
float SampleDigit(const in float n, const in vec2 vUV)
{		
	if(vUV.x  < 0.0) return 0.0;
	if(vUV.y  < 0.0) return 0.0;
	if(vUV.x >= 1.0) return 0.0;
	if(vUV.y >= 1.0) return 0.0;
	
	float data = 0.0;
	
	     if(n < 0.5) data = 7.0 + 5.0*16.0 + 5.0*256.0 + 5.0*4096.0 + 7.0*65536.0;
	else if(n < 1.5) data = 2.0 + 2.0*16.0 + 2.0*256.0 + 2.0*4096.0 + 2.0*65536.0;
	else if(n < 2.5) data = 7.0 + 1.0*16.0 + 7.0*256.0 + 4.0*4096.0 + 7.0*65536.0;
	else if(n < 3.5) data = 7.0 + 4.0*16.0 + 7.0*256.0 + 4.0*4096.0 + 7.0*65536.0;
	else if(n < 4.5) data = 4.0 + 7.0*16.0 + 5.0*256.0 + 1.0*4096.0 + 1.0*65536.0;
	else if(n < 5.5) data = 7.0 + 4.0*16.0 + 7.0*256.0 + 1.0*4096.0 + 7.0*65536.0;
	else if(n < 6.5) data = 7.0 + 5.0*16.0 + 7.0*256.0 + 1.0*4096.0 + 7.0*65536.0;
	else if(n < 7.5) data = 4.0 + 4.0*16.0 + 4.0*256.0 + 4.0*4096.0 + 7.0*65536.0;
	else if(n < 8.5) data = 7.0 + 5.0*16.0 + 7.0*256.0 + 5.0*4096.0 + 7.0*65536.0;
	else if(n < 9.5) data = 7.0 + 4.0*16.0 + 7.0*256.0 + 5.0*4096.0 + 7.0*65536.0;
	
	vec2 vPixel = floor(vUV * vec2(4.0, 5.0));
	float fIndex = vPixel.x + (vPixel.y * 4.0);
	
	return mod(floor(data / pow(2.0, fIndex)), 2.0);
}

float PrintInt( in vec2 uv, in float value )
{
	float res = 0.0;
	float maxDigits = 1.0+ceil(.01+log2(value)/log2(10.0));
	float digitID = floor(uv.x);
	if( digitID>0.0 && digitID<maxDigits )
	{
        float digitVa = mod( floor( value/pow(10.0,maxDigits-1.0-digitID) ), 10.0 );
        res = SampleDigit( digitVa, vec2(fract(uv.x), uv.y) );
	}

	return res;	
}
//=================================================================================================


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float e = 2.0/iResolution.y;
	vec2 p = (-iResolution.xy+2.0*fragCoord) / iResolution.y;

    vec3 col = vec3(1.0);

    vec2 path[50];
    
    //------------------------------------------------------
    // generate a path of 50 random points
    //------------------------------------------------------
    {
        vec2 d = vec2(1000.0);
        vec2 q = vec2(0.25,0.7);
        path[0] = q;
        float dir = 0.0;
        for( int i=1; i<50; i++ )
        {
            float h = float(i)/50.0;
            dir += 1.7*(-1.0+2.0*hash(float(i)));
            q += 0.16*vec2( cos(dir), sin(dir) );
            q = mix( q, path[0], pow(h,16.0) );
            path[i] = q;
        }
    }

    //------------------------------------------------------
    // draw path
    //------------------------------------------------------
    {
        vec2 d = vec2(1000.0);
        for( int i=0; i<49; i++ )
        {
            vec2 a = path[i+0];
            vec2 b = path[i+1];
            d = min( d, vec2(sdSegmentSq( p,a,b ), sdPointSq(p,a) ) );
        }
        d = sqrt( min( d, vec2(sdSegmentSq( p, path[49], path[0] ), sdPointSq(p,path[49]) ) ) );

        col = mix( col, vec3(0.7,0.7,0.7), 1.0-smoothstep(0.0,1.0*e,d.x) );
        col = mix( col, vec3(0.9,0.2,0.0), 1.0-smoothstep(5.0*e,6.0*e,d.y) );
    }

    //------------------------------------------------------
    // compute fourier transform of the path
    //------------------------------------------------------


    vec2 fcs[50];
    for( int k=0; k<50; k++ )
    {
        vec2 fc = vec2(0.0);
        for( int i=0; i<50; i++ )
        {
            float an = -6.283185*float(k)*float(i)/50.0;
            fc += cmul(path[i],vec2(cos(an),sin(an)));
        }
        fcs[k] = fc;
    }

    //------------------------------------------------------
    // inverse transform using only n<=25 coefficients
    //------------------------------------------------------
    float n = min(mod(2.0*iTime,30.0),25.0);
    float ni = floor(n);
    float nf = fract(n);
    n = ni + smoothstep(0.0,1.0,nf);
    
    {
    float d = 1000.0;
    vec2 oq, fq;
    for( int i=0; i<50; i++ )
    {
        vec2 q = vec2(0.0);
        for( int k=0; k<25; k++ )
        {
            float w = clamp( n-float(k), 0.0, 1.0 );
            
            float w1 = 6.283185*float(k)*float(i)/50.0;
            q += w*cmul( fcs[k], vec2( cos(w1), sin(w1) ) )/50.0;
            
            float w2 = 6.283185*float(49-k)*float(i)/50.0;
            q += w*cmul( fcs[49-k], vec2( cos(w2), sin(w2) ) )/50.0;
        }

        if( i==0 ) fq=q; else d = min( d, sdSegmentSq( p, q, oq ) );
        oq = q;
    }
    d = sqrt( min( d, sdSegmentSq( p, oq, fq ) ) );

    col = mix( col, vec3(0.1,0.1,0.2), 1.0-smoothstep(0.0*e,2.0*e,d) );
    col *= 0.75 + 0.25*smoothstep( 0.0, 0.3, sqrt(d) );

    }

    //------------------------------------------------------
    // print number of coefficients and vignette
    //------------------------------------------------------
	col *= 1.0 - PrintInt( (p-vec2(0.85,0.6))*4.0, 2.0*n );
    col *= 1.0 - 0.15*length(p);
    
	fragColor = vec4(col,1.0);
}