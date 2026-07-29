// Sound (sound) — Common shader Tab by iq
// https://www.shadertoy.com/view/4l2BW3

// The MIT License
// Copyright © 2018 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


// This shader shows how to use the Common tab in Shadertoy: all tabs inherit the
// code in the "Common" tab. In this case, that's used to get the Image and the
// Sound shader to reuse the same music pattern to display the visuals and produce
// the sound.


float tone( in float freq, in float deca, in float time )
{
    // fm sound
    float y = sin(6.2831*freq*time + 5.0*sin(6.2831*freq*time) );
    // add some harmonics
    y *= 0.5*(1.0+y*y);
    // attenaute
    y *= exp(-(1.0+freq/20.0)*deca);
    // attack
    y *= clamp(12.0*deca,0.0,1.0);
	return y;    
}

vec2 mainSound( in int samp, float time )
{
    // reverb
    float y = 0.0;
    float a = 0.7;
    for( int i=0; i<5; i++ )
    {       
        float hime = time - 1.4*float(i)/5.0;
        float freq = patternFreq( hime );
        float deca = patternFrac( hime );
        y += a*tone( freq, deca, hime );
        a *= 0.6;
    }
    
    return vec2( y );
}